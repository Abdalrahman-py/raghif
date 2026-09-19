import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/app_database.dart';
import '../../domain/models/customer_summary_model.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/scan_event_model.dart';
import '../../domain/models/store_day_summary.dart';
import '../../domain/models/store_list_entry.dart';
import '../../domain/models/store_model.dart';
import '../../domain/repositories/queue_repository.dart';
import '../sync/queue_sync_service.dart';

/// Wraps a drift-backed [QueueRepository] so it stays the read model and
/// offline cache for every screen (no `Stream<...>` contract changes — see
/// docs/supabase-migration-plan.md Phase 3), while the three writes with
/// real race conditions (sold-out, one-bag-per-day, allocation math) are
/// arbitrated by Postgres RPCs first whenever a session is live and the
/// store is linked. `updatePurchaseStatus`/`setStoreOpen` and everything
/// else stay purely local — no reported race on those in the audit.
///
/// ponytail: no pending-actions replay queue — reserving/notifying while
/// offline (or before a store is linked) just falls back to local-only
/// behavior, same as pre-Phase-3. A real replay-on-reconnect queue is a
/// follow-up if the pilot needs to trust concurrent offline writes across
/// devices; single-store/single-owner-in-the-room doesn't yet.
class SyncedQueueRepository implements QueueRepository {
  SyncedQueueRepository({
    required QueueRepository local,
    required SupabaseClient client,
    required AppDatabase db,
    required QueueSyncService sync,
  })  : _local = local,
        _client = client,
        _db = db,
        _sync = sync;

  final QueueRepository _local;
  final SupabaseClient _client;
  final AppDatabase _db;
  final QueueSyncService _sync;

  bool get _hasSession => _client.auth.currentSession != null;

  Future<String?> _remoteStoreId(int storeId) async {
    final store = await (_db.select(_db.stores)
          ..where((s) => s.id.equals(storeId)))
        .getSingleOrNull();
    return store?.remoteId;
  }

  @override
  Future<PurchaseModel> reserveBag({
    required int userId,
    required int storeId,
    required String date,
  }) async {
    if (_hasSession) {
      final remoteStoreId = await _remoteStoreId(storeId);
      if (remoteStoreId != null) {
        try {
          await _client.rpc('reserve_bag', params: {
            'p_store_id': remoteStoreId,
            'p_purchase_date': date,
          });
        } on PostgrestException catch (e) {
          if (e.message.toLowerCase().contains('sold out') ||
              e.message.toLowerCase().contains('closed')) {
            throw StoreSoldOutException();
          }
          rethrow;
        }
      }
    }
    return _local.reserveBag(userId: userId, storeId: storeId, date: date);
  }

  @override
  Future<bool> notifyNextBatch(int storeId, String date) async {
    if (_hasSession) {
      final remoteStoreId = await _remoteStoreId(storeId);
      if (remoteStoreId != null) {
        try {
          await _client.rpc('notify_next_batch', params: {
            'p_store_id': remoteStoreId,
            'p_purchase_date': date,
          });
        } on PostgrestException catch (_) {
          // Nothing waiting server-side either — local performs the same
          // check and returns false itself below.
        }
      }
    }
    return _local.notifyNextBatch(storeId, date);
  }

  @override
  Future<void> saveStoreAllocation(
    int storeId, {
    required int dailyLimit,
    required int batchSize,
    required String date,
    String? openTime,
    String? closeTime,
  }) async {
    if (_hasSession) {
      final remoteStoreId = await _sync.ensureStoreLinked(storeId);
      if (remoteStoreId != null) {
        final store = await (_db.select(_db.stores)
              ..where((s) => s.id.equals(storeId)))
            .getSingleOrNull();
        await _client.rpc('save_store_allocation', params: {
          'p_store_id': remoteStoreId,
          'p_daily_bag_limit': dailyLimit,
          'p_is_open': store?.isOpen ?? true,
          'p_batch_size': batchSize,
          'p_purchase_date': date,
        });
      }
    }
    return _local.saveStoreAllocation(
      storeId,
      dailyLimit: dailyLimit,
      batchSize: batchSize,
      date: date,
      openTime: openTime,
      closeTime: closeTime,
    );
  }

  // --- Pure passthroughs: drift stays the read model, unchanged. ---

  @override
  Future<void> ensureSeeded() => _local.ensureSeeded();

  @override
  Stream<List<StoreModel>> watchStores() {
    unawaited(_sync.pullStoresDown());
    return _local.watchStores();
  }

  @override
  Future<List<StoreModel>> getStores() async {
    await _sync.pullStoresDown();
    return _local.getStores();
  }

  @override
  Future<StoreModel?> getStoreById(int storeId) => _local.getStoreById(storeId);

  @override
  Stream<List<StoreListEntry>> watchStoreListForUser({
    required int userId,
    required String today,
  }) {
    unawaited(_sync.pullStoresDown());
    return _local.watchStoreListForUser(userId: userId, today: today);
  }

  @override
  Future<void> setStorePinned({
    required int userId,
    required int storeId,
    required bool pinned,
  }) =>
      _local.setStorePinned(userId: userId, storeId: storeId, pinned: pinned);

  @override
  Future<void> recordScan({
    required int storeId,
    required String outcome,
    int? purchaseId,
    String? scannedName,
    String? scannedNationalId,
  }) =>
      _local.recordScan(
        storeId: storeId,
        outcome: outcome,
        purchaseId: purchaseId,
        scannedName: scannedName,
        scannedNationalId: scannedNationalId,
      );

  @override
  Future<List<ScanEventModel>> getScansForStore(int storeId, {int limit = 100}) =>
      _local.getScansForStore(storeId, limit: limit);

  @override
  Stream<List<PurchaseModel>> watchQueueForStore(int storeId, String date) =>
      _local.watchQueueForStore(storeId, date);

  @override
  Future<List<PurchaseModel>> getQueueForStore(int storeId, String date) =>
      _local.getQueueForStore(storeId, date);

  @override
  Future<PurchaseModel?> getBlockingPurchase(
    int userId,
    String date, {
    String? userPhone,
  }) =>
      _local.getBlockingPurchase(userId, date, userPhone: userPhone);

  @override
  Future<PurchaseModel?> getPurchaseById(int purchaseId) =>
      _local.getPurchaseById(purchaseId);

  @override
  Stream<PurchaseModel?> watchPurchaseById(int purchaseId) =>
      _local.watchPurchaseById(purchaseId);

  @override
  Future<void> updatePurchaseStatus(int purchaseId, PurchaseStatus newStatus) =>
      _local.updatePurchaseStatus(purchaseId, newStatus);

  @override
  Future<void> setStoreOpen(int storeId, bool isOpen) =>
      _local.setStoreOpen(storeId, isOpen);

  @override
  Stream<List<CustomerSummaryModel>> watchCustomersForStore(int storeId) =>
      _local.watchCustomersForStore(storeId);

  @override
  Future<List<CustomerSummaryModel>> getCustomersForStore(int storeId) =>
      _local.getCustomersForStore(storeId);

  @override
  Future<List<StoreDaySummary>> getDailySummaries(int storeId, {int limit = 30}) =>
      _local.getDailySummaries(storeId, limit: limit);
}
