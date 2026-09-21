import 'dart:async';

import 'package:drift/drift.dart';
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

/// The only [QueueRepository]. Postgres decides, drift remembers.
///
/// Reads are served from the cache so the app stays usable on a bad
/// connection, and every read kicks off a background refresh. Writes go
/// straight to an RPC and then re-pull: none of them touch the cache
/// directly, because a locally-applied write is a second opinion about
/// state the server owns. That is what produced the batch-number
/// disagreement the old split-brain design shipped with.
class SupabaseQueueRepository implements QueueRepository {
  SupabaseQueueRepository({
    required SupabaseClient client,
    required AppDatabase db,
    required QueueSyncService sync,
  })  : _client = client,
        _db = db,
        _sync = sync;

  final SupabaseClient _client;
  final AppDatabase _db;
  final QueueSyncService _sync;

  // ------------------------------------------------------------- writes --

  /// Runs an RPC, translating the two failures the UI has to tell apart:
  /// the store being out of bags, and the backend being unreachable.
  Future<T> _rpc<T>(String name, Map<String, dynamic> params) async {
    if (_client.auth.currentSession == null) {
      throw const BackendUnavailableException('no session');
    }
    try {
      return await _client.rpc(name, params: params) as T;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('sold out') || message.contains('closed')) {
        throw StoreSoldOutException();
      }
      rethrow;
    } on StoreSoldOutException {
      rethrow;
    } catch (e) {
      // Socket errors, DNS failures, timeouts: the write did not happen.
      throw BackendUnavailableException(e);
    }
  }

  @override
  Future<PurchaseModel> reserveBag({
    required String storeId,
    required String date,
  }) async {
    final row = await _rpc<Map<String, dynamic>>('reserve_bag', {
      'p_store_id': storeId,
      'p_purchase_date': date,
    });
    await _sync.refreshAll();
    final saved = await getPurchaseById(row['id'] as String);
    if (saved != null) return saved;
    // Cache didn't catch up (RLS timing, flaky pull) — the server's own row
    // is still the truth, so hand that back rather than failing a write
    // that succeeded.
    return _purchaseFromRow(row);
  }

  @override
  Future<bool> notifyNextBatch(String storeId, String date) async {
    try {
      await _rpc<dynamic>('notify_next_batch', {
        'p_store_id': storeId,
        'p_purchase_date': date,
      });
    } on PostgrestException catch (e) {
      // "no waiting batch to notify" is an expected outcome, not a failure.
      if (e.message.toLowerCase().contains('no waiting batch')) return false;
      rethrow;
    }
    await _sync.refreshAll();
    return true;
  }

  @override
  Future<void> collectPurchase(String purchaseId) async {
    await _rpc<dynamic>('collect_purchase', {'p_purchase_id': purchaseId});
    await _sync.pullPurchases();
  }

  @override
  Future<void> setStoreOpen(String storeId, bool isOpen) async {
    await _rpc<dynamic>('set_store_open', {
      'p_store_id': storeId,
      'p_is_open': isOpen,
    });
    await _sync.pullStores();
  }

  @override
  Future<void> saveStoreAllocation(
    String storeId, {
    required int dailyLimit,
    required int batchSize,
    required String date,
    String? openTime,
    String? closeTime,
  }) async {
    final store = await getStoreById(storeId);
    await _rpc<dynamic>('save_store_allocation', {
      'p_store_id': storeId,
      'p_daily_bag_limit': dailyLimit,
      'p_is_open': store?.isOpen ?? true,
      'p_batch_size': batchSize,
      'p_purchase_date': date,
      'p_open_time': _time(openTime),
      'p_close_time': _time(closeTime),
    });
    await _sync.pullStores();
  }

  @override
  Future<void> recordScan({
    required String storeId,
    required String outcome,
    String? purchaseId,
    String? scannedName,
    String? scannedNationalId,
  }) async {
    await _rpc<dynamic>('record_scan', {
      'p_store_id': storeId,
      'p_outcome': outcome,
      'p_purchase_id': purchaseId,
      'p_scanned_name': scannedName,
      'p_scanned_national_id': scannedNationalId,
    });
    await _sync.pullScanEvents();
  }

  @override
  Future<void> setStorePinned({
    required String userId,
    required String storeId,
    required bool pinned,
  }) async {
    await _rpc<dynamic>('set_store_pinned', {
      'p_store_id': storeId,
      'p_pinned': pinned,
    });
    await _sync.pullPins();
  }

  // -------------------------------------------------------------- reads --

  @override
  Future<void> refresh() => _sync.refreshAll();

  @override
  Stream<List<StoreModel>> watchStores() {
    unawaited(_sync.pullStores());
    return _db.select(_db.stores).watch().map(
          (rows) => rows.map(_storeFrom).toList(),
        );
  }

  @override
  Future<List<StoreModel>> getStores() async {
    await _sync.pullStores();
    final rows = await _db.select(_db.stores).get();
    return rows.map(_storeFrom).toList();
  }

  @override
  Future<StoreModel?> getStoreById(String storeId) async {
    final row = await (_db.select(_db.stores)
          ..where((s) => s.id.equals(storeId)))
        .getSingleOrNull();
    return row == null ? null : _storeFrom(row);
  }

  @override
  Future<StoreModel?> getStoreForOwner(String ownerId) async {
    await _sync.pullStores();
    final row = await (_db.select(_db.stores)
          ..where((s) => s.ownerId.equals(ownerId))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _storeFrom(row);
  }

  @override
  Stream<List<StoreListEntry>> watchStoreListForUser({
    required String userId,
    required String today,
  }) {
    unawaited(_sync.refreshAll());
    final query = _db.select(_db.stores).join([
      leftOuterJoin(
        _db.storePins,
        _db.storePins.storeId.equalsExp(_db.stores.id) &
            _db.storePins.userId.equals(userId),
      ),
    ]);

    return query.watch().asyncMap((rows) async {
      final purchases = await (_db.select(_db.purchases)
            ..where((p) => p.userId.equals(userId)))
          .get();

      return rows.map((row) {
        final store = row.readTable(_db.stores);
        final mine = purchases.where((p) => p.storeId == store.id).toList()
          ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        final todays = mine.where((p) => p.purchaseDate == today).firstOrNull;
        return StoreListEntry(
          store: _storeFrom(store),
          pinned: row.readTableOrNull(_db.storePins) != null,
          todayStatus: todays?.status,
          todayPurchaseId: todays?.id,
          lastPurchaseDate: mine.firstOrNull?.purchaseDate,
        );
      }).toList();
    });
  }

  @override
  Stream<List<PurchaseModel>> watchQueueForStore(String storeId, String date) {
    unawaited(_sync.pullPurchases());
    return _queueQuery(storeId, date).watch().map(_purchasesFromJoin);
  }

  @override
  Future<List<PurchaseModel>> getQueueForStore(
    String storeId,
    String date,
  ) async {
    await _sync.pullPurchases();
    return _purchasesFromJoin(await _queueQuery(storeId, date).get());
  }

  JoinedSelectStatement _queueQuery(String storeId, String date) {
    return (_db.select(_db.purchases)
          ..where((p) => p.storeId.equals(storeId) & p.purchaseDate.equals(date))
          ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
        .join([
      leftOuterJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
      leftOuterJoin(_db.stores, _db.stores.id.equalsExp(_db.purchases.storeId)),
    ]);
  }

  @override
  Future<PurchaseModel?> getBlockingPurchase(String userId, String date) async {
    final row = await (_db.select(_db.purchases)
          ..where((p) => p.userId.equals(userId) & p.purchaseDate.equals(date)))
        .getSingleOrNull();
    return row == null ? null : _purchaseFrom(row);
  }

  @override
  Future<PurchaseModel?> getPurchaseById(String purchaseId) async {
    final rows = await (_db.select(_db.purchases)
          ..where((p) => p.id.equals(purchaseId)))
        .join([
      leftOuterJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
      leftOuterJoin(_db.stores, _db.stores.id.equalsExp(_db.purchases.storeId)),
    ]).get();
    final list = _purchasesFromJoin(rows);
    return list.isEmpty ? null : list.first;
  }

  @override
  Stream<PurchaseModel?> watchPurchaseById(String purchaseId) {
    return (_db.select(_db.purchases)..where((p) => p.id.equals(purchaseId)))
        .join([
          leftOuterJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
          leftOuterJoin(
            _db.stores,
            _db.stores.id.equalsExp(_db.purchases.storeId),
          ),
        ])
        .watch()
        .map((rows) {
          final list = _purchasesFromJoin(rows);
          return list.isEmpty ? null : list.first;
        });
  }

  @override
  Future<List<ScanEventModel>> getScansForStore(
    String storeId, {
    int limit = 100,
  }) async {
    await _sync.pullScanEvents();
    final rows = await (_db.select(_db.scanEvents)
          ..where((s) => s.storeId.equals(storeId))
          ..orderBy([(s) => OrderingTerm.desc(s.scannedAt)])
          ..limit(limit))
        .get();
    return rows
        .map(
          (r) => ScanEventModel(
            id: r.id,
            storeId: r.storeId,
            purchaseId: r.purchaseId,
            outcome: r.outcome,
            scannedName: r.scannedName,
            scannedNationalId: r.scannedNationalId,
            scannedAtMillis: r.scannedAt,
          ),
        )
        .toList();
  }

  // Computed by Postgres (`store_customers` / `store_daily_summaries`) so the
  // owner's numbers come from the same rows the queue does, not from a
  // partial mirror.

  @override
  Stream<List<CustomerSummaryModel>> watchCustomersForStore(String storeId) {
    return Stream.fromFuture(getCustomersForStore(storeId));
  }

  @override
  Future<List<CustomerSummaryModel>> getCustomersForStore(
    String storeId,
  ) async {
    final rows = await _rpc<List<dynamic>>('store_customers', {
      'p_store_id': storeId,
    });
    return rows.cast<Map<String, dynamic>>().map((r) {
      return CustomerSummaryModel(
        userId: r['user_id'] as String,
        name: (r['name'] as String?) ?? '',
        phone: (r['phone'] as String?) ?? '',
        totalPurchases: (r['total_purchases'] as num?)?.toInt() ?? 0,
        lastPurchaseDate: (r['last_purchase_date'] as String?) ?? '',
      );
    }).toList();
  }

  @override
  Future<List<StoreDaySummary>> getDailySummaries(
    String storeId, {
    int limit = 30,
  }) async {
    final rows = await _rpc<List<dynamic>>('store_daily_summaries', {
      'p_store_id': storeId,
      'p_limit': limit,
    });
    return rows.cast<Map<String, dynamic>>().map((r) {
      return StoreDaySummary(
        date: (r['purchase_date'] as String?) ?? '',
        sold: (r['sold'] as num?)?.toInt() ?? 0,
        collected: (r['collected'] as num?)?.toInt() ?? 0,
        notCollected: (r['not_collected'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  // ------------------------------------------------------------ mapping --

  StoreModel _storeFrom(Store row) => StoreModel(
        id: row.id,
        name: row.name,
        isOpen: row.isOpen,
        dailyBagLimit: row.dailyBagLimit,
        bagsRemaining: row.bagsRemaining,
        ownerId: row.ownerId,
        batchSize: row.batchSize,
        openTime: row.openTime,
        closeTime: row.closeTime,
        area: row.area,
      );

  PurchaseModel _purchaseFrom(Purchase row) => PurchaseModel(
        id: row.id,
        storeId: row.storeId,
        userId: row.userId,
        purchaseDate: row.purchaseDate,
        batchNumber: row.batchNumber,
        status: row.status,
        createdAtMillis: row.createdAt,
      );

  List<PurchaseModel> _purchasesFromJoin(List<TypedResult> rows) {
    return rows.map((row) {
      final purchase = row.readTable(_db.purchases);
      final user = row.readTableOrNull(_db.users);
      final store = row.readTableOrNull(_db.stores);
      return PurchaseModel(
        id: purchase.id,
        storeId: purchase.storeId,
        userId: purchase.userId,
        purchaseDate: purchase.purchaseDate,
        batchNumber: purchase.batchNumber,
        status: purchase.status,
        createdAtMillis: purchase.createdAt,
        userName: user?.name,
        userPhone: user?.phone,
        userNationalId: user?.nationalId,
        storeName: store?.name,
      );
    }).toList();
  }

  PurchaseModel _purchaseFromRow(Map<String, dynamic> row) => PurchaseModel(
        id: row['id'] as String,
        storeId: row['store_id'] as String,
        userId: row['user_id'] as String,
        purchaseDate: row['purchase_date'] as String,
        batchNumber: (row['batch_number'] as int?) ?? 1,
        status: switch (row['status'] as String?) {
          'notified' => PurchaseStatus.notified,
          'collected' => PurchaseStatus.collected,
          _ => PurchaseStatus.waiting,
        },
        createdAtMillis:
            DateTime.tryParse((row['created_at'] as String?) ?? '')
                    ?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
      );

  /// Postgres `time` wants "HH:mm:ss"; the UI carries "HH:mm".
  static String? _time(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    return hhmm.length == 5 ? '$hhmm:00' : hhmm;
  }
}
