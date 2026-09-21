import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;

  /// Makes the whole card one tap target (the card *is* the action) — same
  /// rule as the buyer's store cards.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      // The rounded corners are the card's own shape; without clipping, the
      // ink splash of a tappable card paints square corners over them. Only
      // applied when the card is a tap target, so non-interactive cards render
      // exactly as before.
      clipBehavior: onTap == null ? Clip.none : Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
