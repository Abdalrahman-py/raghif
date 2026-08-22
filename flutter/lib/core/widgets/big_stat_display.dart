import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// A label/value pair with the value at displayMedium — used for the
/// "Remaining: X / Y" counter (UI_SPEC.md OwnerDashboardScreen: the single
/// largest element on screen, tabular numerals).
class BigStatDisplay extends StatelessWidget {
  const BigStatDisplay({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.displayMedium.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
