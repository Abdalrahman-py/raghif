import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login({
    required String phone,
    required String pin,
  });

  Future<UserModel?> loginWithPin({
    required String nationalId,
    required String pin,
  });

  Future<UserModel?> loginWithOtp({
    required String nationalId,
  });

  Future<String?> requestOtp(String nationalId);

  Future<UserModel?> findById(String id);

  Future<UserModel?> findByNationalId(String nationalId);

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

  Future<void> updateVerificationStatus(String userId, VerificationStatus status);

  Future<void> updateJawwalPayNumber(String userId, String jawwalPayNumber);

  Future<void> logout();
}
