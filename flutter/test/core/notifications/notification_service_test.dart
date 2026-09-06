import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/notifications/notification_service.dart';

void main() {
  test('showNotification is a no-op before init() (never throws)', () async {
    // Regression check for the guard in showNotification/init: a caller
    // that never initialized the plugin (e.g. a widget test that builds a
    // QueueController without going through initDependencies()) must not
    // crash when an action tries to fire a notification.
    await NotificationService.instance.showNotification(
      title: 'title',
      body: 'body',
    );
  });
}
