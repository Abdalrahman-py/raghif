import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/auth/demo_accounts.dart';
import '../../core/database/app_database.dart';
import '../../core/di/injection.dart';
import '../../core/i18n/strings.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../domain/models/customer_summary_model.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_model.dart';
import '../../domain/repositories/queue_repository.dart';
import 'memory_database_native.dart'
    if (dart.library.html) 'memory_database_web.dart';
import 'queue_logic.dart';

/// Pilot store identifier matching the seeded demo owner's store (store #1).
const int demoOwnerStoreId = 1;

/// Controller managing bakery queue state and operations. Backed by
/// [QueueRepository] (Drift persistence) with reactive streams.
class QueueController extends ChangeNotifier {
  factory QueueController([QueueRepository? repository]) {
    if (repository != null) return QueueController._(repository, null);
    if (sl.isRegistered<QueueRepository>()) {
      return QueueController._(sl<QueueRepository>(), null);
    }
    final db = AppDatabase(inMemoryExecutor());
    final repo = QueueRepositoryImpl(db);
    unawaited(repo.ensureSeeded());
    return QueueController._(repo, db);
  }

  QueueController._(this._repository, this._ownedDatabase) {
    _stores = defaultStores;
    _init();
  }

  /// Non-null only when this controller created its own database (no DI,
  /// no injected repository) — [dispose] must close it or the connection
  /// and its pending operations leak past the widget's lifetime.
  final AppDatabase? _ownedDatabase;

  static const List<StoreModel> defaultStores = [
    StoreModel(
      id: 1,
      name: 'مخبز الرمال',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 45,
      ownerPhone: demoOwnerPhone,
      allocationDate: '',
    ),
    StoreModel(
      id: 2,
      name: 'مخبز الشاطئ',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 120,
      ownerPhone: '0599000003',
      allocationDate: '',
    ),
    StoreModel(
      id: 3,
      name: 'مخبز النصيرات',
      isOpen: false,
      dailyBagLimit: 300,
      bagsRemaining: 0,
      ownerPhone: '0599000004',
      allocationDate: '',
    ),
  ];

  final QueueRepository _repository;
  StreamSubscription<List<StoreModel>>? _storesSub;
  List<StoreModel> _stores = [];
  bool _storesLoaded = false;
  final Map<int, PurchaseModel> _purchaseCache = {};

  List<StoreModel> get stores => _stores;

  /// True once the repository's real store data has arrived at least once —
  /// [stores] holds [defaultStores] (a same-shaped placeholder) until then,
  /// so widgets that sync local edit state from a store "once on load"
  /// should gate that sync on this rather than on `storeById(...) != null`.
  bool get storesLoaded => _storesLoaded;

  void _init() {
    _storesSub = _repository.watchStores().listen((stores) {
      if (stores.isNotEmpty) {
        _stores = stores;
        _storesLoaded = true;
        notifyListeners();
      }
    });
  }

  static int _parseInt(dynamic value, [int fallback = -1]) {
    if (value is int) return value;
    if (value == null) return fallback;
    final str = value.toString();
    final sanitized = str.replaceAll('store_', '').replaceAll('purchase_', '');
    return int.tryParse(sanitized) ?? fallback;
  }

  StoreModel? storeById(dynamic id) {
    final intId = _parseInt(id, 1);
    for (final s in _stores) {
      if (s.id == intId) return s;
    }
    return null;
  }

  PurchaseModel? cachedPurchase(dynamic id) => _purchaseCache[_parseInt(id)];

  Stream<List<StoreModel>> watchStores() => _repository.watchStores();

  Stream<PurchaseModel?> watchPurchase(dynamic id) {
    final pId = _parseInt(id);
    return _repository.watchPurchaseById(pId);
  }

  Future<PurchaseModel?> purchaseById(dynamic id) {
    final pId = _parseInt(id);
    return _repository.getPurchaseById(pId);
  }

