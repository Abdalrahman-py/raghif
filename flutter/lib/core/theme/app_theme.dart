import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';
import 'status_colors.dart';

/// Dark mode intentionally out of scope for pilot — target devices are cheap,
/// often locked to light system theme (UI_SPEC.md). Revisit if OwnerDashboard
/// sees night use.
///
/// Material 3 port, Phase 0 (docs/superpowers/specs/2026-11-21-material3-port.md):
/// a full scheme from the brand seed, every text role at 15sp or more, and
/// component themes so call sites can use stock widgets bare.
class AppTheme {
  AppTheme._();

  /// One title style for every app bar.
  static final appBarTitle = AppTypography.titleMedium.copyWith(fontSize: 20);

  static ThemeData get light {
    // fromSeed fills every role stock widgets read; the brand values that must
    // not move are pinned on top. Without the surfaceContainerLowest override
    // fromSeed tints cards and sheets blue.
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: AppColors.accent,
          onPrimary: AppColors.onAccent,
          primaryContainer: AppColors.accentContainer,
          // fidelity's onPrimaryContainer is light (made for its saturated
          // container), unreadable on the pale brand container.
          onPrimaryContainer: AppColors.accentPressed,
          surface: AppColors.background,
          surfaceContainerLowest: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.inputBorder,
          outlineVariant: AppColors.border,
          error: AppColors.danger,
          onError: AppColors.statusOn,
          errorContainer: AppColors.dangerContainer,
          onErrorContainer: AppColors.onDangerContainer,
        );
    // Cards, sheets, dialogs and the bottom bar sit white on the #EEF2F6
    // ground; the stock defaults (surfaceContainerLow/High) are near the
    // ground's own tone and would disappear into it.
    final raised = colorScheme.surfaceContainerLowest;

    // 48dp: the touch-target floor, not the old 56dp everywhere. Pill is the
    // M3 default; label 16sp.
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'IBMPlexSansArabic',
      colorScheme: colorScheme,
      extensions: const [StatusColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleTextStyle: appBarTitle,
      ),
      // The selected tab is a solid accent pill with a white icon and an
      // accent label. The bar is set apart by its white tone, not by a shadow
      // or rounded corners.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.accent,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.onAccent
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.labelMedium.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 24),
      // Full width, as PrimaryButton has always been; call sites in rows wrap
      // it in Expanded.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          padding: buttonPadding,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      // Not full width: raw OutlinedButtons sit inside rows. SecondaryButton
      // asks for full width itself.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          backgroundColor: raised,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          padding: buttonPadding,
          textStyle: AppTypography.labelMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: AppTypography.labelMedium,
        ),
      ),
      // Stock IconButtons are 40dp; the floor is 48.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentContainer,
        labelStyle: AppTypography.bodySmall,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      // One card treatment: outlined, flat, white, 16dp corners. The border
      // lives in the shape, so a Card.filled call site that wants no outline
      // passes its own shape.
      cardTheme: CardThemeData(
        color: raised,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.large,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTypography.bodyLarge,
        subtitleTextStyle: AppTypography.bodyMedium,
        leadingAndTrailingTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        iconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
      ),
      // Floating, so it sits above a Scaffold's bottom bar instead of on it.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppShapes.small),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppShapes.extraLarge),
        titleTextStyle: AppTypography.titleLarge,
        contentTextStyle: AppTypography.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: raised,
        modalBackgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      // All 15 roles. The five M3 roles the app had left unset (displaySmall,
      // headline*, titleSmall) fell back to Material sizes, titleSmall to 14sp,
      // under the 15sp floor; each now maps to an existing AppTypography size.
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: AppTypography.displayLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: AppTypography.displayMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: AppTypography.titleLarge,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.labelMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShapes.medium,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.medium,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.medium,
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.medium,
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: AppTypography.bodyLarge,
        // Pinned rather than inherited: without these, Material supplies the
        // helper/error/counter lines from its own 12sp defaults, which sit
        // below this app's type floor and outside its font.
        helperStyle: AppTypography.bodySmall,
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.danger),
        counterStyle: AppTypography.bodySmall,
        helperMaxLines: 2,
        errorMaxLines: 2,
      ),
    );
  }
}
