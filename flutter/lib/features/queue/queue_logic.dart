import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_day_summary.dart';
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

/// True when the owner must set today's allocation first.
///
/// Only asks the server's own counter now. `allocationDate` used to be
/// compared against today, but it was never persisted — it defaulted to ''
/// on every store, so this was permanently true. `bags_remaining` is reset
/// by `save_store_allocation`, which makes it the real signal.
bool needsAllocation(StoreModel store, String today) =>
    store.bagsRemaining <= 0;

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
    .where((p) => p.batchNumber < batch && p.status == PurchaseStatus.notified)
    .length;

/// A nudge for the owner: the next batch is worth calling now.
class NextBatchSuggestion {
  const NextBatchSuggestion({required this.batch, required this.count});

  final int batch;

  /// Buyers in that batch who are still waiting to be called.
  final int count;
}

/// When to suggest calling the next batch: someone is waiting, and the people
/// already called are mostly gone (at most a quarter of the batch size, and
/// never more than a handful, still on their way). It only suggests; the owner
/// still opens the queue and confirms, because calling a batch notifies buyers.
NextBatchSuggestion? suggestNextBatch(
  List<PurchaseModel> queue, {
  required int batchSize,
}) {
  final next = nextBatchToNotify(queue);
  if (next == null) return null;
  final stillOut = queue
      .where((p) => p.status == PurchaseStatus.notified)
      .length;
  final allowed = (batchSize ~/ 4).clamp(0, 5);
  if (stillOut > allowed) return null;
  final count = queue
      .where((p) => p.batchNumber == next && p.status == PurchaseStatus.waiting)
      .length;
  return NextBatchSuggestion(batch: next, count: count);
}

/// The last week at a glance, from the per-day summaries.
class WeeklyStats {
  const WeeklyStats({
    required this.days,
    required this.sold,
    required this.collected,
    required this.cash,
    this.bestDate,
    this.bestSold = 0,
  });

  /// Days that had any sales.
  final int days;
  final int sold;
  final int collected;
  final double cash;
  final String? bestDate;
  final int bestSold;

  /// Share of sold bags that were handed over, 0..100.
  int get collectedPercent => sold == 0 ? 0 : (collected * 100 / sold).round();
  int get dailyAverage => days == 0 ? 0 : (sold / days).round();
}

/// Totals over the newest [windowDays] days in [summaries] (any order).
WeeklyStats weeklyStats(List<StoreDaySummary> summaries, {int windowDays = 7}) {
  final recent = [...summaries]..sort((a, b) => b.date.compareTo(a.date));
  final week = recent.take(windowDays).where((d) => d.sold > 0).toList();
  var sold = 0, collected = 0;
  var cash = 0.0;
  StoreDaySummary? best;
  for (final d in week) {
    sold += d.sold;
    collected += d.collected;
    cash += d.cashTotal;
    if (best == null || d.sold > best.sold) best = d;
  }
  return WeeklyStats(
    days: week.length,
    sold: sold,
    collected: collected,
    cash: cash,
    bestDate: best?.date,
    bestSold: best?.sold ?? 0,
  );
}
