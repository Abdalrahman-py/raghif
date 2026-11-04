import 'package:flutter/material.dart';

/// Stitch identity: bread-brown accent on a light blue-grey ground, with dark
/// text and labelled semantic states.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF2E3B2E);
  static const slate = Color(0xFF5B6357);

  static const accent = Color(0xFF884E00);
  static const accentPressed = Color(0xFF6A3B00);
  static const bread = Color(0xFFB8742A);
  static const gold = Color(0xFFD9A441);
  static const sage = Color(0xFF7A8F6B);
  static const warmSurface = Color(0xFFF6F8FB);
  static const neutralContainer = Color(0xFFE4EAF0);

  static const success = Color(0xFF4E6241);
  static const warning = Color(0xFF884E00);
  static const danger = Color(0xFFB91C1C);
  static const statusOn = Color(0xFFFFFFFF);

  static const background = Color(0xFFEEF2F6);
  static const surface = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onAccent = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF2E3B2E);
  static const textSecondary = Color(0xFF5B6357);
  static const border = Color(0xFFD9E0E8);

  /// Field outline; focus and validation use stronger semantic colors.
  static const inputBorder = Color(0xFFC3CDD8);

  /// Tint behind accent artwork (the intro slides' icon badge) and low-emphasis
  /// accent surfaces: same hue as [accent], dark enough text on it passes
  /// contrast.
  static const accentContainer = Color(0xFFE1E9F2);

  static const successContainer = Color(0xFFEDF3E9);
  static const warningContainer = Color(0xFFFCF2D8);
  static const dangerContainer = Color(0xFFFBE9E5);

  static const onSuccessContainer = Color(0xFF394C2D);
  static const onWarningContainer = Color(0xFF6A3B00);
  static const onDangerContainer = Color(0xFF7F1D1D);
}
