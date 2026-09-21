import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../core/auth/session_store.dart';
import '../../core/database/app_database.dart';
import '../../core/i18n/strings.dart';
import '../../core/notifications/fcm_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth backed by Supabase (national-ID + PIN, verified server-side by the
/// `auth-gateway` Edge Function, which mints a real Supabase session — see
/// docs/supabase-migration-plan.md).
///
/// The local `users` drift table is kept as a read cache so session restore
/// (`findById`) and profile lookups work offline once a user has signed in
/// on this device at least once — it is not the identity source of truth
/// once this repository is selected. `remote_id` bridges a cached local row
/// to its Supabase `profiles` UUID; `pin_hash` is unused here (a
/// `'supabase-managed'` placeholder satisfies the NOT NULL column) since PIN
/// verification happens server-side via the Edge Function.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient client,
    required AppDatabase db,
    required SessionStore sessionStore,
    FcmService? fcmService,
  })  : _client = client,
        _db = db,
        _sessionStore = sessionStore,
        _fcmService = fcmService;

  static const _placeholderPinHash = 'supabase-managed';

  final SupabaseClient _client;
  final AppDatabase _db;
  final SessionStore _sessionStore;
  final FcmService? _fcmService;

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

  Future<Map<String, dynamic>> _invoke(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final res = await _client.functions.invoke(
      'auth-gateway',
      body: {'action': action, ...payload},
    );
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<UserModel> _applySession(Map<String, dynamic> result) async {
    await _client.auth.setSession(result['refreshToken'] as String);
    final profile = Map<String, dynamic>.from(result['profile'] as Map);
    final nationalId = profile['nationalId'] as String;

    final existing = await (_db.select(_db.users)
          ..where((u) => u.nationalId.equals(nationalId)))
        .getSingleOrNull();

    final fields = UsersCompanion(
      phone: Value(profile['phone'] as String),
      name: Value(profile['name'] as String),
      role: Value(profile['role'] as String? ?? 'buyer'),
      jawwalPayNumber: Value(profile['jawwalPayNumber'] as String?),
      verificationStatus:
          Value(profile['verificationStatus'] as String? ?? 'pending'),
      remoteId: Value(profile['remoteId'] as String?),
    );

    final int localId;
    if (existing != null) {
      localId = existing.id;
      await (_db.update(_db.users)..where((u) => u.id.equals(localId)))
          .write(fields);
    } else {
      localId = await _db.into(_db.users).insert(
            UsersCompanion.insert(
              phone: profile['phone'] as String,
              nationalId: nationalId,
              pinHash: _placeholderPinHash,
              name: profile['name'] as String,
              role: Value(profile['role'] as String? ?? 'buyer'),
              jawwalPayNumber: Value(profile['jawwalPayNumber'] as String?),
              verificationStatus:
                  Value(profile['verificationStatus'] as String? ?? 'pending'),
              remoteId: Value(profile['remoteId'] as String?),
            ),
          );
    }

    await _sessionStore.saveUserId(localId);
    unawaited(_fcmService?.registerCurrentDeviceToken());
    final row =
        await (_db.select(_db.users)..where((u) => u.id.equals(localId)))
            .getSingle();
    return _toDomain(row);
  }

  @override
  Future<void> ensureSeeded() async {
    try {
      await _invoke('seed-demo', {});
    } catch (_) {
      // Best-effort — demo accounts may already exist, or the network may
      // be unreachable (offline first run); either way the app should still
      // start.
    }
  }

  @override
  Future<UserModel?> login({
    required String phone,
    required String pin,
  }) async {
    try {
      final result = await _invoke('login-pin', {
        'identifier': phone.trim(),
        'by': 'phone',
        'pin': pin.trim(),
      });
      return await _applySession(result);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel?> loginWithPin({
    required String nationalId,
    required String pin,
  }) async {
    try {
      final result = await _invoke('login-pin', {
        'identifier': nationalId.trim(),
        'by': 'nationalId',
        'pin': pin.trim(),
      });
      return await _applySession(result);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel?> loginWithOtp({
    required String nationalId,
  }) async {
    try {
      final result =
          await _invoke('otp-confirm', {'nationalId': nationalId.trim()});
      return await _applySession(result);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> requestOtp(String nationalId) async {
    try {
      final result =
          await _invoke('otp-request', {'nationalId': nationalId.trim()});
      return result['otpCode'] as String?;
    } catch (_) {
      return null;
    }
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
    try {
      final result = await _invoke(
        'check-availability',
        {'nationalId': nationalId.trim()},
      );
      return result['nationalIdExists'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> phoneExists(String phone) async {
    try {
      final result = await _invoke(
        'check-availability',
        {'phone': phone.trim()},
      );
      return result['phoneExists'] as bool? ?? false;
    } catch (_) {
      return false;
    }
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
    final result = await _invoke('register', {
      'phone': phone.trim(),
      'pin': pin.trim(),
      'nationalId': nationalId.trim(),
      'name': name.trim(),
      'jawwalPayNumber': jawwalPayNumber?.trim(),
    });
    return _applySession(result);
  }

  @override
  Future<void> updateVerificationStatus(
    int userId,
    VerificationStatus status,
  ) async {
    final statusStr =
        status == VerificationStatus.verified ? 'verified' : 'pending';
    final row = await (_db.select(_db.users)..where((u) => u.id.equals(userId)))
        .getSingleOrNull();
    if (row?.remoteId != null) {
      await _client
          .from('profiles')
          .update({'verification_status': statusStr}).eq('id', row!.remoteId!);
    }
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(verificationStatus: Value(statusStr)),
    );
  }

  @override
  Future<void> updateJawwalPayNumber(
    int userId,
    String jawwalPayNumber,
  ) async {
    final trimmed = jawwalPayNumber.trim();
    final row = await (_db.select(_db.users)..where((u) => u.id.equals(userId)))
        .getSingleOrNull();
    if (row?.remoteId != null) {
      await _client
          .from('profiles')
          .update({'jawwal_pay_number': trimmed}).eq('id', row!.remoteId!);
    }
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(jawwalPayNumber: Value(trimmed)),
    );
  }

  @override
  Future<void> logout() async {
    // Before signOut: the device_tokens RLS policy needs a live session, and
    // a token left behind keeps pushing this user's batch alerts to whoever
    // holds the phone next. Best-effort — a dead connection must never trap
    // someone in a signed-in state they asked to leave.
    try {
      await _fcmService?.unregisterCurrentDeviceToken();
    } catch (_) {
      // ignored: logout proceeds regardless
    }
    await _client.auth.signOut();
    await _sessionStore.clear();
  }
}
