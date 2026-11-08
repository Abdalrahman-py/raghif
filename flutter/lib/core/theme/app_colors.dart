import 'package:flutter/material.dart';

/// Brand identity: the logo's blue as the accent on a light blue-grey ground,
/// with dark ink text and labelled semantic states. (The old bread-brown /
/// beige accent was dropped: it read as traditional.)
class AppColors {
  AppColors._();

  static const navy = Color(0xFF1B2433);
  static const slate = Color(0xFF566074);

  static const accent = Color(0xFF1D4ED8);
  static const accentPressed = Color(0xFF1E40AF);
  static const bread = Color(0xFF2563EB);
  static const gold = Color(0xFFF59E0B);
  static const sage = Color(0xFF5B8A72);
  static const warmSurface = Color(0xFFF6F8FB);
  static const neutralContainer = Color(0xFFE4EAF0);

  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFB91C1C);
  static const statusOn = Color(0xFFFFFFFF);

  static const background = Color(0xFFEEF2F6);
  static const surface = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onAccent = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1B2433);
  static const textSecondary = Color(0xFF566074);
  static const border = Color(0xFFD9E0E8);

  /// Field outline; focus and validation use stronger semantic colors.
  static const inputBorder = Color(0xFFC3CDD8);

  /// Tint behind accent artwork (the intro slides' icon badge) and low-emphasis
  /// accent surfaces: same hue as [accent], dark enough text on it passes
  /// contrast.
  static const accentContainer = Color(0xFFDCE7FB);

  static const successContainer = Color(0xFFE3F4EA);
  static const warningContainer = Color(0xFFFFEDD5);
  static const dangerContainer = Color(0xFFFBE9E5);

  static const onSuccessContainer = Color(0xFF14532D);
  static const onWarningContainer = Color(0xFF7C2D12);
  static const onDangerContainer = Color(0xFF7F1D1D);
}
