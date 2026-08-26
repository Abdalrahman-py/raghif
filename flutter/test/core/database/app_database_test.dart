import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';

void main() {
  test('schema creates the stores, users and purchases tables', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final storeId = await db.into(db.stores).insert(
      StoresCompanion.insert(
        name: 'Al-Rimal Bakery',
        ownerPhone: '0599000000',
        dailyBagLimit: const Value(300),
        bagsRemaining: const Value(300),
      ),
    );
    final userId = await db.into(db.users).insert(
      UsersCompanion.insert(
        phone: '0599111111',
        nationalId: '900000000',
        pinHash: 'hashed-pin',
      ),
    );
    await db.into(db.purchases).insert(
      PurchasesCompanion.insert(
        storeId: storeId,
        userId: userId,
        purchaseDate: '2026-08-27',
        batchNumber: 1,
        status: 'waiting',
        createdAt: 0,
      ),
    );

    expect(await db.select(db.stores).get(), hasLength(1));
    expect(await db.select(db.users).get(), hasLength(1));
    expect(await db.select(db.purchases).get(), hasLength(1));
  });
}
