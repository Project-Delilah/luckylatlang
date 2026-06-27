import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/birth_profile.dart';
import '../../../models/planet_line.dart';
import '../../../providers/astro_provider.dart';
import '../../../providers/city_provider.dart';
import '../../../providers/profile_provider.dart';

const _themeModes = [
  (ThemeMode.system, 'Follow system', Icons.brightness_auto_outlined),
  (ThemeMode.light, 'Light', Icons.light_mode_outlined),
  (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
];

class MapDrawer extends ConsumerStatefulWidget {
  const MapDrawer({super.key});

  @override
  ConsumerState<MapDrawer> createState() => _MapDrawerState();
}

class _MapDrawerState extends ConsumerState<MapDrawer> {
  final _countrySearch = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _countrySearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final hidden = ref.watch(planetFilterProvider);
    final selectedCountry = ref.watch(countryFilterProvider);
    final countries = ref.watch(availableCountriesProvider);
    final themeMode = ref.watch(themeModeProvider);

    final filtered = _query.isEmpty
        ? countries
        : countries
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Drawer(
      backgroundColor: AppColors.surfaceDark,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── App header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Lucky Lat·Lang',
                style: AppTextStyles.displaySm.copyWith(color: AppColors.onDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Astrocartography',
                style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft),
              ),
            ),

            // ── Profile card ──────────────────────────────────────────────
            if (profile != null) _ProfileCard(profile: profile),

            // About app link
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.info_outline_rounded,
                  color: AppColors.onDarkSoft, size: 20),
              title: Text(
                'About app',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onDark),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onDarkSoft, size: 18),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                context.push(Routes.about);
              },
            ),

            _drawerDivider(),

            // ── Planet lines ──────────────────────────────────────────────
            _sectionHeader('PLANET LINES'),
            ...Planet.values.map(
              (p) => _PlanetRow(
                planet: p,
                visible: !hidden.contains(p),
                onToggle: () => ref.read(planetFilterProvider.notifier).toggle(p),
              ),
            ),

            _drawerDivider(),

            // ── Country filter ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Text(
                    'COUNTRY FILTER',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.onDarkSoft),
                  ),
                  const Spacer(),
                  if (selectedCountry != null)
                    TextButton(
                      onPressed: () =>
                          ref.read(countryFilterProvider.notifier).state = null,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            // Search field for countries
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _countrySearch,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onDark),
                decoration: InputDecoration(
                  hintText: 'Search countries…',
                  hintStyle:
                      AppTextStyles.bodySm.copyWith(color: AppColors.onDarkSoft),
                  prefixIcon: const Icon(Icons.search, size: 18,
                      color: AppColors.onDarkSoft),
                  filled: true,
                  fillColor: AppColors.surfaceDarkElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            // All countries row
            _CountryTile(
              name: 'All countries',
              isSelected: selectedCountry == null,
              icon: Icons.public_outlined,
              onTap: () =>
                  ref.read(countryFilterProvider.notifier).state = null,
            ),
            // Filtered country list
            ...filtered.take(30).map(
                  (c) => _CountryTile(
                    name: c.name,
                    isSelected: selectedCountry == c.code,
                    onTap: () =>
                        ref.read(countryFilterProvider.notifier).state = c.code,
                  ),
                ),
            if (filtered.length > 30)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  '+ ${filtered.length - 30} more — refine search',
                  style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft),
                ),
              ),

            _drawerDivider(),

            // ── Edit profile ──────────────────────────────────────────────
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.onDarkSoft, size: 20),
              title: Text(
                'Edit profile',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onDark),
              ),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                context.push(Routes.profile);
              },
            ),

            _drawerDivider(),

            // ── Appearance ────────────────────────────────────────────────
            _sectionHeader('APPEARANCE'),
            ..._themeModes.map((entry) {
              final selected = themeMode == entry.$1;
              return InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).set(entry.$1),
                highlightColor: AppColors.surfaceDarkElevated,
                splashColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Icon(entry.$3,
                          size: 18,
                          color: selected ? AppColors.primary : AppColors.onDarkSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.$2,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: selected ? AppColors.primary : AppColors.onDark,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerDivider() => Divider(
        height: 1,
        color: AppColors.onDarkSoft.withValues(alpha: 0.15),
        indent: 16,
        endIndent: 16,
      );

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          label,
          style: AppTextStyles.captionUppercase
              .copyWith(color: AppColors.onDarkSoft),
        ),
      );
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final BirthProfile profile;
  const _ProfileCard({required this.profile});

  String get _initials {
    final parts = profile.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(profile.birthDateTime);
    final timeStr = DateFormat('HH:mm').format(profile.birthDateTime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.onDarkSoft.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: AppTextStyles.titleMd.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      style: AppTextStyles.titleSm
                          .copyWith(color: AppColors.onDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$dateStr · $timeStr',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.onDarkSoft)),
                  const SizedBox(height: 1),
                  Text(profile.cityName,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.onDarkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Planet toggle row ──────────────────────────────────────────────────────────

class _PlanetRow extends StatelessWidget {
  final Planet planet;
  final bool visible;
  final VoidCallback onToggle;
  const _PlanetRow({required this.planet, required this.visible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      highlightColor: AppColors.surfaceDarkElevated,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Text(planet.glyph,
                style: TextStyle(
                    fontSize: 18,
                    color: visible
                        ? planet.color
                        : AppColors.onDarkSoft.withValues(alpha: 0.4))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                planet.displayName,
                style: AppTextStyles.bodyMd.copyWith(
                    color: visible ? AppColors.onDark : AppColors.onDarkSoft),
              ),
            ),
            Icon(
              visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 18,
              color: visible ? planet.color : AppColors.onDarkSoft.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Country tile ───────────────────────────────────────────────────────────────

class _CountryTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;
  const _CountryTile({required this.name, required this.isSelected, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppColors.surfaceDarkElevated,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.onDarkSoft),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: 26),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
