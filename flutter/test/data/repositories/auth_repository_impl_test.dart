import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/demo_accounts.dart';
import 'package:raghif/core/auth/pin_hash.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/repositories/auth_repository_impl.dart';
import 'package:raghif/domain/models/user_model.dart';

void main() {
  late AppDatabase db;
  late AuthRepositoryImpl repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    repo = AuthRepositoryImpl(db: db, sessionStore: SessionStore());
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

    final buyer = await repo.login(phone: demoBuyerPhone, pin: demoBuyerPin);
    expect(buyer, isNotNull);
    expect(buyer!.role, UserRole.buyer);

    final owner = await repo.login(phone: demoOwnerPhone, pin: demoOwnerPin);
    expect(owner, isNotNull);
    expect(owner!.role, UserRole.owner);
  });

  test('login rejects a wrong pin', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    expect(await repo.login(phone: '0599123456', pin: '0000'), isNull);
    expect(await repo.login(phone: '0599123456', pin: '4321'), isNotNull);
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

  test('register creates a buyer, pending verification, that can then log in', () async {
    final created = await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
      jawwalPayNumber: '0599123456',
    );
    expect(created.role, UserRole.buyer);
    expect(created.verificationStatus, VerificationStatus.pending);
    expect(created.jawwalPayNumber, '0599123456');

    final loggedIn = await repo.login(phone: '0599123456', pin: '4321');
    expect(loggedIn?.id, created.id);
  });

  test('updateVerificationStatus flips a user to verified', () async {
    final created = await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    await repo.updateVerificationStatus(created.id, VerificationStatus.verified);

    final user = await repo.findById(created.id);
    expect(user?.verificationStatus, VerificationStatus.verified);
  });

  test('loginWithPin authenticates using national ID and salts with user phone', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    // Correct national ID and PIN
    final user = await repo.loginWithPin(nationalId: '900555666', pin: '4321');
    expect(user, isNotNull);
    expect(user!.nationalId, '900555666');
    expect(user.phone, '0599123456');

    // Wrong PIN
    expect(await repo.loginWithPin(nationalId: '900555666', pin: '0000'), isNull);

    // Non-existent national ID
    expect(await repo.loginWithPin(nationalId: '900999999', pin: '4321'), isNull);
  });

  test('nationalIdExists distinguishes known from unknown national ID', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    expect(await repo.nationalIdExists('900555666'), isTrue);
    expect(await repo.nationalIdExists('900999999'), isFalse);
  });

  test('findByNationalId returns user model or null', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    final found = await repo.findByNationalId('900555666');
    expect(found, isNotNull);
    expect(found!.phone, '0599123456');

    expect(await repo.findByNationalId('900999999'), isNull);
  });

  test('requestOtp returns demo OTP for registered user, null otherwise', () async {
    await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    final otp = await repo.requestOtp('900555666');
    expect(otp, isNotNull);
    expect(otp, '4821');

    expect(await repo.requestOtp('900999999'), isNull);
  });

  test('loginWithOtp completes login and sets session for registered user', () async {
    final registered = await repo.register(
      phone: '0599123456',
      pin: '4321',
      nationalId: '900555666',
      name: 'test user',
    );

    final user = await repo.loginWithOtp(nationalId: '900555666');
    expect(user, isNotNull);
    expect(user!.id, registered.id);

    expect(await repo.loginWithOtp(nationalId: '900999999'), isNull);
  });
}
