import 'package:drift/drift.dart';
import '../../core/auth/demo_accounts.dart';
import '../../core/database/app_database.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_model.dart';
import '../../domain/repositories/queue_repository.dart';

class QueueRepositoryImpl implements QueueRepository {
  QueueRepositoryImpl(this._db);

  final AppDatabase _db;

  StoreModel _storeToDomain(Store store) {
    return StoreModel(
      id: store.id,
      name: store.name,
      isOpen: store.isOpen,
      dailyBagLimit: store.dailyBagLimit,
      bagsRemaining: store.bagsRemaining,
      ownerPhone: store.ownerPhone,
    );
  }

  @override
  Future<void> ensureSeeded() async {
    final existing = await (_db.select(_db.stores)..limit(1)).getSingleOrNull();
    if (existing != null) return;

    await _db.batch((batch) {
      batch.insertAll(_db.stores, [
        StoresCompanion.insert(
          name: 'مخبز الرمال',
          ownerPhone: demoOwnerPhone,
          isOpen: const Value(true),
          dailyBagLimit: 300,
          bagsRemaining: 45,
        ),
        StoresCompanion.insert(
          name: 'مخبز الشاطئ',
          ownerPhone: '0599000003',
          isOpen: const Value(true),
          dailyBagLimit: 300,
          bagsRemaining: 120,
        ),
        StoresCompanion.insert(
          name: 'مخبز النصيرات',
          ownerPhone: '0599000004',
          isOpen: const Value(false),
          dailyBagLimit: 300,
          bagsRemaining: 0,
        ),
      ]);
    });
  }

  @override
  Stream<List<StoreModel>> watchStores() {
    return _db.select(_db.stores).watch().map(
          (stores) => stores.map(_storeToDomain).toList(),
        );
  }

  @override
  Future<List<StoreModel>> getStores() async {
    final stores = await _db.select(_db.stores).get();
    return stores.map(_storeToDomain).toList();
  }

  @override
  Future<StoreModel?> getStoreById(int storeId) async {
    final store = await (_db.select(_db.stores)
          ..where((s) => s.id.equals(storeId)))
        .getSingleOrNull();
    return store == null ? null : _storeToDomain(store);
  }

