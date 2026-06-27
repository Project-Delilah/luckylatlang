import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/birth_profile.dart';
import '../models/planet_line.dart';

class AstroResult {
  final List<PlanetLine> lines;
  const AstroResult(this.lines);
}

// ---------------------------------------------------------------------------
// Pure-Dart planetary ephemeris using Meeus "Astronomical Algorithms" Ch. 33
// Accuracy: ~1 arcminute 1900–2100, sufficient for astrocartography lines.
// ---------------------------------------------------------------------------

class AstroService {
  AstroResult compute(BirthProfile profile) {
    final dt = profile.birthDateTime.toUtc();
    final jd = _julianDay(
      dt.year, dt.month, dt.day,
      dt.hour + dt.minute / 60.0 + dt.second / 3600.0,
    );
    final T = (jd - 2451545.0) / 36525.0; // Julian centuries from J2000
    final gmstDeg = _gmst(jd, T);          // degrees
    final eps = _obliquity(T);              // degrees

    // Earth heliocentric ecliptic position
    final earth = _heliocentricEcliptic(_earthElements, T);

    final lines = <PlanetLine>[];

    // Moon uses simplified lunar theory (not Kepler orbit around Sun)
    final (moonRa, moonDec) = _moonEquatorial(jd, T, eps);
    lines.addAll(_buildLines(Planet.moon, moonRa, moonDec, gmstDeg));

    for (final entry in _planetElements.entries) {
      final planet = entry.key;
      final elems = entry.value;
      final helio = _heliocentricEcliptic(elems, T);

      // Geocentric ecliptic
      final dx = helio.x - earth.x;
      final dy = helio.y - earth.y;
      final dz = helio.z - earth.z;

      final lon = math.atan2(dy, dx) * _r2d; // ecliptic longitude, degrees
      final lat = math.atan2(dz, math.sqrt(dx * dx + dy * dy)) * _r2d;

      // Ecliptic → Equatorial
      final epsR = eps * _d2r;
      final lonR = lon * _d2r;
      final latR = lat * _d2r;

      final ra = _normDeg(math.atan2(
            math.sin(lonR) * math.cos(epsR) - math.tan(latR) * math.sin(epsR),
            math.cos(lonR),
          ) * _r2d);
      final dec = math.asin(
            math.sin(latR) * math.cos(epsR) +
            math.cos(latR) * math.sin(epsR) * math.sin(lonR),
          ) * _r2d;

      lines.addAll(_buildLines(planet, ra, dec, gmstDeg));
    }
    return AstroResult(lines);
  }

  // ── Line geometry ─────────────────────────────────────────────────────────

  List<PlanetLine> _buildLines(Planet planet, double ra, double dec, double gmstDeg) {
    final mcLon = _normLon(ra - gmstDeg);
    final icLon = _normLon(ra - gmstDeg + 180.0);
    return [
      PlanetLine(planet: planet, type: LineType.mc, ra: ra, dec: dec,
          segments: _verticalLine(mcLon)),
      PlanetLine(planet: planet, type: LineType.ic, ra: ra, dec: dec,
          segments: _verticalLine(icLon)),
      PlanetLine(planet: planet, type: LineType.ac, ra: ra, dec: dec,
          segments: _horizLine(ra, dec, gmstDeg, rising: true)),
      PlanetLine(planet: planet, type: LineType.dc, ra: ra, dec: dec,
          segments: _horizLine(ra, dec, gmstDeg, rising: false)),
    ];
  }

  List<List<LatLng>> _verticalLine(double lon) {
    final pts = <LatLng>[];
    for (var lat = -85.0; lat <= 85.0; lat += 2.0) {
      pts.add(LatLng(lat, lon));
    }
    return [pts];
  }

  List<List<LatLng>> _horizLine(double ra, double dec, double gmstD,
      {required bool rising}) {
    final decR = dec * _d2r;
    final pts = <LatLng>[];
    final segments = <List<LatLng>>[];

    for (var lat = -80.0; lat <= 80.0; lat += 0.5) {
      final cosH = -math.tan(decR) * math.tan(lat * _d2r);
      if (cosH.abs() > 1.0) continue;

      final hDeg = math.acos(cosH) * _r2d;
      final lon = _normLon(rising ? ra + hDeg - gmstD : ra - hDeg - gmstD);

      if (pts.isNotEmpty && (lon - pts.last.longitude).abs() > 180.0) {
        segments.add(List.of(pts));
        pts.clear();
      }
      pts.add(LatLng(lat, lon));
    }
    if (pts.isNotEmpty) segments.add(pts);
    return segments;
  }

  // ── Orbital mechanics ─────────────────────────────────────────────────────

  _Vec3 _heliocentricEcliptic(_OrbElems e, double T) {
    final meanLon = _normDeg(e.l0 + e.l1 * T);
    final meanAnom = _normDeg(meanLon - e.w);
    final ea = _solveKepler(meanAnom * _d2r, e.ecc); // eccentric anomaly
    final nu = 2.0 * math.atan2(
      math.sqrt(1 + e.ecc) * math.sin(ea / 2),
      math.sqrt(1 - e.ecc) * math.cos(ea / 2),
    ) * _r2d; // true anomaly, degrees

    final r = e.a * (1.0 - e.ecc * math.cos(ea)); // distance AU

    final argPeri = e.w - e.omega;   // arg of perihelion (degrees)
    final u = (nu + argPeri) * _d2r; // argument of latitude from ascending node
    final omR = e.omega * _d2r;
    final iR  = e.inc * _d2r;

    return _Vec3(
      r * (math.cos(omR) * math.cos(u) - math.sin(omR) * math.sin(u) * math.cos(iR)),
      r * (math.sin(omR) * math.cos(u) + math.cos(omR) * math.sin(u) * math.cos(iR)),
      r *  math.sin(u) * math.sin(iR),
    );
  }

