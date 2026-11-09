import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/cache/offline_cache.dart';
import '../../core/di/injection.dart';
import '../../domain/models/customer_summary_model.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/scan_event_model.dart';
import '../../domain/models/store_day_summary.dart';
import '../../domain/models/store_list_entry.dart';
import '../../domain/models/store_model.dart';
import '../../domain/repositories/queue_repository.dart';
import 'queue_logic.dart';

/// Presentation state over [QueueRepository]. Holds no business rules of its
/// own: Postgres decides what a reservation, a batch release or a pickup
/// means, and this reflects the result.
///
/// Ids are Supabase UUID strings. The old `dynamic` id parameters and their
/// `_parseInt` coercion are gone — they existed only because a store was
/// "1" on one device, "store_1" in a QR code and a different row on the
/// server.
class QueueController extends ChangeNotifier {
  QueueController([QueueRepository? repository, OfflineCache? cache])
    : _repository = repository ?? sl<QueueRepository>(),
      _cache = cache {
    _init();
  }

  final QueueRepository _repository;

  /// What the buyer last saw, for when the server cannot be reached. Null in
  /// tests and anywhere offline reading is not wanted.
  final OfflineCache? _cache;
  bool _storeListStale = false;
  StreamSubscription<List<StoreModel>>? _storesSub;
  List<StoreModel> _stores = [];
  bool _storesLoaded = false;
  bool _storesFailed = false;
  bool _disposed = false;
  int _storesRequest = 0;
  int _storeListGeneration = 0;
  int _queueGeneration = 0;
  int _sessionGeneration = 0;
  String? _storeListUser;
  bool _storeListLoaded = false;
  bool _storeListFailed = false;
  StreamSubscription<List<StoreListEntry>>? _storeListSub;
  List<StoreListEntry> _storeList = [];
  StreamSubscription<List<PurchaseModel>>? _todayQueueSub;
  List<PurchaseModel> _todayQueue = [];
  final Map<String, PurchaseModel> _purchaseCache = {};

  List<StoreModel> get stores => _stores;

  /// True once store rows have arrived from the cache or the server. Widgets
  /// that seed local edit state "once on load" should gate on this rather
  /// than on an empty list, which is also the pre-load state.
  bool get storesLoaded => _storesLoaded;
  bool get storesFailed => _storesFailed;
  bool get storeListLoaded => _storeListLoaded;
  bool get storeListFailed => _storeListFailed;

  /// The bakery list on screen is the saved copy from the last time the
  /// server answered, because it cannot be reached now.
  bool get storeListStale => _storeListStale;

  Future<void> refreshStores() async {
    final request = ++_storesRequest;
    _storesFailed = false;
    if (!_disposed) notifyListeners();
    try {
      final stores = await _repository.getStores();
      if (_disposed || request != _storesRequest) return;
      _stores = stores;
      _storesLoaded = true;
    } catch (_) {
      if (_disposed || request != _storesRequest) return;
      _storesFailed = true;
    }
    if (!_disposed) notifyListeners();
    await _repository.refresh();
  }

