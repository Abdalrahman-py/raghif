import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_spacing.dart';
import 'secondary_button.dart';

/// Shown in place of a screen's data when the server could not be reached.
///
/// The app keeps no local copy (constitution I), so an empty list here would
/// read as "nothing there" when the truth is "could not ask".
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              Strings.offlineRead,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(text: Strings.retryButton, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
