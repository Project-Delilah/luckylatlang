import 'planet_line.dart';

enum ZodiacSign {
  aries, taurus, gemini, cancer, leo, virgo,
  libra, scorpio, sagittarius, capricorn, aquarius, pisces;

  String get displayName => const [
        'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
        'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
      ][index];

  String get element => const [
        'Fire', 'Earth', 'Air', 'Water', 'Fire', 'Earth',
        'Air', 'Water', 'Fire', 'Earth', 'Air', 'Water',
      ][index];

  Planet get traditionalRuler => [
        Planet.mars,
        Planet.venus,
        Planet.mercury,
        Planet.moon,
        Planet.sun,
        Planet.mercury,
        Planet.venus,
        Planet.mars,
        Planet.jupiter,
        Planet.saturn,
        Planet.saturn,
        Planet.jupiter,
      ][index];

  static ZodiacSign fromLon(double lon) {
    final n = ((lon % 360) + 360) % 360;
    return ZodiacSign.values[(n / 30).floor()];
  }
}

class PlanetNatal {
  final Planet planet;
  final double eclipticLon; // 0–360°
  final ZodiacSign sign;
  final int house; // 1–12 (Whole Sign)

  const PlanetNatal({
    required this.planet,
    required this.eclipticLon,
    required this.sign,
    required this.house,
  });

  double get degreeInSign => eclipticLon % 30;
}

class NatalChart {
  final double ascLon;
  final ZodiacSign ascSign;
  final double ascDegree;
  final Map<Planet, PlanetNatal> planets;

  const NatalChart({
    required this.ascLon,
    required this.ascSign,
    required this.ascDegree,
    required this.planets,
  });

  // Sign on the cusp of house N (1-based) in Whole Sign system
  ZodiacSign houseSign(int house) =>
      ZodiacSign.values[(ascSign.index + house - 1) % 12];
}
