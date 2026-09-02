import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the stores, users and purchases tables', () async {
    final storeId = await database.into(database.stores).insert(
      StoresCompanion.insert(
        name: 'Al-Rimal Bakery',
        ownerPhone: '0599000000',
        dailyBagLimit: 300,
        bagsRemaining: 300,
      ),
    );
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        phone: '0599111111',
        nationalId: '900000000',
        pinHash: 'hashed-1234',
        name: 'test user',
      ),
    );

    final purchaseId = await database.into(database.purchases).insert(
      PurchasesCompanion.insert(
        storeId: storeId,
        userId: userId,
        purchaseDate: '2026-08-28',
        batchNumber: 1,
        status: PurchaseStatus.waiting,
        createdAt: 0,
      ),
    );

    final purchase = await (database.select(
      database.purchases,
    )..where((p) => p.id.equals(purchaseId))).getSingle();

    expect(purchase.storeId, storeId);
    expect(purchase.userId, userId);
    expect(purchase.status, PurchaseStatus.waiting);
  });

  test('rejects a second same-day purchase for the same user across different stores', () async {
    final store1Id = await database.into(database.stores).insert(
      StoresCompanion.insert(
        name: 'Al-Rimal Bakery',
        ownerPhone: '0599000000',
        dailyBagLimit: 300,
        bagsRemaining: 300,
      ),
    );
    final store2Id = await database.into(database.stores).insert(
      StoresCompanion.insert(
        name: 'Al-Shati Bakery',
        ownerPhone: '0599000001',
        dailyBagLimit: 300,
        bagsRemaining: 300,
      ),
    );
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        phone: '0599111111',
        nationalId: '900000000',
        pinHash: 'hashed-1234',
        name: 'test user',
      ),
    );

    await database.into(database.purchases).insert(
      PurchasesCompanion.insert(
        storeId: store1Id,
        userId: userId,
        purchaseDate: '2026-08-28',
        batchNumber: 1,
        status: PurchaseStatus.waiting,
        createdAt: 0,
      ),
    );

    expect(
      () => database.into(database.purchases).insert(
        PurchasesCompanion.insert(
          storeId: store2Id,
          userId: userId,
          purchaseDate: '2026-08-28',
          batchNumber: 1,
          status: PurchaseStatus.waiting,
          createdAt: 10,
        ),
      ),
      throwsA(anything),
    );
  });
}
