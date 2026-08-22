import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_typography.dart';

enum StatusTone { success, warning, danger, neutral }

class _ToneColors {
  const _ToneColors(this.container, this.content);
  final Color container;
  final Color content;
}

_ToneColors _toneColors(StatusTone tone) {
  switch (tone) {
    case StatusTone.success:
      return const _ToneColors(AppColors.successContainer, AppColors.success);
    case StatusTone.warning:
      return const _ToneColors(AppColors.warningContainer, AppColors.warning);
    case StatusTone.danger:
      return const _ToneColors(AppColors.dangerContainer, AppColors.danger);
    case StatusTone.neutral:
      return const _ToneColors(Color(0xFFE2E8F0), AppColors.textSecondary);
  }
}

/// Status pairs a color with an icon/label — color is never the only signal
/// (colorblind + grayscale-screen-in-sunlight safe), per UI_SPEC.md.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.text, required this.tone});

  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);
    final icon = switch (tone) {
      StatusTone.success => Icons.check_circle,
      StatusTone.danger => Icons.error,
      _ => Icons.info,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: AppShapes.small,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.content),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTypography.labelMedium.copyWith(color: colors.content),
            ),
          ],
        ),
      ),
    );
  }
}
