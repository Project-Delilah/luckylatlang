import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/birth_profile.dart';
import '../../providers/astro_provider.dart';
import '../../providers/city_provider.dart';
import '../../providers/profile_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final astroAsync = ref.watch(astroResultProvider);
    final spotsAsync = ref.watch(citySpotsProvider);
    final hiddenPlanets = ref.watch(planetFilterProvider);
    final filteredSpots = ref.watch(filteredSpotsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Dismiss selections before leaving the screen
        final city = ref.read(selectedCityProvider);
        final point = ref.read(tappedPointProvider);
        if (city != null) {
          ref.read(selectedCityProvider.notifier).state = null;
        } else if (point != null) {
          ref.read(tappedPointProvider.notifier).state = null;
        } else {
          context.go(Routes.intro);
        }
      },
      child: Scaffold(
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

          // ── Top bar — always dark (map overlay) ───────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  _MapOverlayBtn(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: const Icon(Icons.menu_rounded,
                        size: 20, color: AppColors.onDark),
                  ),
                  const Spacer(),
                  _ProfileBtn(
                    profile: profile,
                    onTap: () => context.push(Routes.profile),
                  ),
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
      ), // PopScope
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

// ── Generic dark overlay button (circle) ──────────────────────────────────────

class _MapOverlayBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _MapOverlayBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Profile avatar button ──────────────────────────────────────────────────────

class _ProfileBtn extends StatelessWidget {
  final BirthProfile? profile;
  final VoidCallback onTap;
  const _ProfileBtn({required this.profile, required this.onTap});

  String get _initials {
    final name = profile?.name ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: profile != null ? AppColors.primary : AppColors.surfaceDarkElevated,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: profile != null
            ? Text(
                _initials,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              )
            : const Icon(Icons.person_outline_rounded,
                size: 20, color: AppColors.onDark),
      ),
    );
  }
}
