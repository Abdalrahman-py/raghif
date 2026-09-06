import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/demo_accounts.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/database/tables/converters.dart';
import 'package:raghif/data/demo_content_seeder.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/features/queue/queue_logic.dart';

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl queueRepo;
  late DemoContentSeeder seeder;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queueRepo = QueueRepositoryImpl(db);
    await queueRepo.ensureSeeded();
    seeder = DemoContentSeeder(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('seeds richer demo content on a fresh base install', () async {
    await seeder.seedIfFresh();

    // 3 base stores + 4 extra = 7.
    final stores = await queueRepo.getStores();
    expect(stores.length, 7);
    expect(stores.map((s) => s.name), contains('مخبز الأمل'));

    // 2 base users + 9 dummy buyers = 11.
    final users = await db.select(db.users).get();
    expect(users.length, 11);
    // The live demo buyer must not be shadowed by a duplicate account.
    final demoBuyerRows = users
        .where((u) => u.nationalId == demoBuyerNationalId)
        .toList();
    expect(demoBuyerRows.length, 1);
  });

  test('seeds today queue at demo store spanning all pickup states', () async {
    await seeder.seedIfFresh();

    final today = todayDateString();
    final demoStore = await queueRepo
        .getStores()
        .then((s) => s.firstWhere((s) => s.ownerPhone == demoOwnerPhone));
    final queue = await queueRepo.getQueueForStore(demoStore.id, today);

    expect(queue.length, 9);
    expect(
      queue.where((p) => p.status == PurchaseStatus.collected).length,
      3,
    );
    expect(
      queue.where((p) => p.status == PurchaseStatus.notified).length,
      3,
    );
    expect(
      queue.where((p) => p.status == PurchaseStatus.waiting).length,
      3,
    );

    // Dynamic batches with demo-store batch size 3: collected = batch 1,
    // notified = batch 2, waiting = batch 3.
    expect(queue[0].batchNumber, 1);
    expect(queue[3].batchNumber, 2);
    expect(queue[6].batchNumber, 3);
  });

  test('live demo buyer has NO seeded purchase today (one-bag rule)', () async {
    await seeder.seedIfFresh();

    final today = todayDateString();
    final demoBuyer = await (db.select(db.users)
          ..where((u) => u.nationalId.equals(demoBuyerNationalId)))
        .getSingle();
    final purchases = await (db.select(db.purchases)
          ..where(
            (p) =>
                p.userId.equals(demoBuyer.id) & p.purchaseDate.equals(today),
          ))
        .get();

    expect(purchases, isEmpty);
  });

  test('is a no-op once demo content exists (idempotent)', () async {
    await seeder.seedIfFresh();
    await seeder.seedIfFresh();

    final stores = await queueRepo.getStores();
    expect(stores.length, 7);
    final users = await db.select(db.users).get();
    expect(users.length, 11);
    final purchases = await db.select(db.purchases).get();
    expect(purchases.length, 9);
  });

  test('is a no-op when purchases already exist (not a fresh install)',
      () async {
    // Simulate an install where a real purchase already happened: the richer
    // seed must not stack demo data on top of it.
    final buyer = await (db.select(db.users)
          ..where((u) => u.nationalId.equals(demoBuyerNationalId)))
        .getSingle();
    final store = (await queueRepo.getStores()).first;
    await queueRepo.reserveBag(
      userId: buyer.id,
      storeId: store.id,
      date: todayDateString(),
    );

    await seeder.seedIfFresh();

    final stores = await queueRepo.getStores();
    expect(stores.length, 3); // unchanged — extras NOT added
    final users = await db.select(db.users).get();
    expect(users.length, 2); // unchanged — dummy buyers NOT added
  });
}
