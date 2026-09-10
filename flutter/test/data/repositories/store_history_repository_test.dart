import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/demo_accounts.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl repo;
  late int buyerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = QueueRepositoryImpl(db);
    await repo.ensureSeeded();
    final buyer = await (db.select(db.users)
          ..where((u) => u.nationalId.equals(demoBuyerNationalId)))
        .getSingle();
    buyerId = buyer.id;
  });

  tearDown(() async {
    await db.close();
  });

  test('no purchases → no history days', () async {
    final store = (await repo.getStores()).first;

    expect(await repo.getDailySummaries(store.id), isEmpty);
  });

  test('groups by day and counts collected vs outstanding', () async {
    final store = (await repo.getStores()).first;

    // 2026-08-01: one purchase, left as collected.
    final first = await repo.reserveBag(
      userId: buyerId,
      storeId: store.id,
      date: '2026-08-01',
    );
    await repo.updatePurchaseStatus(first.id, PurchaseStatus.collected);

    // 2026-08-02: one purchase that never got picked up.
    await repo.reserveBag(
      userId: buyerId,
      storeId: store.id,
      date: '2026-08-02',
    );

    final days = await repo.getDailySummaries(store.id);

    expect(days, hasLength(2));
    // Newest day first.
    expect(days.first.date, '2026-08-02');
    expect(days.first.sold, 1);
    expect(days.first.collected, 0);
    expect(days.first.notCollected, 1);
    expect(days.first.everythingCollected, isFalse);

    expect(days.last.date, '2026-08-01');
    expect(days.last.sold, 1);
    expect(days.last.collected, 1);
    expect(days.last.notCollected, 0);
    expect(days.last.everythingCollected, isTrue);
  });

  test('notified rows still count as outstanding', () async {
    final store = (await repo.getStores()).first;
    await repo.reserveBag(
      userId: buyerId,
      storeId: store.id,
      date: '2026-08-03',
    );
    await repo.notifyNextBatch(store.id, '2026-08-03');

    final day = (await repo.getDailySummaries(store.id)).single;
    expect(day.collected, 0);
    expect(day.notCollected, 1);
  });

  test('respects the limit and ignores other stores', () async {
    final stores = await repo.getStores();
    await repo.reserveBag(
      userId: buyerId,
      storeId: stores.first.id,
      date: '2026-08-04',
    );
    await repo.reserveBag(
      userId: buyerId,
      storeId: stores[1].id,
      date: '2026-08-05',
    );

    final firstStoreDays = await repo.getDailySummaries(stores.first.id);
    expect(firstStoreDays.map((d) => d.date), ['2026-08-04']);

    expect(await repo.getDailySummaries(stores.first.id, limit: 0), isEmpty);
  });
}
