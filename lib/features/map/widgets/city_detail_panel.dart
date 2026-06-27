import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/city_spot.dart';

/// Content-only widget — rendered inside the shared DraggableScrollableSheet
/// in MapBottomSheet. Does NOT own its own sheet or scrollController.
class CityDetailContent extends StatelessWidget {
  final CitySpot city;
  final ScrollController scrollCtrl;
  final VoidCallback onBack;

  const CityDetailContent({
    super.key,
    required this.city,
    required this.scrollCtrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollCtrl,
      slivers: [
        SliverToBoxAdapter(child: _handle()),
        SliverToBoxAdapter(child: _NavBar(label: city.cityId == -1 ? 'Map' : 'Cities', onBack: onBack)),
        SliverToBoxAdapter(child: _Header(city: city)),
        SliverToBoxAdapter(child: _RatingBadge(city: city)),
        if (city.influences.isEmpty)
          const SliverToBoxAdapter(child: _NoInfluences())
        else ...[
          const SliverToBoxAdapter(child: _SectionLabel('Active planet lines')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _PlanetCard(inf: city.influences[i]),
              childCount: city.influences.length,
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _handle() => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
      ),
    ),
  );
}

// ── Back nav bar ──────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final String label;
  final VoidCallback onBack;
  const _NavBar({required this.label, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
        label: Text(label, style: AppTextStyles.bodySm),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.muted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final CitySpot city;
  const _Header({required this.city});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(city.cityName, style: AppTextStyles.displaySm),
          if (city.countryName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(city.countryName,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

// ── Rating badge ──────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final CitySpot city;
  const _RatingBadge({required this.city});

  Color get _color => switch (city.rating) {
    SpotRating.lucky => AppColors.spotLucky,
    SpotRating.neutral => AppColors.spotNeutral,
    SpotRating.challenging => AppColors.spotChallenging,
  };

  String get _scoreLabel {
    final s = city.score;
    if (s > 3) return 'Exceptionally aligned';
    if (s > 1.5) return 'Strongly favourable';
    if (s > 0) return 'Slightly favourable';
    if (s > -1.5) return 'Slightly challenging';
    if (s > -3) return 'Challenging';
    return 'Very challenging';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(city.ratingLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: _color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_scoreLabel, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(text,
          style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
    );
  }
}

// ── No influences ─────────────────────────────────────────────────────────────

class _NoInfluences extends StatelessWidget {
  const _NoInfluences();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Text(
        'No significant planet lines pass within 500 km of this location.',
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}

// ── Planet influence card ─────────────────────────────────────────────────────

class _PlanetCard extends StatelessWidget {
  final LineInfluence inf;
  const _PlanetCard({required this.inf});

  String get _effectLabel {
    final s = inf.score;
    if (s > 1.5) return 'Strong benefit';
    if (s > 0.5) return 'Moderate benefit';
    if (s > 0) return 'Mild benefit';
    if (s > -0.5) return 'Mild tension';
    if (s > -1.5) return 'Moderate tension';
    return 'Strong tension';
  }

  Color get _effectColor {
    final s = inf.score;
    if (s > 0) return AppColors.spotLucky;
    if (s > -0.5) return AppColors.spotNeutral;
    return AppColors.spotChallenging;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: inf.planet.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(inf.planet.glyph,
                      style: TextStyle(fontSize: 18, color: inf.planet.color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${inf.planet.displayName} ${inf.type.displayName}',
                          style: AppTextStyles.titleSm),
                      const SizedBox(height: 2),
                      Text('${inf.type.fullName}  ·  ${inf.distanceKm.round()} km away',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_effectLabel,
                        style: AppTextStyles.caption
                            .copyWith(color: _effectColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _StrengthBar(strength: inf.strength, color: inf.planet.color),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Text(inf.interpretation, style: AppTextStyles.bodyMd),
          ),
        ],
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final double strength;
  final Color color;
  const _StrengthBar({required this.strength, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 5,
      decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: strength.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}
