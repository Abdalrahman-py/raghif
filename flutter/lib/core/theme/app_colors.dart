import 'package:flutter/material.dart';

/// Civic/accessible palette per UI_SPEC.md — WCAG AAA, high-contrast,
/// sunlight-readable. Chosen for cheap/older phones, outdoor market use,
/// low-literacy/older users, no formal training. One trustworthy CTA blue,
/// near-black text, semantic status colors always paired with icon/label
/// (never color alone).
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0F172A); // header/nav chrome, owner-mode surfaces
  static const slate = Color(0xFF334155); // secondary text on light bg, dividers

  static const accent = Color(0xFF0369A1); // CTA — buy, notify next batch
  static const accentPressed = Color(0xFF075985);

  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFB91C1C);
  static const statusOn = Color(0xFFFFFFFF);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFFF8FAFC);
  static const onAccent = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF020617); // 16.8:1 on background
  static const textSecondary = Color(0xFF334155); // 7.5:1 min on background
  static const border = Color(0xFFCBD5E1);

  static const successContainer = Color(0xFFDCFCE7);
  static const warningContainer = Color(0xFFFEF3C7);
  static const dangerContainer = Color(0xFFFEE2E2);
}
