import 'package:drift/drift.dart';
import '../../core/auth/demo_accounts.dart';
import '../../core/auth/pin_hash.dart';
import '../../core/database/app_database.dart';
import '../../domain/models/customer_summary_model.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/models/scan_event_model.dart';
import '../../domain/models/store_day_summary.dart';
import '../../domain/models/store_list_entry.dart';
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
      area: store.area,
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
            area: const Value('الرمال'),
          ),
          StoresCompanion.insert(
            name: 'مخبز الشاطئ',
            ownerPhone: '0599000003',
            isOpen: const Value(true),
            dailyBagLimit: 300,
            bagsRemaining: 120,
            openTime: const Value('07:30'),
            closeTime: const Value('09:30'),
            area: const Value('الشاطئ'),
          ),
          StoresCompanion.insert(
            name: 'مخبز النصيرات',
            ownerPhone: '0599000004',
            isOpen: const Value(false),
            dailyBagLimit: 300,
            bagsRemaining: 0,
            area: const Value('النصيرات'),
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
  Stream<List<StoreListEntry>> watchStoreListForUser({
    required int userId,
    required String today,
  }) {
    // One row per store with three per-buyer sub-selects: whether they pinned
    // it, today's order status, and their most recent purchase date. Kept as
    // one query so the list reacts to pins, purchases and store edits alike.
    final query = _db.customSelect(
      '''
      SELECT
        s.id              AS store_id,
        s.name            AS name,
        s.owner_phone     AS owner_phone,
        s.is_open         AS is_open,
        s.daily_bag_limit AS daily_bag_limit,
        s.bags_remaining  AS bags_remaining,
        s.open_time       AS open_time,
        s.close_time      AS close_time,
        s.batch_size      AS batch_size,
        s.area            AS area,
        EXISTS(
          SELECT 1 FROM store_pins pin
          WHERE pin.store_id = s.id AND pin.user_id = ?
        ) AS pinned,
        (
          SELECT p.status FROM purchases p
          WHERE p.store_id = s.id
            AND p.user_id = ?
            AND p.purchase_date = ?
          ORDER BY p.id DESC
          LIMIT 1
        ) AS today_status,
        (
          SELECT p.id FROM purchases p
          WHERE p.store_id = s.id
            AND p.user_id = ?
            AND p.purchase_date = ?
          ORDER BY p.id DESC
          LIMIT 1
        ) AS today_purchase_id,
        (
          SELECT p.purchase_date FROM purchases p
          WHERE p.store_id = s.id AND p.user_id = ?
          ORDER BY p.purchase_date DESC, p.id DESC
          LIMIT 1
        ) AS last_purchase_date
      FROM stores s
      ORDER BY s.name
      ''',
      variables: [
        Variable.withInt(userId),
        Variable.withInt(userId),
        Variable.withString(today),
        Variable.withInt(userId),
        Variable.withString(today),
        Variable.withInt(userId),
      ],
      readsFrom: {_db.stores, _db.purchases, _db.storePins},
    );

    return query.watch().map((rows) {
      return rows.map((row) {
        final statusRaw = row.readNullable<String>('today_status');
        return StoreListEntry(
          store: StoreModel(
            id: row.read<int>('store_id'),
            name: row.read<String>('name'),
            ownerPhone: row.read<String>('owner_phone'),
            isOpen: row.read<int>('is_open') != 0,
            dailyBagLimit: row.read<int>('daily_bag_limit'),
            bagsRemaining: row.read<int>('bags_remaining'),
            openTime: row.readNullable<String>('open_time'),
            closeTime: row.readNullable<String>('close_time'),
            batchSize: row.read<int>('batch_size'),
            area: row.read<String>('area'),
          ),
          pinned: row.read<int>('pinned') != 0,
          todayStatus: statusRaw == null
              ? null
              : PurchaseStatus.values.byName(statusRaw),
          todayPurchaseId: row.readNullable<int>('today_purchase_id'),
          lastPurchaseDate: row.readNullable<String>('last_purchase_date'),
        );
      }).toList();
    });
  }

  @override
  Future<void> setStorePinned({
    required int userId,
    required int storeId,
    required bool pinned,
  }) async {
    if (pinned) {
      await _db
          .into(_db.storePins)
          .insert(
            StorePinsCompanion.insert(
              userId: userId,
              storeId: storeId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    } else {
      await (_db.delete(_db.storePins)..where(
            (row) => row.userId.equals(userId) & row.storeId.equals(storeId),
          ))
          .go();
    }
  }

  @override
  Future<void> recordScan({
    required int storeId,
    required String outcome,
    int? purchaseId,
    String? scannedName,
    String? scannedNationalId,
  }) async {
    await _db.into(_db.scanEvents).insert(
          ScanEventsCompanion.insert(
            storeId: storeId,
            outcome: outcome,
            scannedAt: DateTime.now().millisecondsSinceEpoch,
            purchaseId: Value(purchaseId),
            scannedName: Value(scannedName),
            scannedNationalId: Value(scannedNationalId),
          ),
        );
  }

  @override
  Future<List<ScanEventModel>> getScansForStore(
    int storeId, {
    int limit = 100,
  }) async {
    final rows = await (_db.select(_db.scanEvents)
          ..where((s) => s.storeId.equals(storeId))
          ..orderBy([(s) => OrderingTerm.desc(s.scannedAt)])
          ..limit(limit))
        .get();
    return rows
        .map(
          (row) => ScanEventModel(
            id: row.id,
            storeId: row.storeId,
            purchaseId: row.purchaseId,
            outcome: row.outcome,
            scannedName: row.scannedName,
            scannedNationalId: row.scannedNationalId,
            scannedAtMillis: row.scannedAt,
          ),
        )
        .toList();
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
          userNationalId: u.nationalId,
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
        userNationalId: u.nationalId,
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
        userNationalId: user.nationalId,
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

  @override
  Future<List<StoreDaySummary>> getDailySummaries(
    int storeId, {
    int limit = 30,
  }) async {
    // One row per day: totals plus the two buckets the owner cares about —
    // handed over, and still outstanding at the end of the day.
    final rows = await _db
        .customSelect(
          'SELECT p.purchase_date AS date, COUNT(*) AS sold, '
          "SUM(CASE WHEN p.status = 'collected' THEN 1 ELSE 0 END) AS collected, "
          "SUM(CASE WHEN p.status IN ('waiting','notified') THEN 1 ELSE 0 END) "
          'AS not_collected '
          'FROM purchases p '
          'WHERE p.store_id = ? '
          'GROUP BY p.purchase_date '
          'ORDER BY p.purchase_date DESC '
          'LIMIT ?',
          variables: [Variable.withInt(storeId), Variable.withInt(limit)],
          readsFrom: {_db.purchases},
        )
        .get();

    return rows
        .map(
          (row) => StoreDaySummary(
            date: row.read<String>('date'),
            sold: row.read<int>('sold'),
            collected: row.read<int>('collected'),
            notCollected: row.read<int>('not_collected'),
          ),
        )
        .toList();
  }
}
