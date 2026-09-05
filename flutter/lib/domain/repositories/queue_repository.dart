import '../models/customer_summary_model.dart';
import '../models/purchase_model.dart';
import '../models/store_model.dart';

/// Thrown by [QueueRepository.reserveBag] when the store has no bags left.
class StoreSoldOutException implements Exception {}

abstract class QueueRepository {
  Future<void> ensureSeeded();

  Stream<List<StoreModel>> watchStores();

  Future<List<StoreModel>> getStores();

  Future<StoreModel?> getStoreById(int storeId);

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
}
