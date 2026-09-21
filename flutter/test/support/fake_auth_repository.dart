import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] for tests that only need the app to boot.
///
/// Replaces `AuthRepositoryImpl`, which was deleted along with on-device
/// auth: PIN verification is the auth-gateway Edge Function's job now, so
/// there is no local implementation left to instantiate.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.users = const []});

  final List<UserModel> users;

  UserModel? _byNationalId(String nationalId) =>
      users.where((u) => u.nationalId == nationalId).firstOrNull;

  @override
  Future<UserModel?> login({required String phone, required String pin}) async =>
      users.where((u) => u.phone == phone).firstOrNull;

  @override
  Future<UserModel?> loginWithPin({
    required String nationalId,
    required String pin,
  }) async =>
      _byNationalId(nationalId);

  @override
  Future<UserModel?> loginWithOtp({required String nationalId}) async =>
      _byNationalId(nationalId);

  @override
  Future<String?> requestOtp(String nationalId) async =>
      _byNationalId(nationalId) == null ? null : '1234';

  @override
  Future<UserModel?> findById(String id) async =>
      users.where((u) => u.id == id).firstOrNull;

  @override
  Future<UserModel?> findByNationalId(String nationalId) async =>
      _byNationalId(nationalId);

  @override
  Future<bool> nationalIdExists(String nationalId) async =>
      _byNationalId(nationalId) != null;

  @override
  Future<bool> phoneExists(String phone) async =>
      users.any((u) => u.phone == phone);

  @override
  String? validateRegistration({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
    String? jawwalPayNumber,
  }) =>
      null;

  @override
  Future<UserModel> register({
    required String phone,
    required String pin,
    required String nationalId,
    required String name,
    String? jawwalPayNumber,
  }) async =>
      UserModel(
        id: 'user-registered',
        phone: phone,
        nationalId: nationalId,
        name: name,
        jawwalPayNumber: jawwalPayNumber,
      );

  @override
  Future<void> updateVerificationStatus(
    String userId,
    VerificationStatus status,
  ) async {}

  @override
  Future<void> updateJawwalPayNumber(
    String userId,
    String jawwalPayNumber,
  ) async {}

  @override
  Future<void> logout() async {}
}
