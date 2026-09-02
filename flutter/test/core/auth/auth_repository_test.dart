import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/auth_repository.dart';
import 'package:raghif/core/auth/demo_accounts.dart';
import 'package:raghif/core/auth/pin_hash.dart';
import 'package:raghif/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late AuthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AuthRepository(db);
  });

  tearDown(() => db.close());

  test('pin is stored hashed, not in plain text', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    final row = await db.select(db.users).getSingle();
    expect(row.pinHash, isNot('4321'));
    expect(row.pinHash, hashPin('0599123456', '4321'));
  });

  test('ensureSeeded creates the two demo accounts once', () async {
    await repo.ensureSeeded();
    await repo.ensureSeeded();

    final rows = await db.select(db.users).get();
    expect(rows.length, 2);

    final buyer = await repo.findByPhoneAndPin(demoBuyerPhone, demoBuyerPin);
    expect(buyer, isNotNull);
    expect(buyer!.role, 'buyer');

    final owner = await repo.findByPhoneAndPin(demoOwnerPhone, demoOwnerPin);
    expect(owner, isNotNull);
    expect(owner!.role, 'owner');
  });

  test('findByPhoneAndPin rejects a wrong pin', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    expect(await repo.findByPhoneAndPin('0599123456', '0000'), isNull);
    expect(await repo.findByPhoneAndPin('0599123456', '4321'), isNotNull);
  });

  test('phoneExists distinguishes a known phone from an unknown one', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    expect(await repo.phoneExists('0599123456'), isTrue);
    expect(await repo.phoneExists('0599000000'), isFalse);
  });

  test('validateRegistration requires all fields and a 4-digit pin', () {
    expect(
      repo.validateRegistration(
        phone: '0599123456',
        pin: '123',
        nationalId: '900555666',
        name: 'test',
      ),
      isNotNull,
    );
    expect(
      repo.validateRegistration(
        phone: '0599123456',
        pin: '1234',
        nationalId: '900555666',
        name: 'test',
      ),
      isNull,
    );
  });

  test('register creates a buyer that can then log in', () async {
    final created = await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );
    expect(created.role, 'buyer');

    final loggedIn = await repo.findByPhoneAndPin('0599123456', '4321');
    expect(loggedIn?.id, created.id);
  });
}
