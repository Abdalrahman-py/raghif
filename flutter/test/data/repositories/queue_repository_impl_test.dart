import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl queueRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queueRepo = QueueRepositoryImpl(db);
    await queueRepo.ensureSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureSeeded populates initial 3 stores', () async {
    final stores = await queueRepo.getStores();
    expect(stores.length, 3);
    expect(stores[0].name, 'مخبز الرمال');
  });

  test(
    'ensureSeeded seeds a purchase window for the open demo stores',
    () async {
      final stores = await queueRepo.getStores();
      expect(stores[0].openTime, '08:00');
      expect(stores[0].closeTime, '10:00');
      expect(stores[0].hasPurchaseWindow, isTrue);
      // The closed demo store has no window set yet.
      expect(stores[2].hasPurchaseWindow, isFalse);
    },
  );

  test('saveStoreAllocation persists the purchase window', () async {
    final store = (await queueRepo.getStores()).first;

    await queueRepo.saveStoreAllocation(
      store.id,
      dailyLimit: store.dailyBagLimit,
      batchSize: 20,
      date: '2026-09-02',
      openTime: '09:00',
      closeTime: '11:30',
    );

    final updated = await queueRepo.getStoreById(store.id);
    expect(updated?.openTime, '09:00');
    expect(updated?.closeTime, '11:30');
  });

  test('reserveBag creates purchase and decrements bagsRemaining', () async {
    final userId = await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            phone: '0599123456',
            nationalId: '900123456',
            pinHash: 'hash',
            name: 'أحمد',
          ),
        );

    final stores = await queueRepo.getStores();
    final store = stores.first;
    final initialBags = store.bagsRemaining;

    final purchase = await queueRepo.reserveBag(
      userId: userId,
      storeId: store.id,
      date: '2026-09-02',
    );

    expect(purchase.userId, userId);
    expect(purchase.storeId, store.id);
    expect(purchase.status, PurchaseStatus.waiting);
    expect(purchase.batchNumber, 1);

    final updatedStore = await queueRepo.getStoreById(store.id);
    expect(updatedStore?.bagsRemaining, initialBags - 1);
  });

  test('getBlockingPurchase returns purchase if user reserved today', () async {
    final userId = await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            phone: '0599123456',
            nationalId: '900123456',
            pinHash: 'hash',
            name: 'أحمد',
          ),
        );

    final stores = await queueRepo.getStores();
    await queueRepo.reserveBag(
      userId: userId,
      storeId: stores[0].id,
      date: '2026-09-02',
    );

    final blocking = await queueRepo.getBlockingPurchase(userId, '2026-09-02');
    expect(blocking, isNotNull);
    expect(blocking?.storeId, stores[0].id);

    final noBlockingForTomorrow = await queueRepo.getBlockingPurchase(
      userId,
      '2026-09-03',
    );
    expect(noBlockingForTomorrow, isNull);
  });

  test('notifyNextBatch transitions waiting batch to notified', () async {
    final user1 = await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            phone: '0599111001',
            nationalId: '900000001',
            pinHash: 'hash',
            name: 'مستخدم 1',
          ),
        );
    final user2 = await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            phone: '0599111002',
            nationalId: '900000002',
            pinHash: 'hash',
            name: 'مستخدم 2',
          ),
        );

    final stores = await queueRepo.getStores();
    final storeId = stores.first.id;

    await queueRepo.reserveBag(
      userId: user1,
      storeId: storeId,
      date: '2026-09-02',
    );
    await queueRepo.reserveBag(
      userId: user2,
      storeId: storeId,
      date: '2026-09-02',
    );

    final notifiedFirstCall = await queueRepo.notifyNextBatch(
      storeId,
      '2026-09-02',
    );
    expect(notifiedFirstCall, isTrue);

    final queue = await queueRepo.getQueueForStore(storeId, '2026-09-02');
    expect(queue.length, 2);
    expect(queue[0].status, PurchaseStatus.notified);
    expect(queue[1].status, PurchaseStatus.notified);

    // Nothing left waiting — a second call has nothing to notify.
    final notifiedSecondCall = await queueRepo.notifyNextBatch(
      storeId,
      '2026-09-02',
    );
    expect(notifiedSecondCall, isFalse);
  });

  test(
    'batch grouping is derived from the store\'s current batch size, not '
    'frozen at purchase time',
    () async {
      final stores = await queueRepo.getStores();
      final store = stores.first;
      final date = '2026-09-02';

      Future<int> addBuyer(String phone, String nationalId) => db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              phone: phone,
              nationalId: nationalId,
              pinHash: 'hash',
              name: phone,
            ),
          );

      final user1 = await addBuyer('0599333001', '900111001');
      final user2 = await addBuyer('0599333002', '900111002');

      await queueRepo.reserveBag(userId: user1, storeId: store.id, date: date);
      await queueRepo.reserveBag(userId: user2, storeId: store.id, date: date);

      // Default batch size (20) groups both buyers into one batch.
      var queue = await queueRepo.getQueueForStore(store.id, date);
      expect(queue.map((p) => p.batchNumber), [1, 1]);

      // Dropping batch size to 1 splits the *same already-reserved* buyers
      // into two batches — nothing about them was re-purchased.
      await queueRepo.saveStoreAllocation(
        store.id,
        dailyLimit: store.dailyBagLimit,
        batchSize: 1,
        date: date,
      );
      queue = await queueRepo.getQueueForStore(store.id, date);
      expect(queue.map((p) => p.batchNumber), [1, 2]);

      // Edge case: 5 buyers at batch size 2 split into 3 batches (2, 2, 1).
      for (final n in [3, 4, 5]) {
        final user = await addBuyer('059933300$n', '90011100$n');
        await queueRepo.reserveBag(userId: user, storeId: store.id, date: date);
      }
      await queueRepo.saveStoreAllocation(
        store.id,
        dailyLimit: store.dailyBagLimit,
        batchSize: 2,
        date: date,
      );
      queue = await queueRepo.getQueueForStore(store.id, date);
      expect(queue.map((p) => p.batchNumber), [1, 1, 2, 2, 3]);
    },
  );

  test(
    'getCustomersForStore returns distinct customers aggregated across all dates',
    () async {
      final user1 = await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              phone: '0599222001',
              nationalId: '900000011',
              pinHash: 'hash',
              name: 'عميل 1',
            ),
          );
      final user2 = await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              phone: '0599222002',
              nationalId: '900000012',
              pinHash: 'hash',
              name: 'عميل 2',
            ),
          );

      final stores = await queueRepo.getStores();
      final store1 = stores[0];
      final store2 = stores[1];

      // User 1 buys twice at store 1 across different dates
      await queueRepo.reserveBag(
        userId: user1,
        storeId: store1.id,
        date: '2026-09-01',
      );
      await queueRepo.reserveBag(
        userId: user1,
        storeId: store1.id,
        date: '2026-09-02',
      );

      // User 2 buys once at store 1
      await queueRepo.reserveBag(
        userId: user2,
        storeId: store1.id,
        date: '2026-09-01',
      );

      // User 2 buys at store 2 (should not appear in store 1)
      await queueRepo.reserveBag(
        userId: user2,
        storeId: store2.id,
        date: '2026-09-03',
      );

      final customers = await queueRepo.getCustomersForStore(store1.id);
      expect(customers.length, 2);

      // User 1 had latest purchase on 2026-09-02, should be first
      expect(customers[0].userId, user1);
      expect(customers[0].name, 'عميل 1');
      expect(customers[0].phone, '0599222001');
      expect(customers[0].totalPurchases, 2);
      expect(customers[0].lastPurchaseDate, '2026-09-02');

      // User 2 had purchase on 2026-09-01 at store 1
      expect(customers[1].userId, user2);
      expect(customers[1].name, 'عميل 2');
      expect(customers[1].phone, '0599222002');
      expect(customers[1].totalPurchases, 1);
      expect(customers[1].lastPurchaseDate, '2026-09-01');
    },
  );
}
