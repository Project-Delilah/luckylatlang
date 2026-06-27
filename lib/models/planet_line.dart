import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';

enum Planet {
  sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto;

  String get displayName => switch (this) {
    Planet.sun => 'Sun',
    Planet.moon => 'Moon',
    Planet.mercury => 'Mercury',
    Planet.venus => 'Venus',
    Planet.mars => 'Mars',
    Planet.jupiter => 'Jupiter',
    Planet.saturn => 'Saturn',
    Planet.uranus => 'Uranus',
    Planet.neptune => 'Neptune',
    Planet.pluto => 'Pluto',
  };

  Color get color => switch (this) {
    Planet.sun => AppColors.planetSun,
    Planet.moon => AppColors.planetMoon,
    Planet.mercury => AppColors.planetMercury,
    Planet.venus => AppColors.planetVenus,
    Planet.mars => AppColors.planetMars,
    Planet.jupiter => AppColors.planetJupiter,
    Planet.saturn => AppColors.planetSaturn,
    Planet.uranus => AppColors.planetUranus,
    Planet.neptune => AppColors.planetNeptune,
    Planet.pluto => AppColors.planetPluto,
  };

  String get glyph => switch (this) {
    Planet.sun => '☉',
    Planet.moon => '☽',
    Planet.mercury => '☿',
    Planet.venus => '♀',
    Planet.mars => '♂',
    Planet.jupiter => '♃',
    Planet.saturn => '♄',
    Planet.uranus => '♅',
    Planet.neptune => '♆',
    Planet.pluto => '♇',
  };

  // Benefit score: positive = beneficial, negative = challenging
  double get benefitScore => switch (this) {
    Planet.jupiter => 3.0,
    Planet.venus => 2.5,
    Planet.sun => 1.5,
    Planet.moon => 0.8,
    Planet.mercury => 0.5,
    Planet.uranus => 0.3,
    Planet.neptune => -0.3,
    Planet.pluto => -1.0,
    Planet.mars => -1.5,
    Planet.saturn => -2.0,
  };
}

enum LineType {
  ac, dc, mc, ic;

  String get displayName => switch (this) {
    LineType.ac => 'AC',
    LineType.dc => 'DC',
    LineType.mc => 'MC',
    LineType.ic => 'IC',
  };

  String get fullName => switch (this) {
    LineType.ac => 'Ascendant',
    LineType.dc => 'Descendant',
    LineType.mc => 'Midheaven',
    LineType.ic => 'Imum Coeli',
  };

  double get weight => switch (this) {
    LineType.mc => 1.0,
    LineType.ac => 1.0,
    LineType.dc => 0.8,
    LineType.ic => 0.8,
  };
}

class PlanetLine {
  final Planet planet;
  final LineType type;
  // Segments split at antimeridian — each segment is a continuous polyline
  final List<List<LatLng>> segments;
  final double ra;   // Right Ascension in degrees
  final double dec;  // Declination in degrees

  const PlanetLine({
    required this.planet,
    required this.type,
    required this.segments,
    required this.ra,
    required this.dec,
  });

  String get label => '${planet.displayName} ${type.displayName}';
  Color get color => planet.color;
}