  @override
  Stream<List<PurchaseModel>> watchQueueForStore(int storeId, String date) {
    final query = _db.select(_db.purchases).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
      innerJoin(_db.stores, _db.stores.id.equalsExp(_db.purchases.storeId)),
    ])
      ..where(_db.purchases.storeId.equals(storeId) &
          _db.purchases.purchaseDate.equals(date))
      ..orderBy([OrderingTerm.asc(_db.purchases.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final p = row.readTable(_db.purchases);
        final u = row.readTable(_db.users);
        final s = row.readTable(_db.stores);
        return PurchaseModel(
          id: p.id,
          storeId: p.storeId,
          userId: p.userId,
          purchaseDate: p.purchaseDate,
          batchNumber: p.batchNumber,
          status: p.status,
          createdAtMillis: p.createdAt,
          userName: u.name,
          userPhone: u.phone,
          storeName: s.name,
        );
      }).toList();
    });
  }

  @override
  Future<List<PurchaseModel>> getQueueForStore(int storeId, String date) async {
    final query = _db.select(_db.purchases).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
      innerJoin(_db.stores, _db.stores.id.equalsExp(_db.purchases.storeId)),
    ])
      ..where(_db.purchases.storeId.equals(storeId) &
          _db.purchases.purchaseDate.equals(date))
      ..orderBy([OrderingTerm.asc(_db.purchases.createdAt)]);

    final rows = await query.get();
    return rows.map((row) {
      final p = row.readTable(_db.purchases);
      final u = row.readTable(_db.users);
      final s = row.readTable(_db.stores);
      return PurchaseModel(
        id: p.id,
        storeId: p.storeId,
        userId: p.userId,
        purchaseDate: p.purchaseDate,
        batchNumber: p.batchNumber,
        status: p.status,
        createdAtMillis: p.createdAt,
        userName: u.name,
        userPhone: u.phone,
        storeName: s.name,
      );
    }).toList();
  }

  @override
  Future<PurchaseModel?> getBlockingPurchase(int userId, String date) async {
    final query = _db.select(_db.purchases).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
      innerJoin(_db.stores, _db.stores.id.equalsExp(_db.purchases.storeId)),
    ])
      ..where(_db.purchases.userId.equals(userId) &
          _db.purchases.purchaseDate.equals(date))
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final p = row.readTable(_db.purchases);
    final u = row.readTable(_db.users);
    final s = row.readTable(_db.stores);
    return PurchaseModel(
      id: p.id,
      storeId: p.storeId,
      userId: p.userId,
      purchaseDate: p.purchaseDate,
      batchNumber: p.batchNumber,
      status: p.status,
      createdAtMillis: p.createdAt,
      userName: u.name,
      userPhone: u.phone,
      storeName: s.name,
    );
  }

  @override
  Future<PurchaseModel?> getPurchaseById(int purchaseId) async {
    final query = _db.select(_db.purchases).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
      innerJoin(_db.stores, _db.stores.id.equalsExp(_db.purchases.storeId)),
    ])
      ..where(_db.purchases.id.equals(purchaseId))
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final p = row.readTable(_db.purchases);
    final u = row.readTable(_db.users);
    final s = row.readTable(_db.stores);
    return PurchaseModel(
      id: p.id,
      storeId: p.storeId,
      userId: p.userId,
      purchaseDate: p.purchaseDate,
      batchNumber: p.batchNumber,
      status: p.status,
      createdAtMillis: p.createdAt,
      userName: u.name,
      userPhone: u.phone,
      storeName: s.name,
    );
  }

  @override
  Future<PurchaseModel> reserveBag({
    required int userId,
    required int storeId,
    required String date,
    int batchSize = 20,
  }) async {
    return _db.transaction(() async {
      final store = await (_db.select(_db.stores)
            ..where((s) => s.id.equals(storeId)))
          .getSingle();

      final existingQueue = await (_db.select(_db.purchases)
            ..where((p) =>
                p.storeId.equals(storeId) & p.purchaseDate.equals(date)))
          .get();

      final position = existingQueue.length + 1;
      final batchNumber = ((position - 1) ~/ batchSize) + 1;
      final now = DateTime.now().millisecondsSinceEpoch;

      final purchaseId = await _db.into(_db.purchases).insert(
            PurchasesCompanion.insert(
              storeId: storeId,
              userId: userId,
              purchaseDate: date,
              batchNumber: batchNumber,
              status: PurchaseStatus.waiting,
              createdAt: now,
            ),
          );

      await (_db.update(_db.stores)..where((s) => s.id.equals(storeId))).write(
        StoresCompanion(
          bagsRemaining: Value(store.bagsRemaining > 0 ? store.bagsRemaining - 1 : 0),
        ),
      );

      final user = await (_db.select(_db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingle();

      return PurchaseModel(
        id: purchaseId,
        storeId: storeId,
        userId: userId,
        purchaseDate: date,
        batchNumber: batchNumber,
        status: PurchaseStatus.waiting,
        createdAtMillis: now,
        userName: user.name,
        userPhone: user.phone,
        storeName: store.name,
      );
    });
  }

  @override
  Future<void> notifyNextBatch(int storeId, String date) async {
    final waiting = await (_db.select(_db.purchases)
          ..where((p) =>
              p.storeId.equals(storeId) &
              p.purchaseDate.equals(date) &
              p.status.equalsValue(PurchaseStatus.waiting))
          ..orderBy([(p) => OrderingTerm.asc(p.batchNumber)]))
        .get();

    if (waiting.isEmpty) return;
    final nextBatch = waiting.first.batchNumber;

    await (_db.update(_db.purchases)
          ..where((p) =>
              p.storeId.equals(storeId) &
              p.purchaseDate.equals(date) &
              p.batchNumber.equals(nextBatch) &
              p.status.equalsValue(PurchaseStatus.waiting)))
        .write(
      const PurchasesCompanion(
        status: Value(PurchaseStatus.notified),
      ),
    );
  }

  @override
  Future<void> updatePurchaseStatus(
      int purchaseId, PurchaseStatus newStatus) async {
    await (_db.update(_db.purchases)..where((p) => p.id.equals(purchaseId)))
        .write(
      PurchasesCompanion(
        status: Value(newStatus),
      ),
    );
  }

  @override
  Future<void> setStoreOpen(int storeId, bool isOpen) async {
    await (_db.update(_db.stores)..where((s) => s.id.equals(storeId))).write(
      StoresCompanion(
        isOpen: Value(isOpen),
      ),
    );
  }

  @override
  Future<void> saveStoreAllocation(
    int storeId, {
    required int dailyLimit,
    required int batchSize,
    required String date,
  }) async {
    await (_db.update(_db.stores)..where((s) => s.id.equals(storeId))).write(
      StoresCompanion(
        dailyBagLimit: Value(dailyLimit),
        bagsRemaining: Value(dailyLimit),
      ),
    );
  }
}
