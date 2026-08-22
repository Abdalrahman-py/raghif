import 'package:flutter/material.dart';
import 'app_colors.dart';

const _fontFamily = 'NotoSansArabic';

/// Sizes per UI_SPEC.md token table — legible in sunlight, for a queue app
/// used standing up. Floor is bodyMedium (15sp); nothing in the app goes
/// below that.
class AppTypography {
  AppTypography._();

  static const displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 42 / 28,
    color: AppColors.textPrimary,
  );
  static const displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 36 / 24,
    color: AppColors.textPrimary,
  );
  static const titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 33 / 22,
    color: AppColors.textPrimary,
  );
  static const titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 27 / 18,
    color: AppColors.textPrimary,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 17,
    height: 26 / 17,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 23 / 15,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );
  static const labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.3,
    color: AppColors.onAccent,
  );
  static const labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 23 / 15,
    letterSpacing: 0.3,
  );
}
