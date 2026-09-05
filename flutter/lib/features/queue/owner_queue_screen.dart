import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md OwnerQueueScreen: 56dp rows (taller than the 48dp floor —
/// dense list needs the extra tap-accuracy margin), batch grouping via
/// section headers (not color-only banding), sticky Notify button that's
/// removed rather than disabled once nobody is left to notify.
class OwnerQueueScreen extends StatelessWidget {
  const OwnerQueueScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final dynamic storeId;

  @override
  Widget build(BuildContext context) {
    final date = todayDateString();
    return Scaffold(
      appBar: AppBar(title: Text(Strings.buyerQueueTitle)),
      body: StreamBuilder<List<PurchaseModel>>(
        stream: controller.watchQueueForStore(storeId, date),
        builder: (context, snapshot) {
          final store = controller.storeById(storeId);
          final queue = snapshot.data ?? [];
          final grouped = <int, List<PurchaseModel>>{};
          for (final p in queue) {
            grouped.putIfAbsent(p.batchNumber, () => []).add(p);
          }
          final batchNumbers = grouped.keys.toList()..sort();
          final nextBatch = nextBatchToNotify(queue);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        0,
                      ),
                      child: Text(
                        store?.name ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: queue.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  Strings.queueEmpty,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              children: [
                                for (final batch in batchNumbers) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      Strings.batchLabel(batch),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  for (final purchase in grouped[batch]!) ...[
                                    _BuyerRow(
                                      purchase: purchase,
                                      onToggleArrival: () =>
                                          controller.toggleArrival(purchase.id),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                ],
                              ],
                            ),
                    ),
                    if (nextBatch != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: PrimaryButton(
                          text: Strings.notifyNextBatch(nextBatch),
                          onPressed: () =>
                              controller.notifyNextBatch(storeId, date),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuyerRow extends StatelessWidget {
  const _BuyerRow({required this.purchase, required this.onToggleArrival});

  final PurchaseModel purchase;
  final VoidCallback onToggleArrival;

  @override
  Widget build(BuildContext context) {
    final tone = switch (purchase.status) {
      PurchaseStatus.notified => StatusTone.success,
      PurchaseStatus.collected => StatusTone.neutral,
      PurchaseStatus.waiting => StatusTone.warning,
    };
    final statusText = switch (purchase.status) {
      PurchaseStatus.notified => Strings.statusNotifiedShort,
      PurchaseStatus.collected => Strings.statusCollectedShort,
      PurchaseStatus.waiting => Strings.statusWaitingShort,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.userName ?? purchase.userPhone ?? purchase.userId.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatReadyTime(purchase.createdAtMillis),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StatusChip(text: statusText, tone: tone),
                ],
              ),
            ),
            if (purchase.status != PurchaseStatus.waiting)
              FilledButton(
                onPressed: onToggleArrival,
                child: Text(
                  purchase.status == PurchaseStatus.notified
                      ? Strings.markReceived
                      : Strings.undoReceived,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
