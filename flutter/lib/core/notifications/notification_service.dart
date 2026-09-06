import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications. There's no backend/push
/// infra in this prototype (spec.md: LOCAL-ONLY), so a "notification" is
/// simulated on-device: whatever triggers it (e.g. the owner notifying the
/// next batch) fires a real OS notification directly, standing in for what
/// a push server would send in production.
///
/// No web support: the plugin doesn't back the browser Notification API, so
/// [init]/[showNotification] are no-ops on web rather than throwing.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'queue_notifications';
  static const _channelName = 'إشعارات الطابور';
  static const _channelDescription = 'إشعارات جاهزية الطلب عند إشعار الدفعة';

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
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
