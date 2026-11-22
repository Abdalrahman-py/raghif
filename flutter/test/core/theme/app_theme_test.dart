import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/theme/app_colors.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/core/theme/status_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final theme = AppTheme.light;
  final scheme = theme.colorScheme;

  test('every TextTheme role is set and at least 15sp', () {
    final t = theme.textTheme;
    final roles = <String, TextStyle?>{
      'displayLarge': t.displayLarge,
      'displayMedium': t.displayMedium,
      'displaySmall': t.displaySmall,
      'headlineLarge': t.headlineLarge,
      'headlineMedium': t.headlineMedium,
      'headlineSmall': t.headlineSmall,
      'titleLarge': t.titleLarge,
      'titleMedium': t.titleMedium,
      'titleSmall': t.titleSmall,
      'bodyLarge': t.bodyLarge,
      'bodyMedium': t.bodyMedium,
      'bodySmall': t.bodySmall,
      'labelLarge': t.labelLarge,
      'labelMedium': t.labelMedium,
      'labelSmall': t.labelSmall,
    };
    for (final MapEntry(:key, :value) in roles.entries) {
      expect(value?.fontSize, greaterThanOrEqualTo(15), reason: key);
    }
  });

  test('brand roles stay put after fromSeed', () {
    expect(scheme.primary, AppColors.accent);
    expect(scheme.primaryContainer, AppColors.accentContainer);
    expect(scheme.surface, AppColors.background);
    expect(scheme.surfaceContainerLowest, AppColors.surface);
    expect(scheme.error, AppColors.danger);
    expect(theme.extension<StatusColors>(), isNotNull);
  });

  test('buttons are 48dp pills with 16sp labels', () {
    for (final style in [
      theme.filledButtonTheme.style!,
      theme.outlinedButtonTheme.style!,
      theme.textButtonTheme.style!,
    ]) {
      expect(style.minimumSize!.resolve({})!.height, 48);
      expect(style.shape!.resolve({}), isA<StadiumBorder>());
      expect(style.textStyle!.resolve({})!.fontSize, 16);
    }
    expect(
      theme.iconButtonTheme.style!.minimumSize!.resolve({}),
      const Size(48, 48),
    );
  });

  test('text on unoverridden scheme roles is at least 4.5:1', () {
    final pairs = <String, (Color, Color)>{
      'onPrimary/primary': (scheme.onPrimary, scheme.primary),
      'onPrimaryContainer/primaryContainer': (
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      ),
      'onSecondaryContainer/secondaryContainer': (
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      'onTertiaryContainer/tertiaryContainer': (
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
      ),
      'onSurfaceVariant/surfaceContainerHighest': (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      'onSurface/surface': (scheme.onSurface, scheme.surface),
      'onErrorContainer/errorContainer': (
        scheme.onErrorContainer,
        scheme.errorContainer,
      ),
    };
    final failing = [
      for (final MapEntry(:key, value: (fg, bg)) in pairs.entries)
        if (_contrast(fg, bg) < 4.5)
          '$key ${_contrast(fg, bg).toStringAsFixed(2)}',
    ];
    expect(failing, isEmpty);
  });
}
