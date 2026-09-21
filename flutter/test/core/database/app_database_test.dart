import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';

/// Since v8 this database is a cache of Supabase, not a source of truth, so
/// there is nothing here about sold-out or batch assignment any more —
/// Postgres owns those and `test/support/fake_queue_repository.dart` stands
/// in for them. What still matters locally is that the mirror is shaped
/// like the server and refuses rows the server would also refuse.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertStore(String id) => db.into(db.stores).insert(
        StoresCompanion.insert(id: id, name: 'مخبز $id'),
      );

  Future<void> insertUser(String id) => db.into(db.users).insert(
        UsersCompanion.insert(id: id, name: Value('بائع $id')),
      );

  test('creates the mirrored tables', () async {
    expect(await db.select(db.stores).get(), isEmpty);
    expect(await db.select(db.users).get(), isEmpty);
    expect(await db.select(db.purchases).get(), isEmpty);
    expect(await db.select(db.scanEvents).get(), isEmpty);
    expect(await db.select(db.storePins).get(), isEmpty);
  });

  test('ids are the Supabase UUIDs, stored verbatim', () async {
    const uuid = '3cafeb25-4823-433d-b461-e7884c6c34c2';
    await insertStore(uuid);
    final row = await db.select(db.stores).getSingle();
    expect(row.id, uuid);
  });

  test('rejects a second same-day purchase for one buyer', () async {
    // Mirrors purchases_user_id_purchase_date_key server-side. The cache
    // enforcing it too means a stale pull can't quietly produce a state the
    // server would never have allowed.
    await insertStore('store-a');
    await insertStore('store-b');
    await insertUser('user-1');

    await db.into(db.purchases).insert(
          PurchasesCompanion.insert(
            id: 'purchase-1',
            storeId: 'store-a',
            userId: 'user-1',
            purchaseDate: '2026-09-21',
            status: PurchaseStatus.waiting,
            createdAt: 1,
          ),
        );

    expect(
      () => db.into(db.purchases).insert(
            PurchasesCompanion.insert(
              id: 'purchase-2',
              storeId: 'store-b',
              userId: 'user-1',
              purchaseDate: '2026-09-21',
              status: PurchaseStatus.waiting,
              createdAt: 2,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('batch_number is stored, not derived', () async {
    // The old schema derived a batch from queue position at read time,
    // which is how a receipt could say batch 4 while Postgres said 1. The
    // server assigns it now and the cache just keeps the number.
    await insertStore('store-a');
    await insertUser('user-1');
    await db.into(db.purchases).insert(
          PurchasesCompanion.insert(
            id: 'purchase-1',
            storeId: 'store-a',
            userId: 'user-1',
            purchaseDate: '2026-09-21',
            batchNumber: const Value(4),
            status: PurchaseStatus.waiting,
            createdAt: 1,
          ),
        );
    final row = await db.select(db.purchases).getSingle();
    expect(row.batchNumber, 4);
  });

  test('holds no credential material', () async {
    // pin_hash used to live here. PIN verification is the auth-gateway
    // Edge Function's job, and a cache has no business storing hashes.
    final columns = db.users.$columns.map((c) => c.name).toList();
    expect(columns, isNot(contains('pin_hash')));
  });
}
