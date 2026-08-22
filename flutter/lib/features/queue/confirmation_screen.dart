import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'models.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';
import 'store_list_screen.dart';

/// UI_SPEC.md ConfirmationScreen: big status statement, batch/store at
/// titleMedium, plain-language status while waiting rather than a raw
/// countdown digit grid.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.controller,
    required this.purchaseId,
  });

  final QueueController controller;
  final String purchaseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Strings.confirmationTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final purchase = controller.purchaseById(purchaseId);
          if (purchase == null) return const SizedBox.shrink();
          final queue = controller.queueForStore(
            purchase.storeId,
            purchase.purchaseDate,
          );
          final position = queue.indexWhere((p) => p.id == purchaseId) + 1;
          final readyAtLabel = formatReadyTime(
            estimatedReadyAtMillis(purchase.createdAtMillis, purchase.batchNumber),
          );

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (position > 0)
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            StatusChip(
                              text: '${Strings.queuePosition} $position',
                              tone: StatusTone.neutral,
                            ),
                            StatusChip(
                              text: Strings.batchLabel(purchase.batchNumber),
                              tone: StatusTone.neutral,
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      if (purchase.status == PurchaseStatus.waiting) ...[
                        Text(
                          Strings.statusWaiting,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          child: Column(
                            children: [
                              Text(
                                Strings.estimatedTime,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                readyAtLabel,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        AppCard(
                          child: Center(
                            child: Text(
                              Strings.statusNotified,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        text: Strings.returnToStores,
                        onPressed: () => Navigator.of(context).popUntil(
                          ModalRoute.withName(StoreListScreen.routeName),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
