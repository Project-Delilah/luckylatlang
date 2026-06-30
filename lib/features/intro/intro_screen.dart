import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/profile_provider.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _proceed() {
    final profile = ref.read(profileProvider);
    if (profile != null) {
      context.push(Routes.map);
    } else {
      context.push(Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        children: [
          // Subtle star field background
          const _StarField(),
          // Radial gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0x00000000), Color(0xFF141410)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.92, end: 1.0).animate(_scaleAnim),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lucky\nLat·Lang',
                            style: AppTextStyles.displayXl.copyWith(
                              color: AppColors.onDark,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 48,
                            height: 2,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Discover the places on Earth\nwhere the stars align for you.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onDarkSoft,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CoralButton(
                          label: 'Begin',
                          onTap: _proceed,
                        ),
                        const SizedBox(height: 12),
                        Consumer(builder: (ctx, r, _) {
                          final profile = r.watch(profileProvider);
                          if (profile == null) return const SizedBox.shrink();
                          return TextButton(
                            onPressed: () => ctx.push(Routes.profile),
                            child: Text(
                              'Change profile',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedSoft),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoralButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CoralButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.button.copyWith(fontSize: 15)),
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StarPainter extends CustomPainter {
  static final _rng = math.Random(42);
  static final _stars = List.generate(200, (_) => Offset(
    _rng.nextDouble(), _rng.nextDouble(),
  ));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final star in _stars) {
      final radius = _rng.nextDouble() * 1.2 + 0.3;
      final opacity = _rng.nextDouble() * 0.6 + 0.2;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(star.dx * size.width, star.dy * size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
