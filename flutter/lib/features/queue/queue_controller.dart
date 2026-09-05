import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import '../../core/auth/demo_accounts.dart';
import '../../core/database/app_database.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_model.dart';
import '../../domain/repositories/queue_repository.dart';
import 'queue_logic.dart';

/// Pilot store identifier matching the seeded demo owner's store (store #1).
const int demoOwnerStoreId = 1;

/// Controller managing bakery queue state and operations. Backed by
/// [QueueRepository] (Drift persistence) with reactive streams.
class QueueController extends ChangeNotifier {
  QueueController([QueueRepository? repository])
      : _repository = repository ??
            (sl.isRegistered<QueueRepository>()
                ? sl<QueueRepository>()
                : QueueRepositoryImpl(AppDatabase(NativeDatabase.memory()))..ensureSeeded()) {
    _stores = defaultStores;
    _init();
  }

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
  final Map<int, PurchaseModel> _purchaseCache = {};

  List<StoreModel> get stores => _stores;

  void _init() {
    _storesSub = _repository.watchStores().listen((stores) {
      if (stores.isNotEmpty) {
        _stores = stores;
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
    int batchSize = 20,
  }) async {
    final uId = _parseInt(userId);
    final sId = _parseInt(storeId);
    final purchase = await _repository.reserveBag(
      userId: uId,
      storeId: sId,
      date: date,
      batchSize: batchSize,
    );
    _purchaseCache[purchase.id] = purchase;
    notifyListeners();
    return purchase;
  }

  /// Owner action: notify every waiting buyer in the next un-notified batch.
  Future<void> notifyNextBatch(dynamic storeId, String date) async {
    final sId = _parseInt(storeId);
    await _repository.notifyNextBatch(sId, date);
    notifyListeners();
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

  Future<void> setPurchaseWindowOpen(dynamic storeId, bool open) async {
    final sId = _parseInt(storeId);
    await _repository.setStoreOpen(sId, open);
    notifyListeners();
  }

  /// Owner action: top up today's allocation.
  Future<void> saveAllocation(
    dynamic storeId, {
    required int dailyBagLimit,
    required int batchSize,
    required String today,
  }) async {
    final sId = _parseInt(storeId);
    await _repository.saveStoreAllocation(
      sId,
      dailyLimit: dailyBagLimit,
      batchSize: batchSize,
      date: today,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _storesSub?.cancel();
    super.dispose();
  }
}
