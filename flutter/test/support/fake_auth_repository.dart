import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] for tests that only need the app to boot.
///
/// Replaces `AuthRepositoryImpl`, which was deleted along with on-device
/// auth: PIN verification is the auth-gateway Edge Function's job now, so
/// there is no local implementation left to instantiate.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.users = const [],
    this.failWith,
    this.sessionUserId,
  });

  final List<UserModel> users;

  /// Who the persisted Supabase session belongs to at startup, if anyone.
  String? sessionUserId;

  /// When set, sign-in calls throw it: a call that never got an answer
  /// (no connection), as opposed to a server that said no.
  final Object? failWith;

  /// When set, [login] refuses (answers "no") any other PIN.
  String? requiredPin;

  /// What [changePin] answers, and what it was last asked.
  ChangePinResult changePinResult = ChangePinResult.ok;
  ({String currentPin, String newPin})? lastPinChange;

  @override
  Future<ChangePinResult> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (failWith != null) throw failWith!;
    lastPinChange = (currentPin: currentPin, newPin: newPin);
    return changePinResult;
  }

  @override
  Future<UserModel?> login({required String phone, required String pin}) async {
    if (failWith != null) throw failWith!;
    if (requiredPin != null && pin != requiredPin) return null;
    return users.where((u) => u.phone == phone).firstOrNull;
  }

  @override
  Future<UserModel?> restoreSession() async {
    if (sessionUserId == null) return null;
    if (failWith != null) throw failWith!;
    return findById(sessionUserId!);
  }

  @override
  Future<UserModel?> findById(String id) async => _updatedUser?.id == id
      ? _updatedUser
      : users.where((u) => u.id == id).firstOrNull;

  @override
  Future<bool> phoneExists(String phone) async =>
      users.any((u) => u.phone == phone);

  @override
  String? validateRegistration({
    required String phone,
    required String pin,
    required String name,
  }) => null;

  @override
  Future<UserModel> register({
    required String phone,
    required String pin,
    required String name,
  }) async => UserModel(id: 'user-registered', phone: phone, name: name);

  @override
  Future<UserModel?> verifyWallet({required String code}) async {
    if (code != '1234') return null;
    final current = await restoreSession();
    if (current == null) return null;
    return current.copyWith(verificationStatus: VerificationStatus.verified);
  }

  @override
  Future<UserModel> updateProfile({required String name}) async {
    if (failWith != null) throw failWith!;
    final current = await restoreSession();
    if (current == null) throw StateError('Not signed in');
    final updated = current.copyWith(name: name.trim());
    _updatedUser = updated;
    return updated;
  }

  UserModel? _updatedUser;

  @override
  Future<void> logout() async => sessionUserId = null;
}
