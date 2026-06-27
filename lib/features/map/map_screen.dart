import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/planet_line.dart';
import '../../providers/astro_provider.dart';
import '../../providers/city_provider.dart';
import '../../providers/profile_provider.dart';
import 'widgets/city_detail_panel.dart';
import 'widgets/city_spots_layer.dart';
import 'widgets/planet_lines_layer.dart';
import 'widgets/spot_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapCtrl = MapController();
  bool _showPlanetFilter = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final astroAsync = ref.watch(astroResultProvider);
    final spotsAsync = ref.watch(citySpotsProvider);
    final hiddenPlanets = ref.watch(planetFilterProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final filteredSpots = ref.watch(filteredSpotsProvider);
    final selectedCountry = ref.watch(countryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
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
              // Prevent panning past the poles so the gray canvas never shows
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-85.06, -180),
                  const LatLng(85.06, 180),
                ),
              ),
              interactionOptions: const InteractionOptions(
                // Rotation disabled — disorienting on a flat world map
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
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
                  selected: selectedCity,
                  onTap: (city) =>
                      ref.read(selectedCityProvider.notifier).state = city,
                ),
            ],
          ),

          // ── Top bar ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _MapChip(
                    icon: Icons.person_outline,
                    label: profile?.name ?? 'Profile',
                    onTap: () => context.push(Routes.profile),
                  ),
                  const SizedBox(width: 8),
                  _MapChip(
                    icon: Icons.public_outlined,
                    label: selectedCountry != null
                        ? _countryName(ref, selectedCountry)
                        : 'All countries',
                    onTap: () => _showCountryFilter(context),
                    active: selectedCountry != null,
                  ),
                  const Spacer(),
                  _MapChip(
                    icon: Icons.tune_outlined,
                    label: 'Planets',
                    onTap: () => setState(() => _showPlanetFilter = !_showPlanetFilter),
                    active: _showPlanetFilter,
                  ),
                ],
              ),
            ),
          ),

          // ── Planet filter panel ────────────────────────────────────────────
          if (_showPlanetFilter)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 58, 16, 0),
                  child: _PlanetFilterPanel(hidden: hiddenPlanets),
                ),
              ),
            ),

          // ── Loading bar ────────────────────────────────────────────────────
          if (astroAsync.isLoading || spotsAsync.isLoading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.primary.withValues(alpha: 0.7),
                minHeight: 2,
              ),
            ),

          // ── Bottom sheet (city list or detail) ─────────────────────────────
          // Positioned.fill gives DraggableScrollableSheet bounded height;
          // touches above the visible fraction pass through to the map.
          Positioned.fill(
            child: selectedCity != null
                ? CityDetailPanel(city: selectedCity)
                : const SpotBottomSheet(),
          ),

          // ── Error banner ───────────────────────────────────────────────────
          if (astroAsync.hasError)
            Positioned(
              bottom: 120, left: 16, right: 16,
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

  String _countryName(WidgetRef ref, String code) {
    final countries = ref.read(availableCountriesProvider);
    return countries.firstWhere((c) => c.code == code, orElse: () => (code: code, name: code)).name;
  }

  void _showCountryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CountryFilterSheet(),
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

// ── Country filter modal sheet ─────────────────────────────────────────────────

class _CountryFilterSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CountryFilterSheet> createState() => _CountryFilterSheetState();
}

class _CountryFilterSheetState extends ConsumerState<_CountryFilterSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(availableCountriesProvider);
    final selected = ref.watch(countryFilterProvider);
    final filtered = _query.isEmpty
        ? countries
        : countries.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Text('Filter by country', style: AppTextStyles.titleMd),
                const Spacer(),
                if (selected != null)
                  TextButton(
                    onPressed: () {
                      ref.read(countryFilterProvider.notifier).state = null;
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search countries…',
                hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.hairline),
          // All countries row
          ListTile(
            leading: const Icon(Icons.public_outlined, color: AppColors.muted, size: 20),
            title: Text('All countries', style: AppTextStyles.bodyMd),
            trailing: selected == null ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
            onTap: () {
              ref.read(countryFilterProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1, color: AppColors.hairline),
          // Country list
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1, indent: 56, color: AppColors.hairlineSoft),
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isSelected = selected == c.code;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  title: Text(c.name, style: AppTextStyles.bodyMd.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.ink,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                  trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
                  onTap: () {
                    ref.read(countryFilterProvider.notifier).state = c.code;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map chip ───────────────────────────────────────────────────────────────────

class _MapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _MapChip({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 160),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceDarkElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.mutedSoft.withValues(alpha: 0.3),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : AppColors.onDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: active ? Colors.white : AppColors.onDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Planet filter panel ────────────────────────────────────────────────────────

class _PlanetFilterPanel extends ConsumerWidget {
  final Set<Planet> hidden;
  const _PlanetFilterPanel({required this.hidden});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mutedSoft.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: Planet.values.map((planet) {
          final visible = !hidden.contains(planet);
          return InkWell(
            onTap: () => ref.read(planetFilterProvider.notifier).toggle(planet),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Text(planet.glyph, style: TextStyle(fontSize: 16, color: planet.color)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      planet.displayName,
                      style: AppTextStyles.bodySm.copyWith(
                        color: visible ? AppColors.onDark : AppColors.mutedSoft,
                      ),
                    ),
                  ),
                  Icon(
                    visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 16,
                    color: visible ? planet.color : AppColors.mutedSoft,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