  /// Chronological queue for one store/day as a stream.
  Stream<List<PurchaseModel>> watchQueueForStore(dynamic storeId, String date) {
    final sId = _parseInt(storeId, 1);
    return _repository.watchQueueForStore(sId, date);
  }

  /// Chronological (purchase-order) queue for one store/day.
  Future<List<PurchaseModel>> queueForStore(dynamic storeId, String date) {
    final sId = _parseInt(storeId, 1);
    return _repository.getQueueForStore(sId, date);
  }

  /// Returns existing blocking purchase if user already has an active purchase today.
  Future<PurchaseModel?> blockingPurchaseFor(
    dynamic userId,
    dynamic storeId,
    String date,
  ) {
    if (userId is int) {
      return _repository.getBlockingPurchase(userId, date);
    }
    final str = userId?.toString() ?? '';
    if (str.startsWith('0') || str.length >= 9) {
      return _repository.getBlockingPurchase(0, date, userPhone: str);
    }
    final uId = _parseInt(userId, -1);
    return _repository.getBlockingPurchase(uId, date);
  }

  /// Records a purchase for [userId] at [storeId].
  Future<PurchaseModel> buy({
    required dynamic userId,
    required dynamic storeId,
    required String date,
  }) async {
    final uId = _parseInt(userId);
    final sId = _parseInt(storeId);
    final purchase = await _repository.reserveBag(
      userId: uId,
      storeId: sId,
      date: date,
    );
    _purchaseCache[purchase.id] = purchase;
    notifyListeners();
    final storeName = purchase.storeName ?? storeById(sId)?.name ?? '';
    await NotificationService.instance.showNotification(
      title: Strings.purchaseConfirmedNotificationTitle(storeName),
      body: Strings.purchaseConfirmedNotificationBody(purchase.batchNumber),
    );
    return purchase;
  }

  /// Owner action: notify every waiting buyer in the next un-notified batch.
  ///
  /// There's no push backend in this prototype, so the "notification" a
  /// buyer would get in production is simulated here: firing a real OS
  /// notification directly on whatever device runs this action.
  Future<void> notifyNextBatch(dynamic storeId, String date) async {
    final sId = _parseInt(storeId);
    final notified = await _repository.notifyNextBatch(sId, date);
    notifyListeners();
    if (notified) {
      final storeName = storeById(sId)?.name ?? '';
      await NotificationService.instance.showNotification(
        title: Strings.batchReadyNotificationTitle(storeName),
        body: Strings.batchReadyNotificationBody,
      );
    }
  }

  /// Owner action: notified <-> collected check-in toggle.
  Future<void> toggleArrival(dynamic purchaseId) async {
    final pId = _parseInt(purchaseId);
    final purchase = await _repository.getPurchaseById(pId);
    if (purchase == null) return;
    final newStatus = toggleArrivalStatus(purchase.status);
    await _repository.updatePurchaseStatus(pId, newStatus);
    notifyListeners();
  }

  /// Owner action: top up today's allocation and purchase window.
  Future<void> saveAllocation(
    dynamic storeId, {
    required int dailyBagLimit,
    required int batchSize,
    required String today,
    String? openTime,
    String? closeTime,
  }) async {
    final sId = _parseInt(storeId);
    await _repository.saveStoreAllocation(
      sId,
      dailyLimit: dailyBagLimit,
      batchSize: batchSize,
      date: today,
      openTime: openTime,
      closeTime: closeTime,
    );
    notifyListeners();
  }

  /// Watch distinct customers for store across all dates.
  Stream<List<CustomerSummaryModel>> watchCustomersForStore(dynamic storeId) {
    final sId = _parseInt(storeId, 1);
    return _repository.watchCustomersForStore(sId);
  }

  /// Get distinct customers for store across all dates.
  Future<List<CustomerSummaryModel>> getCustomersForStore(dynamic storeId) {
    final sId = _parseInt(storeId, 1);
    return _repository.getCustomersForStore(sId);
  }

  @override
  void dispose() {
    _storesSub?.cancel();
    _ownedDatabase?.close();
    super.dispose();
  }
}
