import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications. Two callers:
/// on-device triggers (the owner notifying the next batch while the app is
/// open) and [FcmService], which re-shows foreground pushes the OS would
/// otherwise swallow.
///
/// [channelId] is also named in AndroidManifest.xml
/// (`default_notification_channel_id`) and in the `notify-batch` Edge
/// Function's FCM payload, so backgrounded pushes land in this same
/// channel instead of Android's auto-created "Miscellaneous" one. The
/// channel is created eagerly in [init] — the manifest fallback only
/// applies to a channel that already exists.
///
/// No web support: the plugin doesn't back the browser Notification API, so
/// [init]/[showNotification] are no-ops on web rather than throwing.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Must stay in sync with AndroidManifest.xml's
  /// `com.google.firebase.messaging.default_notification_channel_id` and
  /// the `channel_id` in supabase/functions/notify-batch/index.ts.
  static const channelId = 'queue_notifications';
  static const _channelName = 'إشعارات الطابور';
  static const _channelDescription = 'إشعارات جاهزية الطلب عند إشعار الدفعة';

  static const _androidChannel = AndroidNotificationChannel(
    channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Created up front, not lazily on first show: a push that arrives while
    // the app is backgrounded is rendered by the OS, which needs the channel
    // to already exist or it falls back to "Miscellaneous".
    await android?.createNotificationChannel(_androidChannel);

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
}
