import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Success, warning and neutral container/content pairs. Material 3 has no
/// such roles (only error), so this is the app's one theme extension. Danger
/// reads the scheme's `errorContainer` / `onErrorContainer`.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.neutralContainer,
    required this.onNeutralContainer,
  });

  static const light = StatusColors(
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    neutralContainer: AppColors.neutralContainer,
    onNeutralContainer: AppColors.textSecondary,
  );

  /// The theme's set, or [light] where a widget is pumped without AppTheme.
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color neutralContainer;
  final Color onNeutralContainer;

  @override
  StatusColors copyWith({
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? neutralContainer,
    Color? onNeutralContainer,
  }) => StatusColors(
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    neutralContainer: neutralContainer ?? this.neutralContainer,
    onNeutralContainer: onNeutralContainer ?? this.onNeutralContainer,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      neutralContainer: Color.lerp(
        neutralContainer,
        other.neutralContainer,
        t,
      )!,
      onNeutralContainer: Color.lerp(
        onNeutralContainer,
        other.onNeutralContainer,
        t,
      )!,
    );
  }
}
