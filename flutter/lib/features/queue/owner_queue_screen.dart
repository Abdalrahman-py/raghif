import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/number_stepper.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import 'qr_scanner_screen.dart';
import '../../domain/models/store_model.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md OwnerQueueScreen: batch grouping via section headers (not
/// color-only banding), sticky Notify button that's removed rather than
/// disabled once nobody is left to notify.
///
/// Pickup additions: buyer rows carry national ID + phone, a live filter
/// finds a buyer by ID/phone suffix, and an AppBar scan action opens the QR
/// redemption scanner (#28).
class OwnerQueueScreen extends StatefulWidget {
  const OwnerQueueScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final dynamic storeId;

  @override
  State<OwnerQueueScreen> createState() => _OwnerQueueScreenState();
}

class _OwnerQueueScreenState extends State<OwnerQueueScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(PurchaseModel p) {
    final q = _query.trim();
    if (q.isEmpty) return true;
    final digitsOnly = q.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isNotEmpty) {
      final idDigits = (p.userNationalId ?? '').replaceAll(RegExp(r'\D'), '');
      final phoneDigits = (p.userPhone ?? '').replaceAll(RegExp(r'\D'), '');
      if (idDigits.endsWith(digitsOnly) || phoneDigits.endsWith(digitsOnly)) {
        return true;
      }
    }
    return (p.userName ?? '').contains(q);
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          controller: widget.controller,
          storeId: widget.storeId,
        ),
      ),
    );
  }

  /// Releasing a batch notifies real buyers, so the owner confirms first — and
  /// if people from earlier batches never picked up, the dialog says how many
  /// instead of silently calling another batch on top of them.
  Future<void> _confirmNotify(
    int batch,
    List<PurchaseModel> queue,
    String date,
  ) async {
    final outstanding = outstandingBefore(batch, queue);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Strings.notifyConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.notifyConfirmBody(batch)),
            if (outstanding > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                Strings.notifyOutstandingWarning(outstanding),
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(Strings.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(Strings.notifyConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.notifyNextBatch(widget.storeId, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = todayDateString();
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.buyerQueueTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: Strings.scanQrTitle,
            onPressed: _openScanner,
          ),
        ],
      ),
      body: StreamBuilder<List<PurchaseModel>>(
        stream: widget.controller.watchQueueForStore(widget.storeId, date),
        builder: (context, snapshot) {
          final store = widget.controller.storeById(widget.storeId);
          final queue = snapshot.data ?? [];
          final visible =
              searching ? queue.where(_matches).toList() : queue;
          final grouped = <int, List<PurchaseModel>>{};
          for (final p in visible) {
            grouped.putIfAbsent(p.batchNumber, () => []).add(p);
          }
          final batchNumbers = grouped.keys.toList()..sort();
          // Tallies for the batch headers ("picked / awaiting / not called"),
          // always from the FULL queue so a search can't change the numbers.
          final progress = {
            for (final p in batchProgressForQueue(queue)) p.batch: p,
          };
          // Notify decision always uses the FULL queue; the button is hidden
          // while searching so a lookup can't accidentally release a batch.
          final nextBatch = searching ? null : nextBatchToNotify(queue);

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
                    if (store != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: _BatchSizeControl(
                          controller: widget.controller,
                          storeId: widget.storeId,
                          store: store,
                          date: date,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        0,
                      ),
                      child: TextField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: Strings.searchBuyerHint,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                          : visible.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: Text(
                                      Strings.buyerSearchNoResults,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Strings.batchLabel(batch),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            if (progress[batch] != null) ...[
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                Strings.batchSummary(
                                                  progress[batch]!.picked,
                                                  progress[batch]!
                                                      .awaitingPickup,
                                                  progress[batch]!.waiting,
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      for (final purchase
                                          in grouped[batch]!) ...[
                                        _BuyerRow(
                                          purchase: purchase,
                                          onToggleArrival: () => widget
                                              .controller
                                              .toggleArrival(purchase.id),
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
                          onPressed: () => _confirmNotify(nextBatch, queue, date),
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

    final meta = [
      if (purchase.userNationalId != null &&
          purchase.userNationalId!.isNotEmpty)
        '${Strings.idShortLabel}: ${purchase.userNationalId}',
      if (purchase.userPhone != null && purchase.userPhone!.isNotEmpty)
        '${Strings.phoneShortLabel}: ${purchase.userPhone}',
    ].join('  ·  ');

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.userName ??
                      purchase.userPhone ??
                      purchase.userId.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Flexible(
                      child: StatusChip(text: statusText, tone: tone),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        formatReadyTime(purchase.createdAtMillis),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (purchase.status != PurchaseStatus.waiting)
            // Flexible so this button yields width instead of squeezing the
            // buyer info column (it overflowed notified/collected rows).
            Flexible(
              child: FilledButton(
                onPressed: onToggleArrival,
                child: Text(
                  purchase.status == PurchaseStatus.notified
                      ? Strings.markReceived
                      : Strings.undoReceived,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Batch size groups this queue into notify-able chunks; it lives here
/// (rather than the store dashboard) since it only makes sense next to
/// the queue it groups.
class _BatchSizeControl extends StatefulWidget {
  const _BatchSizeControl({
    required this.controller,
    required this.storeId,
    required this.store,
    required this.date,
  });

  final QueueController controller;
  final dynamic storeId;
  final StoreModel store;
  final String date;

  @override
  State<_BatchSizeControl> createState() => _BatchSizeControlState();
}

class _BatchSizeControlState extends State<_BatchSizeControl> {
  late int _batchSize = widget.store.batchSize;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  Strings.batchSizeLabel,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              NumberStepper(
                value: _batchSize,
                onChanged: (v) => setState(() => _batchSize = v),
                decrementLabel: Strings.decreaseValue,
                incrementLabel: Strings.increaseValue,
                min: 1,
              ),
            ],
          ),
          if (_batchSize != widget.store.batchSize) ...[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              text: Strings.saveBatchSize,
              onPressed: () => widget.controller.saveAllocation(
                widget.storeId,
                dailyBagLimit: widget.store.dailyBagLimit,
                batchSize: _batchSize,
                today: widget.date,
                openTime: widget.store.openTime,
                closeTime: widget.store.closeTime,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
