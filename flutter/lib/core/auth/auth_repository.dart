import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../i18n/strings.dart';
import 'demo_accounts.dart';
import 'pin_hash.dart';

/// Phone + national ID + PIN registration/login against the local `users`
/// table (spec.md). Mirrors app/.../data/Registration.kt + AppDatabase.kt's
/// demo seeding, but with the PIN hashed before it ever reaches the db.
class AuthRepository {
  AuthRepository(this._db);

  final AppDatabase _db;

  /// Seeds the two demo accounts on first run, mirroring
  /// AppDatabase.ensureSeeded in the Kotlin prototype. No-op once any user
  /// exists.
  Future<void> ensureSeeded() async {
    final anyUser = await (_db.select(
      _db.users,
    )..limit(1)).getSingleOrNull();
    if (anyUser != null) return;
    await _db.batch((batch) {
      batch.insertAll(_db.users, [
        UsersCompanion.insert(
          phone: demoBuyerPhone,
          nationalId: demoBuyerNationalId,
          pinHash: hashPin(demoBuyerPhone, demoBuyerPin),
          name: demoBuyerName,
          role: const Value('buyer'),
        ),
        UsersCompanion.insert(
          phone: demoOwnerPhone,
          nationalId: demoOwnerNationalId,
          pinHash: hashPin(demoOwnerPhone, demoOwnerPin),
          name: demoOwnerName,
          role: const Value('owner'),
        ),
      ]);
    });
  }

  Future<User?> findByPhoneAndPin(String phone, String pin) {
    final hash = hashPin(phone, pin);
    return (_db.select(
      _db.users,
    )..where((u) => u.phone.equals(phone) & u.pinHash.equals(hash))).getSingleOrNull();
  }

  Future<bool> phoneExists(String phone) async {
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.phone.equals(phone))).getSingleOrNull();
    return row != null;
  }

  /// Returns an error message when registration fields are invalid, null
  /// when OK. Mirrors Registration.kt's validateRegistration.
  String? validateRegistration({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
  }) {
    if (phone.trim().isEmpty ||
        pin.length != 4 ||
        nationalId.trim().isEmpty ||
        name.trim().isEmpty) {
      return Strings.registerError;
    }
    return null;
  }

  /// Creates a new buyer account (registration is buyer-only, matching
  /// Registration.kt's newBuyer — owners are seeded, not self-registered).
  Future<User> register({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
  }) async {
    final id = await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            phone: phone.trim(),
            nationalId: nationalId.trim(),
            pinHash: hashPin(phone.trim(), pin.trim()),
            name: name.trim(),
          ),
        );
    return (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingle();
  }
}
