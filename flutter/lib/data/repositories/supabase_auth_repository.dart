import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/strings.dart';
import '../../core/notifications/fcm_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../receipt_store.dart';

/// Auth backed by Supabase (phone number + PIN, verified server-side by the
/// `auth-gateway` Edge Function, which mints a real Supabase session — see
/// docs/supabase-migration-plan.md).
///
/// Who is signed in is Supabase's own persisted session; the profile behind
/// it is read from `profiles` every time. Nothing about the user is kept on
/// the phone, except what the buyer's saved receipt already carries
/// ([ReceiptStore]), which lets an offline restart still reach the receipt.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient client,
    FcmService? fcmService,
    ReceiptStore? receipts,
  }) : _client = client,
       _fcmService = fcmService,
       _receipts = receipts ?? ReceiptStore();

  final SupabaseClient _client;
  final FcmService? _fcmService;
  final ReceiptStore _receipts;

  /// Every profile column the app reads. Named, never `*`: `pin_hash` is
  /// revoked in SQL and asking for it fails the whole request.
  static const _profileColumns = 'id, phone, name, role, verification_status';

  static UserModel _userFromRow(Map<String, dynamic> row) => UserModel(
    id: row['id'] as String,
    phone: (row['phone'] as String?) ?? '',
    name: (row['name'] as String?) ?? '',
    role: row['role'] == 'owner' ? UserRole.owner : UserRole.buyer,
    verificationStatus: row['verification_status'] == 'verified'
        ? VerificationStatus.verified
        : VerificationStatus.pending,
  );

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

  /// A gateway call where the server saying no (401 wrong PIN/code, 404 unknown
  /// number) is an answer, not a failure: null. Anything else -- no connection, a
  /// timeout, a 5xx -- is rethrown, so the caller never reports "wrong PIN" or
  /// "not registered" for a network that never answered.
  Future<T?> _answered<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FunctionException catch (e) {
      if (e.status == 401 || e.status == 404) return null;
      if (e.status == 429) {
        throw const AccountBlockedException('login_locked');
      }
      if (e.status == 403) {
        final details = e.details;
        final reason = details is Map ? details['error'] : null;
        if (reason == 'account_disabled' || reason == 'store_archived') {
          throw AccountBlockedException(reason as String);
        }
      }
      rethrow;
    }
  }

  Future<UserModel> _applySession(Map<String, dynamic> result) async {
    await _client.auth.setSession(result['refreshToken'] as String);
    final profile = Map<String, dynamic>.from(result['profile'] as Map);
    unawaited(_fcmService?.registerCurrentDeviceToken());
    return UserModel(
      id: profile['remoteId'] as String,
      phone: profile['phone'] as String? ?? '',
      name: profile['name'] as String? ?? '',
      role: profile['role'] == 'owner' ? UserRole.owner : UserRole.buyer,
      verificationStatus: profile['verificationStatus'] == 'verified'
          ? VerificationStatus.verified
          : VerificationStatus.pending,
    );
  }

  @override
  Future<UserModel?> login({required String phone, required String pin}) async {
    return _answered(() async {
      final result = await _invoke('login-pin', {
        'phone': phone.trim(),
        'pin': pin.trim(),
      });
      return _applySession(result);
    });
  }

  @override
  Future<UserModel?> restoreSession() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    try {
      return await findById(authUser.id);
    } catch (_) {
      // No signal at startup: a buyer with a saved receipt still gets in, far
      // enough to show it at the bakery. Nobody else does.
      final receipt = await _receipts.load();
      if (receipt == null || receipt.userId != authUser.id) rethrow;
      return UserModel(
        id: receipt.userId,
        phone: receipt.userPhone ?? '',
        name: receipt.userName ?? '',
        verificationStatus: VerificationStatus.verified,
      );
    }
  }

  @override
  Future<UserModel?> findById(String id) async {
    final row = await _client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _userFromRow(row);
  }

  @override
  Future<bool> phoneExists(String phone) async {
    try {
      final result = await _invoke('check-availability', {
        'phone': phone.trim(),
      });
      return result['phoneExists'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  String? validateRegistration({
    required String phone,
    required String pin,
    required String name,
  }) {
    if (phone.trim().isEmpty || pin.trim().length != 4 || name.trim().isEmpty) {
      return Strings.registerError;
    }
    return null;
  }

  @override
  Future<UserModel> register({
    required String phone,
    required String pin,
    required String name,
  }) async {
    final result = await _invoke('register', {
      'phone': phone.trim(),
      'pin': pin.trim(),
      'name': name.trim(),
    });
    return _applySession(result);
  }

  @override
  Future<UserModel?> verifyWallet({required String code}) async {
    final result = await _client.rpc(
      'verify_my_wallet',
      params: {'p_code': code.trim()},
    );
    if (result != 'ok') return null;
    return findById(_client.auth.currentUser!.id);
  }

  @override
  Future<UserModel> updateProfile({required String name}) async {
    final row = await _client
        .rpc('update_my_profile', params: {'p_name': name.trim()})
        .single();
    return _userFromRow(row);
  }

  @override
  Future<ChangePinResult> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final word = await _client.rpc(
      'change_my_pin',
      params: {'p_old': currentPin, 'p_new': newPin},
    );
    return ChangePinResult.fromServer(word as String?);
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
    // signOut() revokes the session on the server, so it throws when the
    // backend is down. Signing out is a local decision first: the local
    // session is dropped regardless, or a dead connection leaves the person
    // pressing "sign out" with nothing happening.
    try {
      await _client.auth.signOut();
    } catch (_) {
      // ignored: the server-side revoke is best effort
    }
    // The receipt carries this buyer's name and phone number.
    await _receipts.clear();
  }
}
