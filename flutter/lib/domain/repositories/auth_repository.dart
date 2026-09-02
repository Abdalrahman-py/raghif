import '../models/user_model.dart';

abstract class AuthRepository {
  Future<void> ensureSeeded();

  Future<UserModel?> login({
    required String phone,
    required String pin,
  });

  Future<UserModel?> findById(int id);

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

  Future<void> updateVerificationStatus(int userId, VerificationStatus status);

  Future<void> updateJawwalPayNumber(int userId, String jawwalPayNumber);

  Future<void> logout();
}
