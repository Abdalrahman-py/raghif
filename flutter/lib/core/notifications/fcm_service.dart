import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Registers this device's FCM token with Supabase (`device_tokens`) and
/// surfaces incoming pushes while the app is foregrounded — backgrounded/
/// killed delivery is shown by the OS directly from the FCM `notification`
/// payload (see the `notify-batch` Edge Function), no extra code needed for
/// that. Only meaningful behind `Env.useSupabase`: `device_tokens` and the
/// notify-batch trigger both live server-side. See
/// docs/supabase-migration-plan.md Phase 4.
///
/// ponytail: web is skipped (`kIsWeb` guard) — web push needs a VAPID key
/// and service worker this pass doesn't set up; the app is Android-first
/// per spec.md.
class FcmService {
  FcmService(this._client);

  final SupabaseClient _client;
  bool _listenersAttached = false;

  Future<void> init() async {
    if (kIsWeb) return;

    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await registerCurrentDeviceToken();

    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      registerCurrentDeviceToken();
    });

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      NotificationService.instance.showNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
      );
    });
  }

  /// Upserts the current device's FCM token for the signed-in user. Safe to
  /// call with no session (no-ops) — called again on every login so a token
  /// obtained before sign-in still gets attached to the right user.
  Future<void> registerCurrentDeviceToken() async {
    if (kIsWeb) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'fcm_token': token,
        'platform': defaultTargetPlatform.name,
      },
      onConflict: 'user_id,fcm_token',
    );
  }

  /// Detaches this device's token from the signed-in user. Must run *before*
  /// `auth.signOut()`: the `device_tokens` RLS policy is `auth.uid() =
  /// user_id`, so the delete silently matches nothing once the session is
  /// gone — leaving the handset subscribed to the previous user's batch
  /// pushes, which matters when a phone is shared between buyers.
  Future<void> unregisterCurrentDeviceToken() async {
    if (kIsWeb) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _client
        .from('device_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('fcm_token', token);
  }
}
