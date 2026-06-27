import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/city_spot.dart';
import '../../../providers/city_provider.dart';

enum _Tab { all, lucky, neutral, challenging }

class SpotBottomSheet extends ConsumerStatefulWidget {
  const SpotBottomSheet({super.key});

  @override
  ConsumerState<SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends ConsumerState<SpotBottomSheet> {
  _Tab _tab = _Tab.all;

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(filteredSpotsProvider);
    final lucky = spots.where((s) => s.rating == SpotRating.lucky).toList();
    final neutral = spots.where((s) => s.rating == SpotRating.neutral).toList();
    final challenging = spots.where((s) => s.rating == SpotRating.challenging).toList();

    final displayed = switch (_tab) {
      _Tab.lucky => lucky,
      _Tab.neutral => neutral,
      _Tab.challenging => challenging,
      _Tab.all => spots,
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.08,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.08, 0.12, 0.52, 0.92],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, -4))],
          ),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              SliverToBoxAdapter(child: _handle()),
              SliverToBoxAdapter(
                child: _Summary(
                  luckyCount: lucky.length,
                  neutralCount: neutral.length,
                  challengingCount: challenging.length,
                ),
              ),
              SliverToBoxAdapter(
                child: _TabBar(
                  selected: _tab,
                  total: spots.length,
                  luckyCount: lucky.length,
                  neutralCount: neutral.length,
                  challengingCount: challenging.length,
                  onSelect: (t) => setState(() => _tab = t),
                ),
              ),
              if (displayed.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _CityRow(
                      spot: displayed[i],
                      onTap: () => ref.read(selectedCityProvider.notifier).state = displayed[i],
                    ),
                    childCount: displayed.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _handle() => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: AppColors.hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

// ── Summary bar ──────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  final int luckyCount, neutralCount, challengingCount;
  const _Summary({required this.luckyCount, required this.neutralCount, required this.challengingCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$luckyCount lucky cities found',
              style: AppTextStyles.titleMd,
            ),
          ),
          _Pill(count: luckyCount, color: AppColors.spotLucky),
          const SizedBox(width: 6),
          _Pill(count: neutralCount, color: AppColors.spotNeutral),
          const SizedBox(width: 6),
          _Pill(count: challengingCount, color: AppColors.spotChallenging),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final int count;
  final Color color;
  const _Pill({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final _Tab selected;
  final int total, luckyCount, neutralCount, challengingCount;
  final ValueChanged<_Tab> onSelect;

  const _TabBar({
    required this.selected,
    required this.total,
    required this.luckyCount,
    required this.neutralCount,
    required this.challengingCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TabChip(label: 'All', count: total, active: selected == _Tab.all, onTap: () => onSelect(_Tab.all)),
            const SizedBox(width: 8),
            _TabChip(label: 'Lucky', count: luckyCount, color: AppColors.spotLucky, active: selected == _Tab.lucky, onTap: () => onSelect(_Tab.lucky)),
            const SizedBox(width: 8),
            _TabChip(label: 'Neutral', count: neutralCount, color: AppColors.spotNeutral, active: selected == _Tab.neutral, onTap: () => onSelect(_Tab.neutral)),
            const SizedBox(width: 8),
            _TabChip(label: 'Hard', count: challengingCount, color: AppColors.spotChallenging, active: selected == _Tab.challenging, onTap: () => onSelect(_Tab.challenging)),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.count, this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? c.withValues(alpha: 0.4) : AppColors.hairline,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(
              color: active ? c : AppColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            )),
            const SizedBox(width: 5),
            Text('$count', style: AppTextStyles.caption.copyWith(
              color: active ? c : AppColors.mutedSoft,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ── City row ──────────────────────────────────────────────────────────────────

class _CityRow extends StatelessWidget {
  final CitySpot spot;
  final VoidCallback onTap;
  const _CityRow({required this.spot, required this.onTap});

  Color _ratingColor(SpotRating r) => switch (r) {
    SpotRating.lucky => AppColors.spotLucky,
    SpotRating.neutral => AppColors.spotNeutral,
    SpotRating.challenging => AppColors.spotChallenging,
  };

  @override
  Widget build(BuildContext context) {
    final inf = spot.primaryInfluence;
    final ratingColor = _ratingColor(spot.rating);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairlineSoft, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 9, height: 9,
              decoration: BoxDecoration(color: ratingColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.cityName, style: AppTextStyles.titleSm),
                  const SizedBox(height: 1),
                  Text(spot.countryName, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            if (inf != null) ...[
              Text(inf.planet.glyph, style: TextStyle(fontSize: 14, color: inf.planet.color)),
              const SizedBox(width: 4),
              Text(inf.type.displayName,
                  style: AppTextStyles.caption.copyWith(color: inf.planet.color, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.mutedSoft),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✦', style: TextStyle(fontSize: 32, color: AppColors.hairline)),
            SizedBox(height: 12),
            Text('No cities in this category', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
