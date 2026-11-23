import 'package:flutter/material.dart';

/// The screen's one main action: a stock [FilledButton] (size, shape and
/// colours from `filledButtonTheme`) plus the loading state stock buttons lack.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;

  /// Shows a spinner and disables the button, so a slow write can't be
  /// triggered twice.
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    // The spinner sits on the disabled fill, so it takes the scheme's primary
    // rather than white.
    child: loading
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(text, textAlign: TextAlign.center),
  );
}
