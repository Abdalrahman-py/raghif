import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
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
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String decrementLabel;
  final String incrementLabel;
  final int min;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          label: decrementLabel,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          label: incrementLabel,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.medium,
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Semantics(
            label: label,
            button: true,
            child: Icon(
              icon,
              color: onTap == null ? AppColors.border : AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
