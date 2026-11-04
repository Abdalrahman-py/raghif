import '../models/user_model.dart';

/// The server answered the sign-in, but this account may not use the app right
/// now: an administrator disabled it, or its bakery was archived. Not a wrong
/// PIN and not a network failure, so it gets its own message.
class AccountBlockedException implements Exception {
  const AccountBlockedException(this.reason);

  /// `account_disabled`, `store_archived` or `login_locked` (too many wrong
  /// PINs; what the gateway sends).
  final String reason;

  @override
  String toString() => 'AccountBlockedException($reason)';
}

/// What the server said to a PIN change (`change_my_pin`).
enum ChangePinResult {
  ok,
  wrongPin,
  locked,
  weakPin,
  invalidPin,
  samePin,
  notAllowed;

  /// The server's status word -> result. Anything unrecognized is treated as
  /// not allowed rather than as success.
  static ChangePinResult fromServer(String? word) => switch (word) {
    'ok' => ok,
    'wrong_pin' => wrongPin,
    'locked' => locked,
    'weak_pin' => weakPin,
    'invalid_pin' => invalidPin,
    'same_pin' => samePin,
    _ => notAllowed,
  };
}

abstract class AuthRepository {
  Future<UserModel?> login({required String phone, required String pin});

  Future<UserModel?> loginWithPin({
    required String nationalId,
    required String pin,
  });

  /// The signed-in user from the persisted Supabase session, with their
  /// profile read from the server; null when nobody is signed in.
  Future<UserModel?> restoreSession();

  Future<UserModel?> findById(String id);

  Future<bool> nationalIdExists(String nationalId);

  Future<bool> phoneExists(String phone);

  String? validateRegistration({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
    String? jawwalPayNumber,
  });

  Future<UserModel> register({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
    String? jawwalPayNumber,
  });

  Future<void> updateVerificationStatus(
    String userId,
    VerificationStatus status,
  );

  Future<void> updateJawwalPayNumber(String userId, String jawwalPayNumber);

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String jawwalPayNumber,
  });

  /// An owner replaces their own PIN. Checked on the server: the current PIN
  /// must be right, five misses lock it for 15 minutes, and trivial PINs are
  /// refused. Throws when the server could not be reached.
  Future<ChangePinResult> changePin({
    required String currentPin,
    required String newPin,
  });

  Future<void> logout();
}
