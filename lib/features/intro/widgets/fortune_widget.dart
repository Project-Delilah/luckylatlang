import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/fortunes.dart' as seed;

// How the card looks
enum FortuneWidgetStyle { coral, dark, material }

const _kPrefKey = 'fortune_quotes_v1';
const _kSrc =
    'https://raw.githubusercontent.com/shlomif/fortune-mod/master/fortune-mod/datfiles/wisdom';

class FortuneWidget extends StatefulWidget {
  final FortuneWidgetStyle style;
  const FortuneWidget({super.key, this.style = FortuneWidgetStyle.dark});

  @override
  State<FortuneWidget> createState() => _FortuneWidgetState();
}

class _FortuneWidgetState extends State<FortuneWidget>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  List<String> _pool = [];
  String _current = '';
  bool _fetching = false;

  // Pulse controller for loading bars
  late final AnimationController _pulse;
  late final Animation<double> _pulseA;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseA = Tween(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _init();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── boot ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kPrefKey);
    if (cached != null) {
      final list = (jsonDecode(cached) as List).cast<String>();
      if (list.isNotEmpty) {
        _setPool(list);
        return;
      }
    }
    // seed from local file so something always shows immediately
    _setPool(seed.fortunes);
    // then try to pull fresher quotes
    _fetch(seedFirst: true);
  }

  void _setPool(List<String> pool) {
    if (!mounted) return;
    setState(() {
      _pool = pool;
      _current = pool[_rng.nextInt(pool.length)];
    });
  }

  // ── GitHub fetch ──────────────────────────────────────────────────────────

  Future<void> _fetch({bool seedFirst = false}) async {
    if (_fetching) return;
    if (mounted) setState(() => _fetching = true);
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(_kSrc));
      req.headers.set(HttpHeaders.userAgentHeader, 'luckylatlang/flutter');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        client.close();
        final list = _parse(body);
        if (list.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kPrefKey, jsonEncode(list));
          _setPool(list);
        }
      } else {
        client.close();
      }
    } catch (_) {
      // network failure: keep whatever is showing
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  // fortune-mod `%` separator — handles both `\n%\n` and `%\n` at line start
  List<String> _parse(String raw) {
    return raw
        .split(RegExp(r'\n%\n?'))
        .map((s) => s.trim())
        .where((s) => s.length >= 30 && s.length <= 420 && !s.startsWith('#'))
        .toList();
  }

  // ── interaction ───────────────────────────────────────────────────────────

  void _cycle() {
    if (_pool.isEmpty) return;
    String next;
    do {
      next = _pool[_rng.nextInt(_pool.length)];
    } while (next == _current && _pool.length > 1);
    setState(() => _current = next);
  }

  // ── colors by style ───────────────────────────────────────────────────────

  Color _bg(BuildContext ctx) => switch (widget.style) {
        FortuneWidgetStyle.coral => AppColors.primary,
        FortuneWidgetStyle.dark => AppColors.surfaceDark,
        FortuneWidgetStyle.material =>
          Theme.of(ctx).colorScheme.secondaryContainer,
      };

  Color _fg(BuildContext ctx) => switch (widget.style) {
        FortuneWidgetStyle.coral => Colors.white,
        FortuneWidgetStyle.dark => AppColors.onDark,
        FortuneWidgetStyle.material =>
          Theme.of(ctx).colorScheme.onSecondaryContainer,
      };

  Color _soft(BuildContext ctx) => switch (widget.style) {
        FortuneWidgetStyle.coral => Colors.white.withValues(alpha: 0.55),
        FortuneWidgetStyle.dark => AppColors.onDarkSoft,
        FortuneWidgetStyle.material =>
          Theme.of(ctx).colorScheme.onSecondaryContainer.withValues(alpha: 0.55),
      };

  Border? _border() => switch (widget.style) {
        FortuneWidgetStyle.dark => Border.all(color: Colors.white10),
        _ => null,
      };

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = _bg(context);
    final fg = _fg(context);
    final soft = _soft(context);

    return GestureDetector(
      onTap: _cycle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: _border(),
        ),
        child: _fetching && _current.isEmpty
            ? _Shimmer(anim: _pulseA, fg: fg)
            : _Body(
                quote: _current,
                fg: fg,
                soft: soft,
                fetching: _fetching,
                onRefresh: _fetch,
              ),
      ),
    );
  }
}

// ── Quote body ─────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final String quote;
  final Color fg, soft;
  final bool fetching;
  final VoidCallback onRefresh;
  const _Body({
    required this.quote,
    required this.fg,
    required this.soft,
    required this.fetching,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (quote.isEmpty) {
      return Row(
        children: [
          Icon(Icons.format_quote_rounded, size: 16, color: soft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap ↺ to load quotes from fortune-mod',
              style: _quoteStyle(soft),
            ),
          ),
          _RefreshBtn(fetching: fetching, color: soft, onTap: onRefresh),
        ],
      );
    }

    // Split attribution line (starts with —)
    final lines = quote.split('\n');
    final hasAttr = lines.length > 1 && lines.last.trimLeft().startsWith('—');
    final body =
        hasAttr ? lines.sublist(0, lines.length - 1).join('\n').trim() : quote;
    final attr = hasAttr ? lines.last.trim() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.format_quote_rounded, size: 14, color: soft),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(body, style: _quoteStyle(fg)),
            ),
            const SizedBox(width: 8),
            _RefreshBtn(fetching: fetching, color: soft, onTap: onRefresh),
          ],
        ),
        if (attr != null) ...[
          const SizedBox(height: 10),
          Text(attr, style: _attrStyle(soft)),
        ],
        const SizedBox(height: 6),
        Text('tap to cycle', style: _hintStyle(soft)),
      ],
    );
  }

  TextStyle _quoteStyle(Color c) => GoogleFonts.cormorantGaramond(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: c,
      );

  TextStyle _attrStyle(Color c) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: c,
        letterSpacing: 0.1,
      );

  TextStyle _hintStyle(Color c) => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w400,
        color: c.withValues(alpha: 0.6),
        letterSpacing: 0.8,
      );
}

// ── Refresh button — shows spinner while fetching ──────────────────────────────

class _RefreshBtn extends StatelessWidget {
  final bool fetching;
  final Color color;
  final VoidCallback onTap;
  const _RefreshBtn(
      {required this.fetching, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fetching ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: fetching
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              )
            : Icon(Icons.refresh_rounded, size: 14, color: color),
      ),
    );
  }
}

// ── Shimmer skeleton (initial load with no cache) ──────────────────────────────

class _Shimmer extends StatelessWidget {
  final Animation<double> anim;
  final Color fg;
  const _Shimmer({required this.anim, required this.fg});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(double.infinity, anim.value),
          const SizedBox(height: 9),
          _bar(double.infinity, anim.value * 0.85),
          const SizedBox(height: 9),
          _bar(180, anim.value * 0.65),
          const SizedBox(height: 16),
          _bar(100, anim.value * 0.4),
        ],
      ),
    );
  }

  Widget _bar(double w, double opacity) => Container(
        width: w,
        height: 11,
        decoration: BoxDecoration(
          color: fg.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
