import 'package:drift/drift.dart';
import '../../core/auth/demo_accounts.dart';
import '../../core/auth/pin_hash.dart';
import '../../core/database/app_database.dart';
import '../../domain/models/customer_summary_model.dart';
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
      openTime: store.openTime,
      closeTime: store.closeTime,
      batchSize: store.batchSize,
    );
  }

  /// Batch numbers aren't stored per purchase — they're derived from queue
  /// position and the store's *current* batch size, so changing the batch
  /// size immediately regroups everyone already waiting.
  List<PurchaseModel> _withDynamicBatchNumbers(
    List<PurchaseModel> queueOrderedByPosition,
    int batchSize,
  ) {
    final size = batchSize < 1 ? 1 : batchSize;
    return [
      for (var i = 0; i < queueOrderedByPosition.length; i++)
        queueOrderedByPosition[i].copyWith(batchNumber: (i ~/ size) + 1),
    ];
  }

  @override
  Future<void> ensureSeeded() async {
    final existingStore = await (_db.select(
      _db.stores,
    )..limit(1)).getSingleOrNull();
    if (existingStore == null) {
      await _db.batch((batch) {
        batch.insertAll(_db.stores, [
          StoresCompanion.insert(
            name: 'مخبز الرمال',
            ownerPhone: demoOwnerPhone,
            isOpen: const Value(true),
            dailyBagLimit: 300,
            bagsRemaining: 45,
            openTime: const Value('08:00'),
            closeTime: const Value('10:00'),
          ),
          StoresCompanion.insert(
            name: 'مخبز الشاطئ',
            ownerPhone: '0599000003',
            isOpen: const Value(true),
            dailyBagLimit: 300,
            bagsRemaining: 120,
            openTime: const Value('07:30'),
            closeTime: const Value('09:30'),
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

    final existingUser = await (_db.select(
      _db.users,
    )..limit(1)).getSingleOrNull();
    if (existingUser == null) {
      await _db.batch((batch) {
        batch.insertAll(_db.users, [
          UsersCompanion.insert(
            phone: demoBuyerPhone,
            nationalId: demoBuyerNationalId,
            pinHash: hashPin(demoBuyerPhone, demoBuyerPin),
            name: demoBuyerName,
            role: const Value('buyer'),
            jawwalPayNumber: const Value('0599000001'),
            verificationStatus: const Value('verified'),
          ),
          UsersCompanion.insert(
            phone: demoOwnerPhone,
            nationalId: demoOwnerNationalId,
            pinHash: hashPin(demoOwnerPhone, demoOwnerPin),
            name: demoOwnerName,
            role: const Value('owner'),
            jawwalPayNumber: const Value('0599000002'),
            verificationStatus: const Value('verified'),
          ),
        ]);
      });
    }
  }

  @override
  Stream<List<StoreModel>> watchStores() {
    return _db
        .select(_db.stores)
        .watch()
        .map((stores) => stores.map(_storeToDomain).toList());
  }

  @override
  Future<List<StoreModel>> getStores() async {
    final stores = await _db.select(_db.stores).get();
    return stores.map(_storeToDomain).toList();
  }

  @override
  Future<StoreModel?> getStoreById(int storeId) async {
    final store = await (_db.select(
      _db.stores,
    )..where((s) => s.id.equals(storeId))).getSingleOrNull();
    return store == null ? null : _storeToDomain(store);
  }

  @override
  Stream<List<PurchaseModel>> watchQueueForStore(int storeId, String date) {
    final query =
        _db.select(_db.purchases).join([
            innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
            innerJoin(
              _db.stores,
              _db.stores.id.equalsExp(_db.purchases.storeId),
            ),
          ])
          ..where(
            _db.purchases.storeId.equals(storeId) &
                _db.purchases.purchaseDate.equals(date),
          )
          ..orderBy([OrderingTerm.asc(_db.purchases.id)]);

    return query.watch().map((rows) {
      final queue = rows.map((row) {
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
      final batchSize = rows.isEmpty
          ? 20
          : rows.first.readTable(_db.stores).batchSize;
      return _withDynamicBatchNumbers(queue, batchSize);
    });
  }

  @override
  Future<List<PurchaseModel>> getQueueForStore(int storeId, String date) async {
    final query =
        _db.select(_db.purchases).join([
            innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
            innerJoin(
              _db.stores,
              _db.stores.id.equalsExp(_db.purchases.storeId),
            ),
          ])
          ..where(
            _db.purchases.storeId.equals(storeId) &
                _db.purchases.purchaseDate.equals(date),
          )
          ..orderBy([OrderingTerm.asc(_db.purchases.id)]);

    final rows = await query.get();
    final queue = rows.map((row) {
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
    final batchSize = rows.isEmpty
        ? 20
        : rows.first.readTable(_db.stores).batchSize;
    return _withDynamicBatchNumbers(queue, batchSize);
  }

  @override
  Future<PurchaseModel?> getBlockingPurchase(
    int userId,
    String date, {
    String? userPhone,
  }) async {
    final query =
        _db.select(_db.purchases).join([
            innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
            innerJoin(
              _db.stores,
              _db.stores.id.equalsExp(_db.purchases.storeId),
            ),
          ])
          ..where(
            (userPhone != null
                    ? _db.users.phone.equals(userPhone)
                    : _db.purchases.userId.equals(userId)) &
                _db.purchases.purchaseDate.equals(date),
          )
          ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final p = row.readTable(_db.purchases);
    final queue = await getQueueForStore(p.storeId, p.purchaseDate);
    return queue.firstWhere((q) => q.id == p.id);
  }

  @override
  Future<PurchaseModel?> getPurchaseById(int purchaseId) async {
    final query =
        _db.select(_db.purchases).join([
            innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
            innerJoin(
              _db.stores,
              _db.stores.id.equalsExp(_db.purchases.storeId),
            ),
          ])
          ..where(_db.purchases.id.equals(purchaseId))
          ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final p = row.readTable(_db.purchases);
    final queue = await getQueueForStore(p.storeId, p.purchaseDate);
    return queue.firstWhere((q) => q.id == p.id);
  }

  @override
  Stream<PurchaseModel?> watchPurchaseById(int purchaseId) {
    final query =
        _db.select(_db.purchases).join([
            innerJoin(_db.users, _db.users.id.equalsExp(_db.purchases.userId)),
            innerJoin(
              _db.stores,
              _db.stores.id.equalsExp(_db.purchases.storeId),
            ),
          ])
          ..where(_db.purchases.id.equals(purchaseId))
          ..limit(1);

    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final p = row.readTable(_db.purchases);
      final queue = await getQueueForStore(p.storeId, p.purchaseDate);
      return queue.firstWhere((q) => q.id == p.id);
    });
  }

  @override
  Future<PurchaseModel> reserveBag({
    required int userId,
    required int storeId,
    required String date,
  }) async {
    return _db.transaction(() async {
      final store = await (_db.select(
        _db.stores,
      )..where((s) => s.id.equals(storeId))).getSingle();

      if (store.bagsRemaining <= 0) {
        throw StoreSoldOutException();
      }

      final existingQueue =
          await (_db.select(_db.purchases)..where(
                (p) => p.storeId.equals(storeId) & p.purchaseDate.equals(date),
              ))
              .get();

      final position = existingQueue.length + 1;
      final batchSize = store.batchSize < 1 ? 1 : store.batchSize;
      final batchNumber = ((position - 1) ~/ batchSize) + 1;
      final now = DateTime.now().millisecondsSinceEpoch;

      final purchaseId = await _db
          .into(_db.purchases)
          .insert(
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
          bagsRemaining: Value(
            store.bagsRemaining > 0 ? store.bagsRemaining - 1 : 0,
          ),
        ),
      );

      final user = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingle();

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
  Future<bool> notifyNextBatch(int storeId, String date) async {
    final queue = await getQueueForStore(storeId, date);
    final waiting = queue.where((p) => p.status == PurchaseStatus.waiting);
    if (waiting.isEmpty) return false;
    final nextBatch = waiting
        .map((p) => p.batchNumber)
        .reduce((a, b) => a < b ? a : b);

    final waitingInNextBatch = waiting
        .where((p) => p.batchNumber == nextBatch)
        .toList();

    await (_db.update(_db.purchases)..where(
          (p) => p.id.isIn(waitingInNextBatch.map((p) => p.id)),
        ))
        .write(
          const PurchasesCompanion(status: Value(PurchaseStatus.notified)),
        );
    return true;
  }

  @override
  Future<void> updatePurchaseStatus(
    int purchaseId,
    PurchaseStatus newStatus,
  ) async {
    await (_db.update(_db.purchases)..where((p) => p.id.equals(purchaseId)))
        .write(PurchasesCompanion(status: Value(newStatus)));
  }

  @override
  Future<void> setStoreOpen(int storeId, bool isOpen) async {
    await (_db.update(_db.stores)..where((s) => s.id.equals(storeId))).write(
      StoresCompanion(isOpen: Value(isOpen)),
    );
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
    await _db.transaction(() async {
      final store = await (_db.select(
        _db.stores,
      )..where((s) => s.id.equals(storeId))).getSingle();
      // Preserve bags already sold today: shift remaining by however much
      // the limit changed, instead of resetting to the full new limit.
      final delta = dailyLimit - store.dailyBagLimit;
      final newRemaining = (store.bagsRemaining + delta).clamp(0, dailyLimit);
      await (_db.update(_db.stores)..where((s) => s.id.equals(storeId))).write(
        StoresCompanion(
          dailyBagLimit: Value(dailyLimit),
          bagsRemaining: Value(newRemaining),
          openTime: Value(openTime),
          closeTime: Value(closeTime),
          batchSize: Value(batchSize),
        ),
      );
    });
  }

  @override
  Stream<List<CustomerSummaryModel>> watchCustomersForStore(int storeId) {
    return _db
        .customSelect(
          'SELECT u.id AS user_id, u.name AS user_name, u.phone AS user_phone, '
          'COUNT(p.id) AS total_purchases, MAX(p.purchase_date) AS last_purchase_date '
          'FROM purchases p '
          'INNER JOIN users u ON u.id = p.user_id '
          'WHERE p.store_id = ? '
          'GROUP BY u.id '
          'ORDER BY last_purchase_date DESC, MAX(p.created_at) DESC',
          variables: [Variable.withInt(storeId)],
          readsFrom: {_db.purchases, _db.users},
        )
        .watch()
        .map((rows) {
          return rows.map((row) {
            return CustomerSummaryModel(
              userId: row.read<int>('user_id'),
              name: row.read<String>('user_name'),
              phone: row.read<String>('user_phone'),
              totalPurchases: row.read<int>('total_purchases'),
              lastPurchaseDate: row.read<String>('last_purchase_date'),
            );
          }).toList();
        });
  }

  @override
  Future<List<CustomerSummaryModel>> getCustomersForStore(int storeId) async {
    final rows = await _db
        .customSelect(
          'SELECT u.id AS user_id, u.name AS user_name, u.phone AS user_phone, '
          'COUNT(p.id) AS total_purchases, MAX(p.purchase_date) AS last_purchase_date '
          'FROM purchases p '
          'INNER JOIN users u ON u.id = p.user_id '
          'WHERE p.store_id = ? '
          'GROUP BY u.id '
          'ORDER BY last_purchase_date DESC, MAX(p.created_at) DESC',
          variables: [Variable.withInt(storeId)],
          readsFrom: {_db.purchases, _db.users},
        )
        .get();

    return rows.map((row) {
      return CustomerSummaryModel(
        userId: row.read<int>('user_id'),
        name: row.read<String>('user_name'),
        phone: row.read<String>('user_phone'),
        totalPurchases: row.read<int>('total_purchases'),
        lastPurchaseDate: row.read<String>('last_purchase_date'),
      );
    }).toList();
  }
}
