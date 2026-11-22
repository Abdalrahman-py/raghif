import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// +/- stepper over free-text entry — fewer input errors for numeric fields
/// an owner edits mid-crowd (UI_SPEC.md OwnerDashboardScreen treatment).
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.decrementLabel,
    required this.incrementLabel,
    this.min = 0,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String decrementLabel;
  final String incrementLabel;
  final int min;

  /// How much one tap moves the value. Large ranges (300 bags a day) would
  /// take dozens of +1 taps.
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The tooltip is the button's accessible name.
        IconButton.outlined(
          icon: const Icon(Icons.remove),
          tooltip: decrementLabel,
          onPressed: value > min
              ? () => onChanged(value - step < min ? min : value - step)
              : null,
        ),
        // A floor, not a fixed width: "300" at a large font scale must not
        // wrap.
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add),
          tooltip: incrementLabel,
          onPressed: () => onChanged(value + step),
        ),
      ],
    );
  }
}
