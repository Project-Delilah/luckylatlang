import 'package:latlong2/latlong.dart';
import 'planet_line.dart';

class LineInfluence {
  final Planet planet;
  final LineType type;
  final double distanceKm;
  final double strength; // 0–1
  final String interpretation;

  const LineInfluence({
    required this.planet,
    required this.type,
    required this.distanceKm,
    required this.strength,
    required this.interpretation,
  });

  double get score => planet.benefitScore * type.weight * strength;
}

enum SpotRating { lucky, neutral, challenging }

class CitySpot {
  final int cityId;
  final String cityName;
  final String countryCode;
  final String countryName;
  final double latitude;
  final double longitude;
  final double score;
  final List<LineInfluence> influences;

  const CitySpot({
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.countryName,
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.influences,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  SpotRating get rating {
    if (score >= 1.5) return SpotRating.lucky;
    if (score <= -1.5) return SpotRating.challenging;
    return SpotRating.neutral;
  }

  String get ratingLabel => switch (rating) {
    SpotRating.lucky => 'Lucky',
    SpotRating.neutral => 'Neutral',
    SpotRating.challenging => 'Challenging',
  };

  // Primary (strongest) influence for quick display
  LineInfluence? get primaryInfluence {
    if (influences.isEmpty) return null;
    return influences.reduce((a, b) => a.strength > b.strength ? a : b);
  }
}
