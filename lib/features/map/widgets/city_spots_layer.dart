import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/city_spot.dart';

class CitySpotsLayer extends StatelessWidget {
  final List<CitySpot> spots;
  final CitySpot? selected;
  final ValueChanged<CitySpot> onTap;

  const CitySpotsLayer({
    super.key,
    required this.spots,
    required this.selected,
    required this.onTap,
  });

  Color _color(SpotRating r) => switch (r) {
    SpotRating.lucky => AppColors.spotLucky,
    SpotRating.neutral => AppColors.spotNeutral,
    SpotRating.challenging => AppColors.spotChallenging,
  };

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: spots.map((spot) {
        final isSelected = selected?.cityId == spot.cityId;
        final color = _color(spot.rating);
        return Marker(
          point: LatLng(spot.latitude, spot.longitude),
          width: isSelected ? 100 : 80,
          height: isSelected ? 36 : 28,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => onTap(spot),
            child: _SpotMarker(spot: spot, color: color, selected: isSelected),
          ),
        );
      }).toList(),
    );
  }
}

class _SpotMarker extends StatelessWidget {
  final CitySpot spot;
  final Color color;
  final bool selected;
  const _SpotMarker({required this.spot, required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Text(
          spot.cityName,
          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return Center(
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1))],
        ),
      ),
    );
  }
}
