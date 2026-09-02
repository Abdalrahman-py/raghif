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

  test('reserveBag creates purchase and decrements bagsRemaining', () async {
    final userId = await db.into(db.users).insert(
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
    final userId = await db.into(db.users).insert(
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

    final noBlockingForTomorrow =
        await queueRepo.getBlockingPurchase(userId, '2026-09-03');
    expect(noBlockingForTomorrow, isNull);
  });

  test('notifyNextBatch transitions waiting batch to notified', () async {
    final user1 = await db.into(db.users).insert(
      UsersCompanion.insert(
        phone: '0599111001',
        nationalId: '900000001',
        pinHash: 'hash',
        name: 'مستخدم 1',
      ),
    );
    final user2 = await db.into(db.users).insert(
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

    await queueRepo.notifyNextBatch(storeId, '2026-09-02');

    final queue = await queueRepo.getQueueForStore(storeId, '2026-09-02');
    expect(queue.length, 2);
    expect(queue[0].status, PurchaseStatus.notified);
    expect(queue[1].status, PurchaseStatus.notified);
  });
}
