import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/data/local/database.dart';
import 'package:raghif/data/local/purchase_status.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('inserts and reads back a store', () async {
    final id = await db
        .into(db.stores)
        .insert(
          StoresCompanion.insert(
            name: 'Al-Rimal Bakery',
            ownerPhone: '0599000000',
            dailyBagLimit: 300,
            bagsRemaining: 300,
          ),
        );

    final store = await (db.select(
      db.stores,
    )..where((s) => s.id.equals(id))).getSingle();

    expect(store.name, 'Al-Rimal Bakery');
    expect(store.isOpen, isFalse);
    expect(store.bagsRemaining, 300);
  });

  test('enforces one purchase per user/store/day and maps status enum', () async {
    final storeId = await db
        .into(db.stores)
        .insert(
          StoresCompanion.insert(
            name: 'Al-Rimal Bakery',
            ownerPhone: '0599000000',
            dailyBagLimit: 300,
            bagsRemaining: 300,
          ),
        );
    final userId = await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            phone: '0599111111',
            nationalId: '900123456',
            pinHash: 'hashed-pin',
          ),
        );

    final purchase = PurchasesCompanion.insert(
      storeId: storeId,
      userId: userId,
      purchaseDate: '2026-08-29',
      batchNumber: 1,
      status: PurchaseStatus.waiting,
      createdAt: DateTime.utc(2026, 8, 28),
    );

    await db.into(db.purchases).insert(purchase);

    final saved = await db.select(db.purchases).getSingle();
    expect(saved.status, PurchaseStatus.waiting);

    await expectLater(
      db.into(db.purchases).insert(purchase),
      throwsA(anything),
    );
  });
}
