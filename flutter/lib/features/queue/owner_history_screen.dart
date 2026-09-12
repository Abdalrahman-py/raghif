import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_day_summary.dart';
import 'queue_controller.dart';

/// Owner history (walkthrough P0 #4): a day browser over the same queue the
/// owner already works with. Days come from one grouped query, so the list
/// shows "yesterday: 120 sold, 3 never picked up" without loading every row.
class OwnerHistoryScreen extends StatefulWidget {
  const OwnerHistoryScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final dynamic storeId;

  @override
  State<OwnerHistoryScreen> createState() => _OwnerHistoryScreenState();
}

class _OwnerHistoryScreenState extends State<OwnerHistoryScreen> {
  late final Future<List<StoreDaySummary>> _days =
      widget.controller.dailySummariesForStore(widget.storeId);

  @override
  Widget build(BuildContext context) {
    final store = widget.controller.storeById(widget.storeId);
    return Scaffold(
      appBar: AppBar(title: Text(Strings.historyTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<List<StoreDaySummary>>(
              future: _days,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final days = snapshot.data ?? const <StoreDaySummary>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (store != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          0,
                        ),
                        child: Text(
                          store.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: days.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  Strings.historyEmpty,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              itemCount: days.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) => _DayCard(
                                summary: days[index],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OwnerHistoryDayScreen(
                                      controller: widget.controller,
                                      storeId: widget.storeId,
                                      date: days[index].date,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.summary, required this.onTap});

  final StoreDaySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.large,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(summary.date, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                StatusChip(
                  text: Strings.historySold(summary.sold),
                  tone: StatusTone.neutral,
                ),
                StatusChip(
                  text: Strings.historyCollected(summary.collected),
                  tone: StatusTone.success,
                ),
                if (!summary.everythingCollected)
                  StatusChip(
                    text: Strings.historyNotCollected(summary.notCollected),
                    tone: StatusTone.warning,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One past day: the buyers and how each ended up, with the counts on top.
class OwnerHistoryDayScreen extends StatefulWidget {
  const OwnerHistoryDayScreen({
    super.key,
    required this.controller,
    required this.storeId,
    required this.date,
  });

  final QueueController controller;
  final dynamic storeId;
  final String date;

  @override
  State<OwnerHistoryDayScreen> createState() => _OwnerHistoryDayScreenState();
}

class _OwnerHistoryDayScreenState extends State<OwnerHistoryDayScreen> {
  late final Future<List<PurchaseModel>> _queue =
      widget.controller.queueForStore(widget.storeId, widget.date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Strings.historyDayTitle(widget.date))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<List<PurchaseModel>>(
              future: _queue,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final queue = snapshot.data ?? const <PurchaseModel>[];
                if (queue.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        Strings.historyEmpty,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                final collected = queue
                    .where((p) => p.status == PurchaseStatus.collected)
                    .length;
                final outstanding = queue.length - collected;

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: queue.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            StatusChip(
                              text: Strings.historySold(queue.length),
                              tone: StatusTone.neutral,
                            ),
                            StatusChip(
                              text: Strings.historyCollected(collected),
                              tone: StatusTone.success,
                            ),
                            if (outstanding > 0)
                              StatusChip(
                                text: Strings.historyNotCollected(outstanding),
                                tone: StatusTone.warning,
                              ),
                          ],
                        ),
                      );
                    }
                    return _BuyerHistoryRow(purchase: queue[index - 1]);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyerHistoryRow extends StatelessWidget {
  const _BuyerHistoryRow({required this.purchase});

  final PurchaseModel purchase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = switch (purchase.status) {
      PurchaseStatus.collected => (
        Strings.statusCollectedShort,
        StatusTone.success,
      ),
      PurchaseStatus.notified => (
        Strings.statusNotifiedShort,
        StatusTone.warning,
      ),
      PurchaseStatus.waiting => (
        Strings.statusWaitingShort,
        StatusTone.neutral,
      ),
    };
    final meta = [
      if (purchase.userNationalId != null && purchase.userNationalId!.isNotEmpty)
        purchase.userNationalId!,
      if (purchase.userPhone != null && purchase.userPhone!.isNotEmpty)
        purchase.userPhone!,
    ].join('  ·  ');

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.userName ?? purchase.userPhone ?? '',
                  style: textTheme.bodyLarge,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    meta,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(text: label, tone: tone),
        ],
      ),
    );
  }
}
