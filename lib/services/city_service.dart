import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../core/db/city_db.dart';
import '../models/city_spot.dart';
import '../models/planet_line.dart';
import '../services/astro_service.dart';

// Radius within which a line influences a city (km)
const _influenceRadiusKm = 500.0;
// ~1 degree ≈ 111km → 500km ≈ 4.5 degrees
// Gaussian falloff: σ=150 km — strong within orb (~100 km), steep drop beyond
const _sigma = 150.0;
const _influenceDegreesLat = 5.0;
// longitude degrees varies with latitude — we use a conservative 8°

const Map<(Planet, LineType), String> _interpretations = {
  (Planet.sun, LineType.ac): 'Your vitality shines here. Others see your full radiance, confidence flows naturally, and leadership opportunities come to you.',
  (Planet.sun, LineType.mc): 'Career and public recognition peak in this region. A place for achievement, visibility, and professional fulfilment.',
  (Planet.sun, LineType.dc): 'Partnerships and significant relationships tend to flourish. You attract sunny, generous companions.',
  (Planet.sun, LineType.ic): 'A deep sense of home and rootedness. Family ties strengthen and inner security is nourished.',
  (Planet.moon, LineType.ac): 'Emotional openness and nurturing energy characterise how you show up. Intuition is heightened.',
  (Planet.moon, LineType.mc): 'Public life is shaped by emotional intelligence. Work with people, caregiving, and creative endeavours thrive.',
  (Planet.moon, LineType.dc): 'Relationships take on a caring, emotional depth. You attract nurturing partners.',
  (Planet.moon, LineType.ic): 'Strong domestic instincts and ancestral connection. A place to put down roots.',
  (Planet.mercury, LineType.ac): 'Communication and wit define your identity here. Writing, speaking, and networking come easily.',
  (Planet.mercury, LineType.mc): 'Intellectual pursuits and communication-based careers thrive. Media, education, and technology benefit you.',
  (Planet.mercury, LineType.dc): 'Clever, communicative partners are drawn to you. Contracts and negotiations go well.',
  (Planet.mercury, LineType.ic): 'Mental agility and curiosity colour your home life. A good place for study.',
  (Planet.venus, LineType.ac): 'Beauty, grace, and charm amplify. You make an excellent impression and social life blossoms.',
  (Planet.venus, LineType.mc): 'Artistic careers and aesthetic pursuits flourish. Financial opportunities and recognition in creative fields.',
  (Planet.venus, LineType.dc): 'Romantic relationships are loving and harmonious. Marriage and partnership thrive.',
  (Planet.venus, LineType.ic): 'A beautiful, comfortable home environment. Peace and aesthetic pleasure surround you.',
  (Planet.mars, LineType.ac): 'High energy and drive — but also conflict and impulsiveness. Good for sports and competition, challenging for peace.',
  (Planet.mars, LineType.mc): 'Ambition accelerates but so does friction with authority. Entrepreneurial energy is very high.',
  (Planet.mars, LineType.dc): 'Relationships can be passionate but combative. Attracts strong-willed partners.',
  (Planet.mars, LineType.ic): 'Domestic tension possible. High physical energy in the home environment.',
  (Planet.jupiter, LineType.ac): 'Exceptional luck, optimism, and opportunity define this location. Growth and expansion come naturally to you.',
  (Planet.jupiter, LineType.mc): 'Career success, abundance, and recognition arrive with ease. Travel and higher education benefit you greatly.',
  (Planet.jupiter, LineType.dc): 'Generous, expansive partners. Legal matters tend to resolve favourably. Social life expands.',
  (Planet.jupiter, LineType.ic): 'Wealth and stability in home and property. A lucky base of operations.',
  (Planet.saturn, LineType.ac): 'Discipline and hard work are demanded. Long-term results are possible but the process is austere.',
  (Planet.saturn, LineType.mc): 'Career requires serious sustained effort. Authority figures may be demanding. Eventual reward, slow to arrive.',
  (Planet.saturn, LineType.dc): 'Relationships feel karmic and demanding. Partners may be older, serious, or restrictive.',
  (Planet.saturn, LineType.ic): 'Home life feels heavy or isolated. Good for solitary deep work, difficult for family joy.',
  (Planet.uranus, LineType.ac): 'You reinvent yourself here. Exciting, unpredictable — brilliant breakthroughs and sudden changes.',
  (Planet.uranus, LineType.mc): 'Unconventional career paths open. Technology, innovation, and disruption become your domain.',
  (Planet.uranus, LineType.dc): 'Unusual or independent partners. Relationships resist convention.',
  (Planet.uranus, LineType.ic): 'Unstable home environment but great creative freedom. Frequent moves possible.',
  (Planet.neptune, LineType.ac): 'Dreamy, spiritual, and creative — but also prone to illusion and lack of clarity about identity.',
  (Planet.neptune, LineType.mc): 'Artistic or spiritual callings surface. Guard against deception in career matters.',
  (Planet.neptune, LineType.dc): 'Romantic, idealistic relationships — but with risk of illusion or disappointment.',
  (Planet.neptune, LineType.ic): 'Spiritual home life. Privacy and retreat are important here.',
};

