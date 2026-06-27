import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/city_spot.dart';
import '../../../providers/city_provider.dart';
import 'city_detail_panel.dart';
import 'spot_bottom_sheet.dart';

/// Single persistent DraggableScrollableSheet for the map screen.
///
/// The sheet frame NEVER remounts — only the content inside it swaps when
/// the user navigates between the city list, a city detail, or a tapped
/// point. This keeps the sheet at whatever scroll position the user set.
class MapBottomSheet extends ConsumerStatefulWidget {
  const MapBottomSheet({super.key});

  @override
  ConsumerState<MapBottomSheet> createState() => _MapBottomSheetState();
}

class _MapBottomSheetState extends ConsumerState<MapBottomSheet> {
  final _sheetCtrl = DraggableScrollableController();

  @override
  void dispose() {
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final tappedSpot  = ref.watch(tappedPointSpotProvider);

    // When the user taps a city or blank point from a collapsed state,
    // animate up so the detail is actually visible.
    ref.listen(selectedCityProvider, (prev, next) => _expandIfCollapsed(next));
    ref.listen(tappedPointSpotProvider, (prev, next) => _expandIfCollapsed(next));

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.12,
      minChildSize: 0.08,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.08, 0.12, 0.52, 0.92],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: ctx.colors.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, -4)),
            ],
          ),
          child: _content(selectedCity, tappedSpot, scrollCtrl),
        );
      },
    );
  }

  Widget _content(CitySpot? selectedCity, CitySpot? tappedSpot, ScrollController scrollCtrl) {
    if (selectedCity != null) {
      return CityDetailContent(
        key: const ValueKey('city-detail'),
        city: selectedCity,
        scrollCtrl: scrollCtrl,
        onBack: () => ref.read(selectedCityProvider.notifier).state = null,
      );
    }
    if (tappedSpot != null) {
      return CityDetailContent(
        key: const ValueKey('point-detail'),
        city: tappedSpot,
        scrollCtrl: scrollCtrl,
        onBack: () => ref.read(tappedPointProvider.notifier).state = null,
      );
    }
    return SpotSheetContent(
      key: const ValueKey('spot-list'),
      scrollCtrl: scrollCtrl,
    );
  }

  void _expandIfCollapsed(Object? _) {
    if (!_sheetCtrl.isAttached) return;
    if (_sheetCtrl.size < 0.20) {
      _sheetCtrl.animateTo(
        0.52,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
