import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get _serif => GoogleFonts.cormorantGaramond();
  static TextStyle get _sans => GoogleFonts.inter();

  static TextStyle displayXl = _serif.copyWith(
    fontSize: 52,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.5,
    height: 1.05,
    color: AppColors.ink,
  );

  static TextStyle displayLg = _serif.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.0,
    height: 1.1,
    color: AppColors.ink,
  );

  static TextStyle displayMd = _serif.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.15,
    color: AppColors.ink,
  );

  static TextStyle displaySm = _serif.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.2,
    color: AppColors.ink,
  );

  static TextStyle titleLg = _sans.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.ink,
  );

  static TextStyle titleMd = _sans.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.ink,
  );

  static TextStyle titleSm = _sans.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.ink,
  );

  static TextStyle bodyMd = _sans.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.body,
  );

  static TextStyle bodySm = _sans.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.body,
  );

  static TextStyle caption = _sans.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.muted,
  );

  static TextStyle captionUppercase = _sans.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.2,
    color: AppColors.muted,
  );

  static TextStyle button = _sans.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.onPrimary,
  );

  // On-dark variants
  static TextStyle displayLgOnDark = displayLg.copyWith(color: AppColors.onDark);
  static TextStyle displayMdOnDark = displayMd.copyWith(color: AppColors.onDark);
  static TextStyle bodyMdOnDark = bodyMd.copyWith(color: AppColors.onDark);
  static TextStyle bodySmOnDark = bodySm.copyWith(color: AppColors.onDarkSoft);
}