  /// Pull-to-refresh: asks every watching screen to read again. Nothing else
  /// downloads on its own (there is no live connection), so this, the retry
  /// buttons, coming back to the app and a push are how data is renewed.
  Future<void> refreshAll() async {
    await _repository.refresh();
    // The reads run in the background; give the spinner a moment to show.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  /// [clearCache] is false when a session is merely being restored (app
  /// start): the saved copy is exactly what an offline start needs.
  void resetForSession({bool clearCache = true}) {
    _sessionGeneration++;
    _storeListGeneration++;
    _queueGeneration++;
    _storeListSub?.cancel();
    _todayQueueSub?.cancel();
    _storeListUser = null;
    _storeList = [];
    _storeListLoaded = false;
    _storeListFailed = false;
    _storeListStale = false;
    _todayQueue = [];
    _purchaseCache.clear();
    if (clearCache) _cache?.clear();
    if (!_disposed) notifyListeners();
  }

  void _init() {
    _storesSub = _repository.watchStores().listen(
      (stores) {
        _stores = stores;
        _storesLoaded = true;
        _storesFailed = false;
        notifyListeners();
      },
      onError: (_) {
        if (!_disposed) {
          _storesFailed = true;
          notifyListeners();
        }
      },
    );
  }

  StoreModel? storeById(String? id) {
    if (id == null) return null;
    for (final s in _stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The store this owner manages, straight from the server. Replaces the
  /// hardcoded "store #1" the local seed used to guarantee.
  ///
  /// The last answer is saved; with no signal the saved bakery opens the
  /// dashboard instead of an error page (every write still needs the server).
  Future<StoreModel?> storeForOwner(String ownerId) async {
    try {
      final store = await _repository.getStoreForOwner(ownerId);
      if (store != null) _cache?.saveOwnerStore(ownerId, store);
      return store;
    } catch (_) {
      final saved = await _cache?.loadOwnerStore(ownerId);
      if (saved != null) return saved;
      rethrow;
    }
  }

  PurchaseModel? cachedPurchase(String id) => _purchaseCache[id];

  Stream<List<StoreModel>> watchStores() => _repository.watchStores();

  /// Buyer's store list: every store plus this buyer's own context for it
  /// (pinned, today's order, last purchase).
  List<StoreListEntry> get storeList => _storeList;

  /// Points the store-list watch at [userId]. Safe to call again if the user
  /// changes — the old watch is dropped.
  void watchStoreListFor(String userId) {
    final generation = ++_storeListGeneration;
    if (_storeListUser != userId) {
      _storeList = [];
      _storeListLoaded = false;
    }
    _storeListUser = userId;
    _storeListFailed = false;
    _storeListSub?.cancel();
    _storeListSub = _repository
        .watchStoreListForUser(userId: userId, today: todayDateString())
        .listen(
          (entries) {
            if (_disposed || generation != _storeListGeneration) return;
            _storeList = entries;
            _storeListLoaded = true;
            _storeListFailed = false;
            _storeListStale = false;
            _cache?.saveStoreList(userId, entries);
            notifyListeners();
          },
          onError: (_) async {
            if (_disposed || generation != _storeListGeneration) return;
            // Nothing on screen yet and no server: show the saved list, marked
            // as old, instead of an empty error page.
            if (_storeList.isEmpty && _cache != null) {
              final saved = await _cache.loadStoreList(userId);
              if (_disposed || generation != _storeListGeneration) return;
              if (saved.isNotEmpty) {
                _storeList = saved;
                _storeListLoaded = true;
                _storeListFailed = false;
                _storeListStale = true;
                notifyListeners();
                return;
              }
            }
            _storeListFailed = true;
            notifyListeners();
          },
        );
  }

  Future<void> setStorePinned(
    String userId,
    String storeId,
    bool pinned,
  ) async {
    await _repository.setStorePinned(
      userId: userId,
      storeId: storeId,
      pinned: pinned,
    );
    notifyListeners();
  }

  /// Owner action: append one QR scan attempt to the audit trail.
  Future<void> recordScan({
    required String storeId,
    required String outcome,
    String? purchaseId,
    String? scannedName,
  }) async {
    await _repository.recordScan(
      storeId: storeId,
      outcome: outcome,
      purchaseId: purchaseId,
      scannedName: scannedName,
    );
    notifyListeners();
  }

  Future<List<ScanEventModel>> scansForStore(
    String storeId, {
    int limit = 100,
  }) => _repository.getScansForStore(storeId, limit: limit);

  /// A booking's live state. The last copy is saved on the phone: opened with
  /// no signal, the receipt (with its QR) still shows what was last seen, and
  /// the live updates simply resume when the connection returns.
  Stream<PurchaseModel?> watchPurchase(String id) async* {
    final cache = _cache;
    if (cache != null && _purchaseCache[id] == null) {
      final saved = await cache.loadPurchase(id);
      if (saved != null && _purchaseCache[id] == null) {
        _purchaseCache[id] = saved;
        yield saved;
      }
    }
    yield* _repository
        .watchPurchaseById(id)
        // Offline with a saved copy: keep it on screen, no error page.
        .handleError((_) {}, test: (_) => _purchaseCache[id] != null)
        .map((purchase) {
          if (purchase != null) {
            _purchaseCache[id] = purchase;
            cache?.savePurchase(purchase);
          }
          return purchase;
        });
  }

  Future<PurchaseModel?> purchaseById(String id) =>
      _repository.getPurchaseById(id);

  List<PurchaseModel> get todayQueue => _todayQueue;

  /// Points the dashboard's today-queue watch at [storeId].
  void watchTodayQueueFor(String storeId) {
    final generation = ++_queueGeneration;
    _todayQueueSub?.cancel();
    _todayQueueSub = _repository
        .watchQueueForStore(storeId, todayDateString())
        .listen(
          (queue) {
            if (_disposed || generation != _queueGeneration) return;
            _todayQueue = queue;
            _cache?.saveQueue(storeId, todayDateString(), queue);
            notifyListeners();
          },
          onError: (_) async {
            // No signal: show the last queue seen today.
            if (_todayQueue.isNotEmpty || _cache == null) return;
            final saved = await _cache.loadQueue(storeId, todayDateString());
            if (_disposed || generation != _queueGeneration) return;
            if (saved != null && _todayQueue.isEmpty) {
              _todayQueue = saved;
              notifyListeners();
            }
          },
        );
  }

  /// A bakery's queue for [date], live. The last copy is saved: with no signal
  /// the owner still sees the queue as it last was (and the stream resumes on
  /// its own when the connection returns).
  Stream<List<PurchaseModel>> watchQueueForStore(
    String storeId,
    String date,
  ) async* {
    final cache = _cache;
    var shown = false;
    if (cache != null) {
      final saved = await cache.loadQueue(storeId, date);
      if (saved != null) {
        shown = true;
        yield saved;
      }
    }
    yield* _repository
        .watchQueueForStore(storeId, date)
        .handleError((_) {}, test: (_) => shown)
        .map((queue) {
          shown = true;
          cache?.saveQueue(storeId, date, queue);
          return queue;
        });
  }

  Future<List<PurchaseModel>> queueForStore(String storeId, String date) =>
      _repository.getQueueForStore(storeId, date);

  /// This buyer's existing order for [date], if any.
  Future<PurchaseModel?> blockingPurchaseFor(String userId, String date) =>
      _repository.getBlockingPurchase(userId, date);

  Future<PurchaseModel?> currentOrUpcomingPurchase(
    String userId,
    String today,
  ) => _repository.currentOrUpcomingPurchase(userId, today);

  Future<PurchaseModel> postponePurchase(String purchaseId) async {
    final session = _sessionGeneration;
    final purchase = await _repository.postponePurchase(purchaseId);
    if (_disposed || session != _sessionGeneration) return purchase;
    _purchaseCache[purchase.id] = purchase;
    notifyListeners();
    return purchase;
  }

  /// Reserves a bag at [storeId]. The buyer comes from the session
  /// server-side. Throws [StoreSoldOutException] if Postgres says the store
  /// has none left, or [BackendUnavailableException] if it couldn't be
  /// asked — in which case nothing was reserved.
  Future<PurchaseModel> buy({
    required String storeId,
    required String date,
  }) async {
    final session = _sessionGeneration;
    final purchase = await _repository.reserveBag(storeId: storeId, date: date);
    if (_disposed || session != _sessionGeneration) return purchase;
    _purchaseCache[purchase.id] = purchase;
    notifyListeners();
    // The "purchase confirmed" push is sent by the backend (notify-batch).
    return purchase;
  }

  /// Records the (simulated) wallet payment for a booking just made. A failure
  /// is not fatal: the booking stands and the bakery will ask for cash.
  Future<void> recordWalletPayment(String purchaseId) async {
    await _repository.recordWalletPayment(purchaseId);
    final cached = _purchaseCache[purchaseId];
    if (cached != null) {
      _purchaseCache[purchaseId] = cached.copyWith(paymentMethod: 'simulated');
      notifyListeners();
    }
  }

  /// Owner action: release the next un-notified batch. The push to those
  /// buyers is sent by the backend (notify-batch Edge Function). Returns
  /// false when there was no waiting batch left.
  Future<bool> notifyNextBatch(String storeId, String date) async {
    final notified = await _repository.notifyNextBatch(storeId, date);
    notifyListeners();
    return notified;
  }

  /// Owner action: hand the bag over.
  ///
  /// One-way, unlike the old notified<->collected toggle: bread that has
  /// been handed to someone cannot be un-handed, and the server offers no
  /// way back. An accidental scan is corrected out-of-band, not by the app
  /// silently rewriting a pickup record.
  Future<void> collectPurchase(String purchaseId) async {
    await _repository.collectPurchase(purchaseId);
    notifyListeners();
  }

  /// Owner action: open or close the store for buying.
  ///
  /// This is the only thing that can stop sales mid-crowd: [StoreModel
  /// .canPurchase] reads the flag, so every buyer device sees the store shut
  /// on its next read. The purchase window's times are informational and do
  /// not themselves gate buying — this does.
  Future<void> setStoreOpen(String storeId, bool isOpen) async {
    await _repository.setStoreOpen(storeId, isOpen);
    notifyListeners();
  }

  /// Owner action: today's allocation and purchase window.
  Future<void> saveAllocation(
    String storeId, {
    required int dailyBagLimit,
    required int batchSize,
    required String today,
    String? openTime,
    String? closeTime,
  }) async {
    await _repository.saveStoreAllocation(
      storeId,
      dailyLimit: dailyBagLimit,
      batchSize: batchSize,
      date: today,
      openTime: openTime,
      closeTime: closeTime,
    );
    notifyListeners();
  }

  Stream<List<CustomerSummaryModel>> watchCustomersForStore(String storeId) =>
      _repository.watchCustomersForStore(storeId);

  Future<List<StoreDaySummary>> dailySummariesForStore(
    String storeId, {
    int limit = 30,
  }) => _repository.getDailySummaries(storeId, limit: limit);

  Future<List<CustomerSummaryModel>> getCustomersForStore(String storeId) =>
      _repository.getCustomersForStore(storeId);

  @override
  void dispose() {
    _disposed = true;
    _storeListGeneration++;
    _queueGeneration++;
    _storesRequest++;
    _storesSub?.cancel();
    _storeListSub?.cancel();
    _todayQueueSub?.cancel();
    super.dispose();
  }
}