String _interpret(Planet planet, LineType type) =>
    _interpretations[(planet, type)] ??
    'This line brings the energy of ${planet.displayName} to your ${type.fullName}.';

class CityService {
  final CityDb _db;
  CityService(this._db);

  /// Score an arbitrary geographic point against all planet lines.
  /// Returns a synthetic CitySpot (cityId = -1) — no DB lookup needed.
  CitySpot scorePoint(AstroResult astro, LatLng point) {
    final influences = <LineInfluence>[];
    final seen = <(Planet, LineType)>{};

    for (final line in astro.lines) {
      final key = (line.planet, line.type);
      if (seen.contains(key)) continue;

      var minDist = double.infinity;
      for (final seg in line.segments) {
        final d = _minDistToSegment(point, seg);
        if (d < minDist) minDist = d;
      }
      if (minDist > _influenceRadiusKm) continue;

      seen.add(key);
      final strength = math.exp(-(minDist * minDist) / (2 * _sigma * _sigma));
      influences.add(LineInfluence(
        planet: line.planet,
        type: line.type,
        distanceKm: minDist,
        strength: strength,
        interpretation: _interpret(line.planet, line.type),
      ));
    }

    influences.sort((a, b) => b.strength.compareTo(a.strength));
    final score = influences.fold(0.0, (s, inf) => s + inf.score);

    final lat = point.latitude.toStringAsFixed(3);
    final lng = point.longitude.toStringAsFixed(3);
    return CitySpot(
      cityId: -1,
      cityName: '$lat°, $lng°',
      countryCode: '',
      countryName: 'Custom location',
      latitude: point.latitude,
      longitude: point.longitude,
      score: score,
      influences: influences,
    );
  }

  Future<List<CitySpot>> computeSpots(AstroResult astro) async {
    // Collect candidate cities across all lines
    final Map<int, Map<String, dynamic>> cityRows = {};
    final Map<int, List<_LineCandidate>> cityCandidates = {};

    for (final line in astro.lines) {
      for (final segment in line.segments) {
        if (segment.isEmpty) continue;
        // Bounding box for the segment
        final lats = segment.map((p) => p.latitude).toList()..sort();
        final lngs = segment.map((p) => p.longitude).toList()..sort();
        final rows = await _db.citiesInBounds(
          minLat: lats.first - _influenceDegreesLat,
          maxLat: lats.last + _influenceDegreesLat,
          minLng: lngs.first - _influenceDegreesLat * 2,
          maxLng: lngs.last + _influenceDegreesLat * 2,
        );
        for (final row in rows) {
          final id = row['id'] as int;
          cityRows[id] = row;
          (cityCandidates[id] ??= []).add(_LineCandidate(line, segment));
        }
      }
    }

    final spots = <CitySpot>[];
    final countryCache = <String, String>{};

    for (final entry in cityRows.entries) {
      final id = entry.key;
      final row = entry.value;
      final cityLat = (row['latitude'] as num).toDouble();
      final cityLng = (row['longitude'] as num).toDouble();
      final cityLatLng = LatLng(cityLat, cityLng);

      // Find nearest point on each line
      final seen = <(Planet, LineType)>{};
      final influences = <LineInfluence>[];

      for (final candidate in cityCandidates[id]!) {
        final key = (candidate.line.planet, candidate.line.type);
        if (seen.contains(key)) continue;

        final distKm = _minDistToSegment(cityLatLng, candidate.segment);
        if (distKm > _influenceRadiusKm) continue;

        seen.add(key);
        final strength = math.exp(-(distKm * distKm) / (2 * _sigma * _sigma));
        influences.add(LineInfluence(
          planet: candidate.line.planet,
          type: candidate.line.type,
          distanceKm: distKm,
          strength: strength,
          interpretation: _interpret(candidate.line.planet, candidate.line.type),
        ));
      }

      if (influences.isEmpty) continue;

      final score = influences.fold(0.0, (s, inf) => s + inf.score);

      final cc = row['country_code'] as String;
      countryCache[cc] ??=
          (await _db.countryByCode(cc))?['name'] as String? ?? cc;

      spots.add(CitySpot(
        cityId: id,
        cityName: row['name'] as String,
        countryCode: cc,
        countryName: countryCache[cc]!,
        latitude: cityLat,
        longitude: cityLng,
        score: score,
        influences: influences..sort((a, b) => b.strength.compareTo(a.strength)),
      ));
    }

    // Sort: lucky first, then by absolute score strength
    spots.sort((a, b) => b.score.compareTo(a.score));
    return spots;
  }

  double _minDistToSegment(LatLng city, List<LatLng> segment) {
    var min = double.infinity;
    for (final pt in segment) {
      final d = _haversineKm(city.latitude, city.longitude, pt.latitude, pt.longitude);
      if (d < min) min = d;
    }
    return min;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class _LineCandidate {
  final PlanetLine line;
  final List<LatLng> segment;
  _LineCandidate(this.line, this.segment);
}