  // Newton-Raphson for Kepler's equation E - e·sin(E) = M
  double _solveKepler(double mRad, double ecc) {
    var e = mRad;
    for (var i = 0; i < 10; i++) {
      final dE = (mRad - e + ecc * math.sin(e)) / (1.0 - ecc * math.cos(e));
      e += dE;
      if (dE.abs() < 1e-10) break;
    }
    return e;
  }

  // ── Time & orientation ────────────────────────────────────────────────────

  double _julianDay(int year, int month, int day, double hour) {
    var y = year; var m = month;
    if (m <= 2) { y -= 1; m += 12; }
    final A = (y / 100).floor();
    final B = 2 - A + (A / 4).floor();
    return (365.25 * (y + 4716)).floor() +
           (30.6001 * (m + 1)).floor() +
           day + hour / 24.0 + B - 1524.5;
  }

  // GMST in degrees (Meeus Ch. 12)
  double _gmst(double jd, double T) {
    final gmstRaw = 280.46061837
        + 360.98564736629 * (jd - 2451545.0)
        + 0.000387933 * T * T
        - T * T * T / 38710000.0;
    return _normDeg(gmstRaw);
  }

  // Mean obliquity of ecliptic (Meeus Ch. 22)
  double _obliquity(double T) =>
      23.439291111 - 0.013004167 * T - 0.000001639 * T * T + 0.000000503 * T * T * T;

  // Simplified lunar theory, good to ~1° (Meeus Ch. 47 truncated)
  (double ra, double dec) _moonEquatorial(double jd, double T, double eps) {
    final d = jd - 2451545.0;
    final mLon  = (218.316 + 13.176396 * d) * _d2r;
    final mAnom = (134.963 + 13.064993 * d) * _d2r;
    final mF    = ( 93.272 + 13.229350 * d) * _d2r;
    final eclLon = mLon + 6.289 * _d2r * math.sin(mAnom);
    final eclLat = 5.128 * _d2r * math.sin(mF);
    final epsR   = eps * _d2r;
    final ra = _normDeg(math.atan2(
      math.sin(eclLon) * math.cos(epsR) - math.tan(eclLat) * math.sin(epsR),
      math.cos(eclLon),
    ) * _r2d);
    final dec = math.asin(
      math.sin(eclLat) * math.cos(epsR) +
      math.cos(eclLat) * math.sin(epsR) * math.sin(eclLon),
    ) * _r2d;
    return (ra, dec);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _d2r = math.pi / 180.0;
  static const _r2d = 180.0 / math.pi;

  double _normDeg(double d) {
    final r = d % 360.0;
    return r < 0 ? r + 360.0 : r;
  }

  double _normLon(double lon) {
    var l = lon % 360.0;
    if (l > 180.0) l -= 360.0;
    if (l < -180.0) l += 360.0;
    return l;
  }
}

// ── Orbital element tables (Meeus Table 33.a, J2000 epoch) ────────────────
// Fields: L₀, L₁ (mean longitude °/century), a (AU), ecc, inc (°),
//         omega (Ω, ascending node °), w (ω̃, longitude of perihelion °)

class _OrbElems {
  final double l0, l1; // mean longitude at J2000, rate °/century
  final double a;      // semi-major axis AU
  final double ecc;    // eccentricity
  final double inc;    // inclination °
  final double omega;  // longitude of ascending node °
  final double w;      // longitude of perihelion °
  const _OrbElems(this.l0, this.l1, this.a, this.ecc, this.inc, this.omega, this.w);
}

// Earth used only for subtraction — inclination/node are 0 by definition
const _earthElements = _OrbElems(
  100.466457, 36000.7698278,
  1.000001018, 0.01670863,
  0.0, 0.0, 102.937348,
);

final Map<Planet, _OrbElems> _planetElements = {
  Planet.mercury: const _OrbElems(252.250906, 149474.0722491, 0.387098310, 0.20563175,  7.004986, 48.330893,  77.456119),
  Planet.venus:   const _OrbElems(181.979801,  58519.2130302, 0.723329820, 0.00677192,  3.394662, 76.679920, 131.563703),
  Planet.mars:    const _OrbElems(355.433000,  19141.6964471, 1.523679342, 0.09340065,  1.849726, 49.558093, 336.060234),
  Planet.jupiter: const _OrbElems( 34.351519,   3036.3027748, 5.202603209, 0.04849793,  1.303270,100.464407,  14.331207),
  Planet.saturn:  const _OrbElems( 50.077444,   1223.5110686, 9.554909192, 0.05554814,  2.488879,113.665503,  93.057237),
  Planet.uranus:  const _OrbElems(314.055005,    429.8640561,19.218446062, 0.04629590,  0.773197, 74.005957, 173.005291),
  Planet.neptune: const _OrbElems(304.348665,    219.8833092,30.110386869, 0.00898809,  1.769953,131.784057,  48.123691),
  Planet.pluto:   const _OrbElems(238.928881,    145.1845580,39.481686677, 0.24882730, 17.141750,110.303470, 224.066676),
  // ponytail: Moon uses simplified lunar theory in _moonEquatorial, not Kepler orbit
};

class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);
}
