import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_model.dart';

/// Pure queue logic, kept separate from widgets so it's unit-testable without
/// pumping a widget tree. Mirrors app/.../data/QueueLogic.kt's rules.
const batchIntervalMinutes = 10;

String todayDateString([DateTime? now]) {
  final d = now ?? DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Admin arrival check: notified (pending) <-> collected (arrived). Waiting
/// rows have no action.
PurchaseStatus toggleArrivalStatus(PurchaseStatus status) => switch (status) {
  PurchaseStatus.notified => PurchaseStatus.collected,
  PurchaseStatus.collected => PurchaseStatus.notified,
  PurchaseStatus.waiting => PurchaseStatus.waiting,
};

/// Smallest batch number that still has waiting customers — the one the
/// owner should notify next. Null when nobody is waiting.
int? nextBatchToNotify(List<PurchaseModel> queue) {
  final waiting = queue.where((p) => p.status == PurchaseStatus.waiting);
  if (waiting.isEmpty) return null;
  return waiting.map((p) => p.batchNumber).reduce((a, b) => a < b ? a : b);
}

/// Estimated ready time (epoch millis): createdAt + batch x interval.
int estimatedReadyAtMillis(int createdAtMillis, int batchNumber) =>
    createdAtMillis + batchNumber * batchIntervalMinutes * 60000;

/// Formats epoch millis as HH:mm in local time.
String formatReadyTime(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// True when the owner must set today's allocation first: it's a new day, or
/// the current bundles are gone.
bool needsAllocation(StoreModel store, String today) =>
    store.allocationDate != today || store.bagsRemaining <= 0;

/// In-app low-stock warning threshold. Actual SMS/push delivery is out of
/// scope for this prototype (decision D) — the app only surfaces the state.
const int lowStockThreshold = 20;

/// True when the store is running low and the owner should be warned in-app.
bool isLowStock(StoreModel store) => store.bagsRemaining <= lowStockThreshold;

/// Today's paid-but-not-collected buyers — the dashboard's "still waiting"
/// count, so the owner doesn't have to open the queue to know.
int pendingPickupCount(List<PurchaseModel> queue) =>
    queue.where((p) => p.status != PurchaseStatus.collected).length;

/// Tallies for one batch header in the owner's queue.
class BatchProgress {
  const BatchProgress({
    required this.batch,
    required this.total,
    required this.picked,
    required this.awaitingPickup,
    required this.waiting,
  });

  final int batch;
  final int total;

  /// Handed over.
  final int picked;

  /// Called, but the buyer hasn't shown up yet.
  final int awaitingPickup;

  /// Not called yet.
  final int waiting;

  bool get allPicked => picked == total;
}

/// Per-batch tallies for [queue], ordered by batch number — "called N / picked
/// M / still waiting K" next to each batch header.
List<BatchProgress> batchProgressForQueue(List<PurchaseModel> queue) {
  final byBatch = <int, List<PurchaseModel>>{};
  for (final purchase in queue) {
    byBatch.putIfAbsent(purchase.batchNumber, () => []).add(purchase);
  }
  final batches = byBatch.keys.toList()..sort();
  return [
    for (final batch in batches)
      BatchProgress(
        batch: batch,
        total: byBatch[batch]!.length,
        picked: byBatch[batch]!
            .where((p) => p.status == PurchaseStatus.collected)
            .length,
        awaitingPickup: byBatch[batch]!
            .where((p) => p.status == PurchaseStatus.notified)
            .length,
        waiting: byBatch[batch]!
            .where((p) => p.status == PurchaseStatus.waiting)
            .length,
      ),
  ];
}

/// Buyers in *earlier* batches who were called but never picked up. Releasing
/// a new batch on top of them is what the owner gets warned about.
int outstandingBefore(int batch, List<PurchaseModel> queue) => queue
    .where(
      (p) =>
          p.batchNumber < batch && p.status == PurchaseStatus.notified,
    )
    .length;
