import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../../providers/profile_provider.dart';

// ── Theme mode — persisted in SharedPreferences ────────────────────────────────

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void set(ThemeMode mode) {
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = mode;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ── Theme data ─────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF1A1815) : AppColors.canvas;
    final ink = isDark ? AppColors.onDark : AppColors.ink;
    final hairline = isDark ? const Color(0xFF2E2A26) : AppColors.hairline;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accentTeal,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: canvas,
        onSurface: ink,
        outline: hairline,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 52, fontWeight: FontWeight.w400, letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 40, fontWeight: FontWeight.w400, letterSpacing: -1.0,
        ),
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 30, fontWeight: FontWeight.w400, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: hairline),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 0),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle:
            GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceDarkElevated : AppColors.surfaceCard,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
