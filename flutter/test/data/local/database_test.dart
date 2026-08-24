import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/data/local/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('stores round-trips through the generated table API', () async {
    final id = await database.into(database.stores).insert(
      StoresCompanion.insert(
        name: 'Al-Rimal Bakery',
        ownerPhone: '0599000000',
        isOpen: true,
        dailyBagLimit: 50,
        bagsRemaining: 50,
      ),
    );

    final store = await (database.select(
      database.stores,
    )..where((s) => s.id.equals(id))).getSingle();

    expect(store.name, 'Al-Rimal Bakery');
    expect(store.isOpen, isTrue);
    expect(store.bagsRemaining, 50);
  });

  test('purchases enforce one active purchase per user/store/day', () async {
    final storeId = await database
        .into(database.stores)
        .insert(
          StoresCompanion.insert(
            name: 'Al-Rimal Bakery',
            ownerPhone: '0599000000',
            isOpen: true,
            dailyBagLimit: 50,
            bagsRemaining: 50,
          ),
        );
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        phone: '0599111111',
        nationalId: '900000000',
        pinHash: 'hashed',
      ),
    );
    final purchaseDate = DateTime.utc(2026, 8, 24);

    await database.into(database.purchases).insert(
      PurchasesCompanion.insert(
        storeId: storeId,
        userId: userId,
        purchaseDate: purchaseDate,
        batchNumber: 1,
        status: 'waiting',
        createdAt: DateTime.utc(2026, 8, 24, 8),
      ),
    );

    expect(
      () => database.into(database.purchases).insert(
        PurchasesCompanion.insert(
          storeId: storeId,
          userId: userId,
          purchaseDate: purchaseDate,
          batchNumber: 2,
          status: 'waiting',
          createdAt: DateTime.utc(2026, 8, 24, 9),
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
