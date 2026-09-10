import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/demo_accounts.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/features/queue/queue_logic.dart';

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl repo;
  late int buyerId;

  Future<int> userIdByNationalId(String nationalId) async {
    final row = await (db.select(db.users)
          ..where((u) => u.nationalId.equals(nationalId)))
        .getSingle();
    return row.id;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = QueueRepositoryImpl(db);
    await repo.ensureSeeded();
    buyerId = await userIdByNationalId(demoBuyerNationalId);
  });

  tearDown(() async {
    await db.close();
  });

  test('fresh install: every store listed with no buyer context', () async {
    final list = await repo
        .watchStoreListForUser(userId: buyerId, today: todayDateString())
        .first;

    expect(list.length, 3);
    expect(list.every((e) => !e.pinned), isTrue);
    expect(list.every((e) => e.todayStatus == null), isTrue);
    expect(list.every((e) => e.lastPurchaseDate == null), isTrue);
    // Areas are seeded so the filter chips have something to show.
    expect(list.every((e) => e.store.area.isNotEmpty), isTrue);
  });

  test('pinning is idempotent and un-pinning clears it', () async {
    final storeId = (await repo.getStores()).first.id;

    Future<bool> pinned() async {
      final list = await repo
          .watchStoreListForUser(userId: buyerId, today: todayDateString())
          .first;
      return list.firstWhere((e) => e.store.id == storeId).pinned;
    }

    await repo.setStorePinned(
      userId: buyerId,
      storeId: storeId,
      pinned: true,
    );
    expect(await pinned(), isTrue);

    // Pinning twice must not fail or duplicate.
    await repo.setStorePinned(
      userId: buyerId,
      storeId: storeId,
      pinned: true,
    );
    expect(await pinned(), isTrue);

    await repo.setStorePinned(
      userId: buyerId,
      storeId: storeId,
      pinned: false,
    );
    expect(await pinned(), isFalse);
  });

  test('a purchase today surfaces as order status + last purchase date',
      () async {
    final store = (await repo.getStores()).first;
    final today = todayDateString();
    await repo.reserveBag(userId: buyerId, storeId: store.id, date: today);

    final list = await repo
        .watchStoreListForUser(userId: buyerId, today: today)
        .first;
    final entry = list.firstWhere((e) => e.store.id == store.id);

    expect(entry.todayStatus, PurchaseStatus.waiting);
    expect(entry.lastPurchaseDate, today);
    expect(entry.awaitingPickup, isTrue);
    // The buyer's other stores stay untouched.
    expect(
      list.where((e) => e.store.id != store.id).every((e) => !e.isFamiliar),
      isTrue,
    );
  });

  test('an old purchase counts as history but not as an order today',
      () async {
    final store = (await repo.getStores()).first;
    await repo.reserveBag(
      userId: buyerId,
      storeId: store.id,
      date: '2026-08-30',
    );

    final list = await repo
        .watchStoreListForUser(userId: buyerId, today: todayDateString())
        .first;
    final entry = list.firstWhere((e) => e.store.id == store.id);

    expect(entry.todayStatus, null);
    expect(entry.lastPurchaseDate, '2026-08-30');
    expect(entry.isFamiliar, isTrue);
  });

  test('pins belong to the buyer, not the store', () async {
    final storeId = (await repo.getStores()).first.id;
    final ownerId = await userIdByNationalId(demoOwnerNationalId);

    await repo.setStorePinned(
      userId: buyerId,
      storeId: storeId,
      pinned: true,
    );

    final ownerList = await repo
        .watchStoreListForUser(userId: ownerId, today: todayDateString())
        .first;
    expect(ownerList.every((e) => !e.pinned), isTrue);
  });
}
