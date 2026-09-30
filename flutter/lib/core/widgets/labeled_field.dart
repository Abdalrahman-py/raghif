import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A form field with its label above it, at full size.
///
/// Material's floating label shrinks to 75% once a field has focus or text, so
/// a 17sp label becomes ~12.75sp — under the 15sp floor (constitution V) and
/// exactly when an older user is checking what they just typed. Here the label
/// never moves or shrinks. Screen readers still get it as the field's label.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(label: label, child: child),
      ],
    );
  }
}
