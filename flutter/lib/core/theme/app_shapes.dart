import 'package:flutter/material.dart';

/// The Material 3 corner scale (UI_SPEC.md "Shape & Spacing"), so stock M3
/// widgets need no shape overrides: small = chips/badges, medium = inputs,
/// large = cards, extraLarge = dialogs and sheets. Buttons stay full pills,
/// which is the M3 default.
class AppShapes {
  AppShapes._();

  static const small = BorderRadius.all(Radius.circular(8));
  static const medium = BorderRadius.all(Radius.circular(12));
  static const large = BorderRadius.all(Radius.circular(16));
  static const extraLarge = BorderRadius.all(Radius.circular(28));
}
