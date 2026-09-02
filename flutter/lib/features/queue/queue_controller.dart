import 'package:flutter/foundation.dart';
import 'models.dart';
import 'queue_logic.dart';

/// Owner hardcoded by phone (spec.md "Owner Identification") — this prototype
/// has one pilot store, matching app/.../data/AppDatabase.kt's DEMO_STORE_ID.
const demoOwnerStoreId = 'store_1';

/// In-memory mock data store standing in for the SQLDelight database until
/// issue #7 wires real queries. Holds every store/purchase for the app's
/// lifetime and notifies listeners on writes, same shape a repository would
/// expose over a stream.
class QueueController extends ChangeNotifier {
  QueueController()
    : stores = [
        Store(
          id: 'store_1',
          name: 'مخبز الرمال',
          isOpen: true,
          dailyBagLimit: 300,
          bagsRemaining: 45,
          allocationDate: todayDateString(),
        ),
        Store(
          id: 'store_2',
          name: 'مخبز الشاطئ',
          isOpen: true,
          dailyBagLimit: 300,
          bagsRemaining: 120,
          allocationDate: todayDateString(),
        ),
        Store(
          id: 'store_3',
          name: 'مخبز النصيرات',
          isOpen: false,
          dailyBagLimit: 300,
          bagsRemaining: 0,
          allocationDate: todayDateString(),
        ),
      ],
      purchases = [];

  final List<Store> stores;
  final List<Purchase> purchases;
  int _nextPurchaseSeq = 1;

  Store? storeById(String id) {
    for (final s in stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  Purchase? purchaseById(String id) {
    for (final p in purchases) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Chronological (purchase-order) queue for one store/day.
  List<Purchase> queueForStore(String storeId, String date) {
    final matches = purchases
        .where((p) => p.storeId == storeId && p.purchaseDate == date)
        .toList();
    matches.sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));
    return matches;
  }

  /// spec.md: one bag per national ID per store per day (schema's UNIQUE
  /// constraint is on user_id + store_id + purchase_date). The escape hatch:
  /// once the owner tops up allocation (bumping batchRound), an existing
  /// purchase from an older round no longer blocks a new one.
  Purchase? blockingPurchaseFor(String userId, String storeId, String date) {
    Purchase? existing;
    for (final p in purchases) {
      if (p.userId == userId && p.storeId == storeId && p.purchaseDate == date) {
        existing = p;
        break;
      }
    }
    if (existing == null) return null;
    final currentRound = storeById(storeId)?.batchRound ?? 1;
    if (currentRound > existing.batchRoundAtPurchase) return null;
    return existing;
  }

  /// Records a purchase for [userId] at [storeId]. Caller must have already
  /// checked [blockingPurchaseFor] and that the store is available.
  Purchase buy({
    required String userId,
    required String storeId,
    required String date,
  }) {
    final store = storeById(storeId)!;
    final position = queueForStore(storeId, date).length + 1;
    final batchNumber = ((position - 1) ~/ store.batchSize) + 1;
    final purchase = Purchase(
      id: 'purchase_${_nextPurchaseSeq++}',
      storeId: storeId,
      userId: userId,
      purchaseDate: date,
      batchNumber: batchNumber,
      status: PurchaseStatus.waiting,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      batchRoundAtPurchase: store.batchRound,
    );
    purchases.add(purchase);
    store.bagsRemaining -= 1;
    notifyListeners();
    return purchase;
  }

  /// Owner action: notify every waiting buyer in the next un-notified batch.
  void notifyNextBatch(String storeId, String date) {
    final next = nextBatchToNotify(queueForStore(storeId, date));
    if (next == null) return;
    for (var i = 0; i < purchases.length; i++) {
      final p = purchases[i];
      if (p.storeId == storeId &&
          p.batchNumber == next &&
          p.status == PurchaseStatus.waiting) {
        purchases[i] = p.copyWith(status: PurchaseStatus.notified);
      }
    }
    notifyListeners();
  }

  /// Owner action: notified <-> collected check-in toggle.
  void toggleArrival(String purchaseId) {
    final i = purchases.indexWhere((p) => p.id == purchaseId);
    if (i == -1) return;
    purchases[i] = purchases[i].copyWith(
      status: toggleArrivalStatus(purchases[i].status),
    );
    notifyListeners();
  }

  void setPurchaseWindowOpen(String storeId, bool open) {
    final store = storeById(storeId);
    if (store == null) return;
    store.isOpen = open;
    notifyListeners();
  }

  /// Owner action: top up today's allocation. Bumps batchRound so buyers who
  /// already collected a bag from this store today can buy one more.
  void saveAllocation(
    String storeId, {
    required int dailyBagLimit,
    required int batchSize,
    required String today,
  }) {
    final store = storeById(storeId);
    if (store == null) return;
    store.dailyBagLimit = dailyBagLimit;
    store.bagsRemaining = dailyBagLimit;
    store.batchSize = batchSize;
    store.batchRound += 1;
    store.allocationDate = today;
    notifyListeners();
  }
}
