import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/cache/offline_cache.dart';
import 'package:raghif/core/connectivity/connectivity_banner.dart';
import 'package:raghif/core/connectivity/connectivity_monitor.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/features/queue/queue_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_queue_repository.dart';
import '../support/queue_test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the monitor follows what the probe says', () async {
    var reachable = true;
    final monitor = ConnectivityMonitor(probe: () async => reachable);
    await monitor.check();
    expect(monitor.online.value, isTrue);
    reachable = false;
    await monitor.check();
    expect(monitor.online.value, isFalse);
    reachable = true;
    await monitor.check();
    expect(monitor.online.value, isTrue);
    monitor.dispose();
  });

  test('a probe that throws counts as offline', () async {
    final monitor = ConnectivityMonitor(probe: () async => throw Exception());
    await monitor.check();
    expect(monitor.online.value, isFalse);
    monitor.dispose();
  });

  testWidgets('the bar shows offline, then "back" for a moment', (
    tester,
  ) async {
    final monitor = ConnectivityMonitor(probe: () async => true);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: ConnectivityBanner(
            monitor: monitor,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(find.text(Strings.connectionOffline), findsNothing);

    monitor.online.value = false;
    await tester.pumpAndSettle();
    expect(find.text(Strings.connectionOffline), findsOneWidget);

    monitor.online.value = true;
    await tester.pump();
    expect(find.text(Strings.connectionRestored), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(Strings.connectionRestored), findsNothing);
    expect(find.text(Strings.connectionOffline), findsNothing);
  });

  test('an owner with no signal still reaches the saved bakery', () async {
    final repo = FakeQueueRepository.seeded()..currentUserId = seededOwnerId;
    final controller = QueueController(repo, OfflineCache());

    final live = await controller.storeForOwner(seededOwnerId);
    expect(live, isNotNull);
    await Future<void>.delayed(Duration.zero);

    repo.online = false;
    final offline = await controller.storeForOwner(seededOwnerId);
    expect(offline?.id, live!.id);

    // No saved copy for someone else: the error still surfaces.
    expect(controller.storeForOwner('nobody'), throwsA(anything));
    controller.dispose();
    repo.dispose();
  });
}
