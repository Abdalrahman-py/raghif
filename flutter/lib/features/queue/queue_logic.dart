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
