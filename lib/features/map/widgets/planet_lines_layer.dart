import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../models/planet_line.dart';
import '../../../services/astro_service.dart';

class PlanetLinesLayer extends StatelessWidget {
  final AstroResult astro;
  final Set<Planet> hiddenPlanets;

  const PlanetLinesLayer({
    super.key,
    required this.astro,
    required this.hiddenPlanets,
  });

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];

    for (final line in astro.lines) {
      if (hiddenPlanets.contains(line.planet)) continue;

      final isDashed = line.type == LineType.dc || line.type == LineType.ic;
      final isMC = line.type == LineType.mc || line.type == LineType.ic;

      for (final segment in line.segments) {
        if (segment.length < 2) continue;
        polylines.add(Polyline(
          points: segment,
          color: line.color.withValues(alpha: isDashed ? 0.6 : 0.8),
          strokeWidth: isMC ? 2.0 : 1.5,
          // flutter_map doesn't support native dashes; we use lower opacity for DC/IC
        ));
      }
    }

    return PolylineLayer(polylines: polylines);
  }
}
