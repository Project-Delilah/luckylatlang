import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final String _mysticPath;

  @override
  void initState() {
    super.initState();
    final idx = math.Random().nextInt(30);
    _mysticPath = idx < 28
        ? 'assets/mystic/module_timeline_shop_sign_edu_${(idx + 1).toString().padLeft(2, '0')}.webp'
        : idx == 28
            ? 'assets/mystic/module_timeline_shop_void.webp'
            : 'assets/mystic/module_timeline_shop_year_ahead.webp';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: AppColors.onDark,
            pinned: true,
            elevation: 0,
            title: Text(
              'About',
              style: AppTextStyles.titleMd.copyWith(color: AppColors.onDark),
            ),
          ),

          // ── App identity block (dark) ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surfaceDark,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App glyph
                  const Text('✦', style: TextStyle(fontSize: 36, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text(
                    'Lucky Lat·Lang',
                    style: AppTextStyles.displayMd.copyWith(color: AppColors.onDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Personal astrocartography — discover the places\non Earth that resonate with your birth chart.',
                    style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onDarkSoft, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  // Version chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDarkElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── What is astrocartography (canvas) ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What is Astrocartography?',
                      style: AppTextStyles.displaySm.copyWith(color: context.colors.ink)),
                  const SizedBox(height: 14),
                  Text(
                    'Astrocartography maps where the planets were rising, setting, or at their highest point at the exact moment you were born. These celestial positions trace lines across the globe — zones where specific planetary energies are at their strongest for you personally.',
                    style: AppTextStyles.bodyMd.copyWith(color: context.colors.body),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The theory, developed by Jim Lewis in the 1970s, holds that geography amplifies the natal chart. Moving to — or visiting — a location near one of your planetary lines shifts which parts of your chart come to the foreground of your life.',
                    style: AppTextStyles.bodyMd.copyWith(color: context.colors.body),
                  ),
                ],
              ),
            ),
          ),

          // ── How it works (card band) ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              decoration: BoxDecoration(
                color: context.colors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How the app works',
                      style: AppTextStyles.titleMd.copyWith(color: context.colors.ink)),
                  const SizedBox(height: 16),
                  ..._steps.map((s) => _Step(number: s.$1, text: s.$2)),
                ],
              ),
            ),
          ),

          // ── Mystic polaroid ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 0),
              child: Transform.rotate(
                angle: -0.025,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 28,
                          offset: Offset(0, 10)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    child: Image.asset(_mysticPath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),

          // ── Planet key (canvas) ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reading your map',
                      style: AppTextStyles.displaySm.copyWith(color: context.colors.ink)),
                  const SizedBox(height: 6),
                  Text(
                    'Each planet line carries a distinct quality:',
                    style: AppTextStyles.bodyMd.copyWith(color: context.colors.muted),
                  ),
                  const SizedBox(height: 16),
                  ..._planets.map((p) => _PlanetRow(glyph: p.$1, name: p.$2, meaning: p.$3, color: p.$4)),
                ],
              ),
            ),
          ),

          // ── Rating legend (coral callout) ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('City ratings',
                      style: AppTextStyles.titleSm.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 12),
                  _RatingRow(color: AppColors.spotLucky, label: 'Lucky',
                      desc: 'Strong beneficial planet lines within 500 km'),
                  const SizedBox(height: 8),
                  _RatingRow(color: AppColors.spotNeutral, label: 'Neutral',
                      desc: 'Mild or balanced influences nearby'),
                  const SizedBox(height: 8),
                  _RatingRow(color: AppColors.spotChallenging, label: 'Challenging',
                      desc: 'Lines that bring tension or transformation'),
                ],
              ),
            ),
          ),

          // ── Developer section (dark) ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 36),
              color: AppColors.surfaceDark,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ABOUT THE DEVELOPER',
                      style: AppTextStyles.captionUppercase
                          .copyWith(color: AppColors.onDarkSoft)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Avatar — network image with initials fallback
                      ClipOval(
                        child: Image.network(
                          'https://avatars.githubusercontent.com/u/95901240?v=4',
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 68,
                            height: 68,
                            color: AppColors.primary,
                            alignment: Alignment.center,
                            child: Text('SG',
                                style: AppTextStyles.titleMd
                                    .copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sapan Gajjar',
                                style: AppTextStyles.titleMd
                                    .copyWith(color: AppColors.onDark)),
                            const SizedBox(height: 3),
                            Text('Fullstack Developer · Ahmedabad, India',
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.onDarkSoft)),
                            const SizedBox(height: 6),
                            // GitHub pill
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(
                                    text: 'https://github.com/isg32'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Link copied'),
                                    backgroundColor: AppColors.surfaceDarkElevated,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDarkElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.code_rounded,
                                        size: 13, color: AppColors.onDarkSoft),
                                    const SizedBox(width: 5),
                                    Text('github.com/isg32',
                                        style: AppTextStyles.caption
                                            .copyWith(color: AppColors.onDarkSoft)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Motto
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    child: Text(
                      '"When we lose our principles, we invite chaos"',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onDark,
                          fontStyle: FontStyle.italic,
                          height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sapan is a fullstack developer and Flutter enthusiast building apps at the intersection of design and functionality. With 115+ open-source projects spanning Android, web, and IoT — and a focus on clean, purposeful interfaces — Lucky Lat·Lang brings together orbital mechanics, cartography, and personal astrology into one cohesive experience.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onDarkSoft, height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  // Tech stack chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Flutter', 'Dart', 'Pure Orbital Mechanics',
                      'OpenStreetMap', 'GeoNames DB']
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDarkElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(t,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.onDarkSoft)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
        ],
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

const _steps = [
  ('1', 'Enter your birth date, time, and place — the more precise, the better.'),
  ('2', 'The app computes your planetary positions using Meeus orbital mechanics.'),
  ('3', 'Planet lines are drawn on the world map — each planet traces 4 lines (rising, setting, MC, IC).'),
  ('4', 'Cities within 500 km of a line are scored and coloured: lucky, neutral, or challenging.'),
  ('5', 'Tap any city or blank spot on the map to see a detailed breakdown of planetary influences.'),
];

const _planets = [
  ('☉', 'Sun', 'Vitality, identity, recognition. A Sun line brings life purpose into focus.', AppColors.planetSun),
  ('☽', 'Moon', 'Emotions, home, intuition. A Moon line deepens feeling and belonging.', AppColors.planetMoon),
  ('☿', 'Mercury', 'Communication, learning, travel. Sharpens the mind and social connections.', AppColors.planetMercury),
  ('♀', 'Venus', 'Love, beauty, creativity. Draws art, relationships, and aesthetic pleasure.', AppColors.planetVenus),
  ('♂', 'Mars', 'Drive, assertion, ambition. Energising but can bring conflict.', AppColors.planetMars),
  ('♃', 'Jupiter', 'Expansion, luck, growth. Often the most broadly "lucky" line.', AppColors.planetJupiter),
  ('♄', 'Saturn', 'Discipline, structure, challenge. Hard-won growth and responsibility.', AppColors.planetSaturn),
  ('♅', 'Uranus', 'Innovation, disruption, freedom. Unpredictable change and breakthroughs.', AppColors.planetUranus),
  ('♆', 'Neptune', 'Spirituality, dreams, dissolution. Idealistic; can blur boundaries.', AppColors.planetNeptune),
];

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: AppTextStyles.bodyMd.copyWith(color: context.colors.body)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanetRow extends StatelessWidget {
  final String glyph;
  final String name;
  final String meaning;
  final Color color;
  const _PlanetRow(
      {required this.glyph, required this.name, required this.meaning, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(glyph, style: TextStyle(fontSize: 20, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.titleSm.copyWith(color: context.colors.ink)),
                const SizedBox(height: 2),
                Text(meaning,
                    style: AppTextStyles.bodySm.copyWith(color: context.colors.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final Color color;
  final String label;
  final String desc;
  const _RatingRow({required this.color, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 9, height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text('$label  ', style: AppTextStyles.bodySm.copyWith(
            color: color, fontWeight: FontWeight.w600)),
        Expanded(child: Text(desc,
            style: AppTextStyles.bodySm.copyWith(color: context.colors.body))),
      ],
    );
  }
}
