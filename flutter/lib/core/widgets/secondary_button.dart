import 'package:flutter/material.dart';

/// Outlined, not filled — a solid second button would compete visually with
/// the screen's one primary action (UI_SPEC.md PurchaseScreen treatment).
/// A stock [OutlinedButton] styled by `outlinedButtonTheme`, full width.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;

  /// Shows a spinner and disables the button, so a slow write can't be
  /// triggered twice.
  final bool loading;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: loading ? null : onPressed,
    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    child: loading
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(text, textAlign: TextAlign.center),
  );
}
