import '../models/customer_summary_model.dart';
import '../models/purchase_model.dart';
import '../models/scan_event_model.dart';
import '../models/store_day_summary.dart';
import '../models/store_list_entry.dart';
import '../models/store_model.dart';

/// Thrown by [QueueRepository.reserveBag] when the store has no bags left.
class StoreSoldOutException implements Exception {}

abstract class QueueRepository {
  Future<void> ensureSeeded();

  Stream<List<StoreModel>> watchStores();

  Future<List<StoreModel>> getStores();

  Future<StoreModel?> getStoreById(int storeId);

  /// The buyer's store list: every store plus that buyer's own context for it
  /// (pinned, today's order status, last purchase date), so the list can float
  /// the stores they actually use to the top and show extra detail on them.
  Stream<List<StoreListEntry>> watchStoreListForUser({
    required int userId,
    required String today,
  });

  /// Pins or un-pins [storeId] for [userId]. A pinned store always sorts to
  /// the top of that buyer's list.
  Future<void> setStorePinned({
    required int userId,
    required int storeId,
    required bool pinned,
  });

  /// Audit trail: records one QR scan attempt at pickup.
  Future<void> recordScan({
    required int storeId,
    required String outcome,
    int? purchaseId,
    String? scannedName,
    String? scannedNationalId,
  });

  /// Scan history for a store, newest first.
  Future<List<ScanEventModel>> getScansForStore(int storeId, {int limit = 100});

  Stream<List<PurchaseModel>> watchQueueForStore(int storeId, String date);

  Future<List<PurchaseModel>> getQueueForStore(int storeId, String date);

  Future<PurchaseModel?> getBlockingPurchase(
    int userId,
    String date, {
    String? userPhone,
  });

  Future<PurchaseModel?> getPurchaseById(int purchaseId);

  Stream<PurchaseModel?> watchPurchaseById(int purchaseId);

  Future<PurchaseModel> reserveBag({
    required int userId,
    required int storeId,
    required String date,
  });

  /// Returns true if a waiting batch existed and was notified, false if
  /// there was nothing left to notify.
  Future<bool> notifyNextBatch(int storeId, String date);

  Future<void> updatePurchaseStatus(int purchaseId, PurchaseStatus newStatus);

  Future<void> setStoreOpen(int storeId, bool isOpen);

  Future<void> saveStoreAllocation(
    int storeId, {
    required int dailyLimit,
    required int batchSize,
    required String date,
    String? openTime,
    String? closeTime,
  });

  Stream<List<CustomerSummaryModel>> watchCustomersForStore(int storeId);

  Future<List<CustomerSummaryModel>> getCustomersForStore(int storeId);

  /// Per-day sales totals for a store, newest day first — the owner's history
  /// browser. [notCollected] is the end-of-day leftover (paid, never picked up).
  Future<List<StoreDaySummary>> getDailySummaries(int storeId, {int limit = 30});
}
