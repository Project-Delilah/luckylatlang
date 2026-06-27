import 'package:flutter/material.dart';

// ── Dynamic color helper — resolves to light or dark values by context ─────────
class _DynamicColors {
  final BuildContext _ctx;
  const _DynamicColors(this._ctx);

  bool get _dark => Theme.of(_ctx).brightness == Brightness.dark;

  // Surfaces
  Color get canvas => _dark ? const Color(0xFF1A1815) : AppColors.canvas;
  Color get surfaceCard => _dark ? AppColors.surfaceDarkElevated : AppColors.surfaceCard;
  Color get surfaceSoft => _dark ? AppColors.surfaceDarkSoft : AppColors.surfaceSoft;

  // Text
  Color get ink => _dark ? AppColors.onDark : AppColors.ink;
  Color get body => _dark ? const Color(0xFFB8B4AC) : AppColors.body;
  Color get muted => _dark ? AppColors.onDarkSoft : AppColors.muted;
  Color get mutedSoft => _dark ? const Color(0xFF4A4845) : AppColors.mutedSoft;

  // Borders
  Color get hairline => _dark ? const Color(0xFF2E2A26) : AppColors.hairline;
  Color get hairlineSoft => _dark ? const Color(0xFF242019) : AppColors.hairlineSoft;
}

extension AppColorsX on BuildContext {
  // ignore: library_private_types_in_public_api
  _DynamicColors get colors => _DynamicColors(this);
}

abstract final class AppColors {
  // Brand
  static const canvas = Color(0xFFFAF9F5);
  static const surfaceCard = Color(0xFFEFE9DE);
  static const surfaceSoft = Color(0xFFF5F0E8);
  static const surfaceDark = Color(0xFF181715);
  static const surfaceDarkElevated = Color(0xFF252320);
  static const surfaceDarkSoft = Color(0xFF1F1E1B);

  static const primary = Color(0xFFCC785C);
  static const primaryActive = Color(0xFFA9583E);
  static const primaryDisabled = Color(0xFFE6DFD8);

  static const accentTeal = Color(0xFF5DB8A6);
  static const accentAmber = Color(0xFFE8A55A);

  static const hairline = Color(0xFFE6DFD8);
  static const hairlineSoft = Color(0xFFEBE6DF);

  // Text
  static const ink = Color(0xFF141413);
  static const bodyStrong = Color(0xFF252523);
  static const body = Color(0xFF3D3D3A);
  static const muted = Color(0xFF6C6A64);
  static const mutedSoft = Color(0xFF8E8B82);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onDark = Color(0xFFFAF9F5);
  static const onDarkSoft = Color(0xFFA09D96);

  // Semantic
  static const success = Color(0xFF5DB872);
  static const warning = Color(0xFFD4A017);
  static const error = Color(0xFFC64545);

  // Planet line colors
  static const planetSun = Color(0xFFE8A55A);
  static const planetMoon = Color(0xFFB8C4CC);
  static const planetMercury = Color(0xFF7EB8D4);
  static const planetVenus = Color(0xFFE8A0B4);
  static const planetMars = Color(0xFFCC5C5C);
  static const planetJupiter = Color(0xFF8B6FC8);
  static const planetSaturn = Color(0xFF9B8B6C);
  static const planetUranus = Color(0xFF5DC8B8);
  static const planetNeptune = Color(0xFF4A7CC8);
  static const planetPluto = Color(0xFF7C4A7C);

  // Spot rating
  static const spotLucky = Color(0xFF5DB872);
  static const spotNeutral = Color(0xFFE8A55A);
  static const spotChallenging = Color(0xFFC64545);
}
