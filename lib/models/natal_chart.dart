import 'planet_line.dart';

enum FunctionalNature { yogaKaraka, benefic, supportive, neutral, challenging }

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

  // Functional benefic/malefic classification for this ascendant (classical planets only)
  Map<Planet, FunctionalNature> get functionalNature {
    final owned = <Planet, Set<int>>{};
    for (var h = 1; h <= 12; h++) {
      final lord = houseSign(h).traditionalRuler;
      owned.putIfAbsent(lord, () => {}).add(h);
    }
    const trikonas = {5, 9};       // pure trikonas (1st counted via trikonaAll below)
    const kendraPure = {4, 7, 10}; // pure kendras
    const trikonaAll = {1, 5, 9};
    const kendraAll = {1, 4, 7, 10};
    const dusthana = {6, 8, 12};

    return Map.fromEntries(owned.entries.map((e) {
      final h = e.value;
      final isYK  = h.any(kendraPure.contains) && h.any(trikonas.contains);
      final isTri = h.any(trikonaAll.contains);
      final isKen = h.any(kendraAll.contains);
      final isDus = h.any(dusthana.contains);
      final nature = isYK
          ? FunctionalNature.yogaKaraka
          : isTri
              ? FunctionalNature.benefic
              : (isKen && !isDus)
                  ? FunctionalNature.supportive
                  : isDus
                      ? FunctionalNature.challenging
                      : FunctionalNature.neutral;
      return MapEntry(e.key, nature);
    }));
  }
}
