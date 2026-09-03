import 'package:drift/drift.dart';
import '../../core/auth/demo_accounts.dart';
import '../../core/auth/pin_hash.dart';
import '../../core/auth/session_store.dart';
import '../../core/database/app_database.dart';
import '../../core/i18n/strings.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AppDatabase db,
    required SessionStore sessionStore,
  })  : _db = db,
        _sessionStore = sessionStore;

  final AppDatabase _db;
  final SessionStore _sessionStore;

  UserModel _toDomain(User user) {
    return UserModel(
      id: user.id,
      phone: user.phone,
      nationalId: user.nationalId,
      name: user.name,
      role: user.role == 'owner' ? UserRole.owner : UserRole.buyer,
      jawwalPayNumber: user.jawwalPayNumber,
      verificationStatus: user.verificationStatus == 'verified'
          ? VerificationStatus.verified
          : VerificationStatus.pending,
    );
  }

  @override
  Future<void> ensureSeeded() async {
    final anyUser = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
    if (anyUser != null) return;

    await _db.batch((batch) {
      batch.insertAll(_db.users, [
        UsersCompanion.insert(
          phone: demoBuyerPhone,
          nationalId: demoBuyerNationalId,
          pinHash: hashPin(demoBuyerPhone, demoBuyerPin),
          name: demoBuyerName,
          role: const Value('buyer'),
          jawwalPayNumber: const Value('0599000001'),
          verificationStatus: const Value('verified'),
        ),
        UsersCompanion.insert(
          phone: demoOwnerPhone,
          nationalId: demoOwnerNationalId,
          pinHash: hashPin(demoOwnerPhone, demoOwnerPin),
          name: demoOwnerName,
          role: const Value('owner'),
          jawwalPayNumber: const Value('0599000002'),
          verificationStatus: const Value('verified'),
        ),
      ]);
    });
  }

  @override
  Future<UserModel?> login({
    required String phone,
    required String pin,
  }) async {
    final hash = hashPin(phone.trim(), pin.trim());
    final user = await (_db.select(_db.users)
          ..where((u) => u.phone.equals(phone.trim()) & u.pinHash.equals(hash)))
        .getSingleOrNull();

    if (user != null) {
      await _sessionStore.saveUserId(user.id);
      return _toDomain(user);
    }
    return null;
  }

  @override
  Future<UserModel?> loginWithPin({
    required String nationalId,
    required String pin,
  }) async {
    final user = await (_db.select(_db.users)
          ..where((u) => u.nationalId.equals(nationalId.trim())))
        .getSingleOrNull();

    if (user == null) return null;

    final hash = hashPin(user.phone, pin.trim());
    if (user.pinHash == hash) {
      await _sessionStore.saveUserId(user.id);
      return _toDomain(user);
    }
    return null;
  }

  @override
  Future<UserModel?> loginWithOtp({
    required String nationalId,
  }) async {
    final user = await (_db.select(_db.users)
          ..where((u) => u.nationalId.equals(nationalId.trim())))
        .getSingleOrNull();

    if (user != null) {
      await _sessionStore.saveUserId(user.id);
      return _toDomain(user);
    }
    return null;
  }

  @override
  Future<String?> requestOtp(String nationalId) async {
    final user = await (_db.select(_db.users)
          ..where((u) => u.nationalId.equals(nationalId.trim())))
        .getSingleOrNull();

    if (user == null) return null;
    return '4821';
  }

  @override
  Future<UserModel?> findById(int id) async {
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
    return user == null ? null : _toDomain(user);
  }

  @override
  Future<UserModel?> findByNationalId(String nationalId) async {
    final user = await (_db.select(_db.users)
          ..where((u) => u.nationalId.equals(nationalId.trim())))
        .getSingleOrNull();
    return user == null ? null : _toDomain(user);
  }

  @override
  Future<bool> nationalIdExists(String nationalId) async {
    final row = await (_db.select(_db.users)
          ..where((u) => u.nationalId.equals(nationalId.trim())))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<bool> phoneExists(String phone) async {
    final row = await (_db.select(_db.users)
          ..where((u) => u.phone.equals(phone.trim())))
        .getSingleOrNull();
    return row != null;
  }

  @override
  String? validateRegistration({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
    String? jawwalPayNumber,
  }) {
    if (phone.trim().isEmpty ||
        pin.trim().length != 4 ||
        nationalId.trim().isEmpty ||
        name.trim().isEmpty) {
      return Strings.registerError;
    }
    return null;
  }

  @override
  Future<UserModel> register({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
    String? jawwalPayNumber,
  }) async {
    final id = await _db.into(_db.users).insert(
          UsersCompanion.insert(
            phone: phone.trim(),
            nationalId: nationalId.trim(),
            pinHash: hashPin(phone.trim(), pin.trim()),
            name: name.trim(),
            jawwalPayNumber: Value(jawwalPayNumber?.trim()),
            verificationStatus: const Value('pending'),
          ),
        );
    await _sessionStore.saveUserId(id);
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(id)))
        .getSingle();
    return _toDomain(user);
  }

  @override
  Future<void> updateVerificationStatus(
      int userId, VerificationStatus status) async {
    final statusStr = status == VerificationStatus.verified ? 'verified' : 'pending';
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        verificationStatus: Value(statusStr),
      ),
    );
  }

  @override
  Future<void> updateJawwalPayNumber(int userId, String jawwalPayNumber) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        jawwalPayNumber: Value(jawwalPayNumber.trim()),
      ),
    );
  }

  @override
  Future<void> logout() async {
    await _sessionStore.clear();
  }
}
