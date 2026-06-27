import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Full-screen overlay shown while astro / city computations are running.
class ComputingOverlay extends StatefulWidget {
  final bool computingLines; // true = astro pass; false = city-scoring pass
  const ComputingOverlay({super.key, required this.computingLines});

  @override
  State<ComputingOverlay> createState() => _ComputingOverlayState();
}

class _ComputingOverlayState extends State<ComputingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        color: AppColors.surfaceDark.withValues(alpha: 0.94),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: Listenable.merge([_spin, _pulse]),
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OrbitalRing(
                  spinT: _spin.value,
                  pulseT: _pulse.value,
                ),
                const SizedBox(height: 40),
                Text(
                  'Charting the heavens',
                  style: AppTextStyles.displaySm.copyWith(color: AppColors.onDark),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.computingLines
                        ? 'Computing planet lines…'
                        : 'Scoring 170,000 cities…',
                    key: ValueKey(widget.computingLines),
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onDarkSoft),
                  ),
                ),
                const SizedBox(height: 48),
                _DotRow(pulseT: _pulse.value),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Orbital ring custom painter ───────────────────────────────────────────────

class _OrbitalRing extends StatelessWidget {
  final double spinT;   // 0.0 → 1.0, repeating
  final double pulseT;  // 0.0 → 1.0, reverse-repeating

  const _OrbitalRing({required this.spinT, required this.pulseT});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      height: 136,
      child: CustomPaint(
        painter: _RingPainter(spinT: spinT, pulseT: pulseT),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double spinT;
  final double pulseT;
  const _RingPainter({required this.spinT, required this.pulseT});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 2;
    final innerR = outerR * 0.42;

    // Hairline orbit track
    canvas.drawCircle(
      c, outerR,
      Paint()
        ..color = AppColors.mutedSoft.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Faint second orbit ring
    canvas.drawCircle(
      c, outerR * 0.70,
      Paint()
        ..color = AppColors.mutedSoft.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );

    // Spinning coral arc — long sweep on first ring
    final arcAngle = spinT * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR),
      arcAngle,
      math.pi * 0.65,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Counter-spinning amber arc on second ring
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR * 0.70),
      -arcAngle * 0.7,
      math.pi * 0.4,
      false,
      Paint()
        ..color = AppColors.accentAmber.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Pulsing inner glow disc
    final glowAlpha = 0.07 + 0.07 * pulseT;
    canvas.drawCircle(
      c,
      innerR * (0.88 + 0.12 * pulseT),
      Paint()
        ..color = AppColors.primary.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.fill,
    );

    // Center star glyph via TextPainter
    final glyphAlpha = 0.55 + 0.45 * pulseT;
    final tp = TextPainter(
      text: TextSpan(
        text: '✦',
        style: TextStyle(
          fontSize: 26,
          color: AppColors.primary.withValues(alpha: glyphAlpha),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));

    // Small dot orbiting on outer ring (planet marker)
    final dotAngle = arcAngle + math.pi * 0.65;
    final dotX = c.dx + outerR * math.cos(dotAngle);
    final dotY = c.dy + outerR * math.sin(dotAngle);
    canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      Offset(dotX, dotY), 6,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.spinT != spinT || old.pulseT != pulseT;
}

// ── Animated dot row ──────────────────────────────────────────────────────────

class _DotRow extends StatelessWidget {
  final double pulseT;
  const _DotRow({required this.pulseT});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = ((pulseT + i / 3) % 1.0);
        final alpha = 0.25 + 0.75 * math.sin(t * math.pi).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: alpha),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
