import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/city_spot.dart';
import '../../providers/astro_provider.dart';
import '../../providers/city_provider.dart';
import 'widgets/city_spots_layer.dart';
import 'widgets/computing_overlay.dart';
import 'widgets/map_bottom_sheet.dart';
import 'widgets/map_drawer.dart';
import 'widgets/planet_lines_layer.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapCtrl = MapController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final astroAsync = ref.watch(astroResultProvider);
    final spotsAsync = ref.watch(citySpotsProvider);
    final hiddenPlanets = ref.watch(planetFilterProvider);
    final filteredSpots = ref.watch(filteredSpotsProvider);

    final searchResults = _searchQuery.isEmpty
        ? const <CitySpot>[]
        : filteredSpots
            .where((s) =>
                s.cityName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                s.countryName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .take(8)
            .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceDark,
      drawer: const MapDrawer(),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: const LatLng(20.0, 0.0),
              initialZoom: 2.5,
              minZoom: 2.0,
              maxZoom: 10,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-85.06, -180),
                  const LatLng(85.06, 180),
                ),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPos, latLng) {
                ref.read(selectedCityProvider.notifier).state = null;
                ref.read(tappedPointProvider.notifier).state = latLng;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.isg32.luckylatlang',
                tileBuilder: _darkTileBuilder,
              ),
              if (astroAsync.valueOrNull != null)
                PlanetLinesLayer(
                  astro: astroAsync.value!,
                  hiddenPlanets: hiddenPlanets,
                ),
              if (spotsAsync.valueOrNull != null)
                CitySpotsLayer(
                  spots: filteredSpots,
                  selected: ref.watch(selectedCityProvider),
                  onTap: (city) =>
                      ref.read(selectedCityProvider.notifier).state = city,
                ),
            ],
          ),

          // ── Top bar: hamburger + search ─────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _DarkIconBtn(
                        icon: Icons.menu_rounded,
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SearchField(
                          ctrl: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          onClear: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (searchResults.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _SearchDropdown(
                      results: searchResults,
                      onTap: (city) {
                        ref.read(selectedCityProvider.notifier).state = city;
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Computing overlay ──────────────────────────────────────────────
          if (astroAsync.isLoading || spotsAsync.isLoading)
            Positioned.fill(
              child: ComputingOverlay(computingLines: astroAsync.isLoading),
            ),

          // ── Bottom sheet ───────────────────────────────────────────────────
          const Positioned.fill(child: MapBottomSheet()),

          // ── Error banner ───────────────────────────────────────────────────
          if (astroAsync.hasError)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Astro computation failed. ${astroAsync.error}',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _darkTileBuilder(BuildContext context, Widget tile, TileImage image) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.65, 0, 0, 0, 0,
        0, 0.65, 0, 0, 0,
        0, 0, 0.65, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }
}

// ── Hamburger icon button ──────────────────────────────────────────────────────

class _DarkIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DarkIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.onDarkSoft.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.onDark),
      ),
    );
  }
}

// ── Search field ───────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchField({required this.ctrl, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onDarkSoft.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
        ],
      ),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.onDark),
        decoration: InputDecoration(
          hintText: 'Search cities…',
          hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.onDarkSoft),
          prefixIcon: const Icon(Icons.search_rounded, size: 18,
              color: AppColors.onDarkSoft),
          suffixIcon: ctrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.onDarkSoft),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── Search results dropdown ────────────────────────────────────────────────────

class _SearchDropdown extends StatelessWidget {
  final List<CitySpot> results;
  final ValueChanged<CitySpot> onTap;
  const _SearchDropdown({required this.results, required this.onTap});

  Color _ratingColor(SpotRating r) => switch (r) {
    SpotRating.lucky => AppColors.spotLucky,
    SpotRating.neutral => AppColors.spotNeutral,
    SpotRating.challenging => AppColors.spotChallenging,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.onDarkSoft.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.35), blurRadius: 16)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.map((city) {
              final inf = city.primaryInfluence;
              return InkWell(
                onTap: () => onTap(city),
                highlightColor: AppColors.surfaceDark,
                splashColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _ratingColor(city.rating),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(city.cityName,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.onDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(city.countryName,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.onDarkSoft),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (inf != null) ...[
                        Text(inf.planet.glyph,
                            style: TextStyle(
                                fontSize: 13, color: inf.planet.color)),
                        const SizedBox(width: 4),
                        Text(inf.type.displayName,
                            style: AppTextStyles.caption
                                .copyWith(color: inf.planet.color)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
