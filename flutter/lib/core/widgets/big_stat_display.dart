import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A label/value pair with the value at displayLarge — used for the
/// "remaining bags" counter (UI_SPEC.md OwnerDashboardScreen: the single
/// largest element on screen, tabular numerals). displayLarge is the largest
/// token in AppTypography, so the counter outranks every other text on the
/// screen by construction.
///
/// Stacked and start-aligned rather than label-left/value-right: split across
/// the full card width the two read as unrelated, and a numeric value sitting
/// to the left of its label is the first thing an RTL reader has to hunt for.
class BigStatDisplay extends StatelessWidget {
  const BigStatDisplay({
    super.key,
    required this.label,
    required this.value,
    this.semanticsLabel,
  });

  final String label;
  final String value;

  /// Spoken form of [value], for values whose glyphs don't read as words.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: semanticsLabel,
          child: Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
