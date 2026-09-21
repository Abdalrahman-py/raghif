import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/widgets/status_chip.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/purchase_screen.dart';
import 'package:raghif/features/queue/queue_logic.dart';

import '../../support/queue_test_harness.dart';

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

void main() {
  const testUser = DemoUser(
    id: seededBuyerId,
    phone: '0599111111',
    pin: '1234',
    role: UserRole.buyer,
    name: 'أحمد محمود',
    jawwalPayNumber: '0599111111',
  );

  group('Strings unit tests', () {
    test('dailyLimitReachedOtherStore handles names with and without bakery prefix', () {
      expect(
        Strings.dailyLimitReachedOtherStore('مخبز الرمال'),
        'لقد قمت بالحجز من مخبز الرمال اليوم بالفعل',
      );
      expect(
        Strings.dailyLimitReachedOtherStore('الشاطئ'),
        'لقد قمت بالحجز من مخبز الشاطئ اليوم بالفعل',
      );
      expect(
        Strings.dailyLimitReachedOtherStore(''),
        'لقد قمت بالحجز من مخبز آخر اليوم بالفعل',
      );
      expect(
        Strings.dailyLimitReachedOtherStore('   '),
        'لقد قمت بالحجز من مخبز آخر اليوم بالفعل',
      );
    });

    test('waitingReassurance is non-empty reassurance text', () {
      expect(Strings.waitingReassurance, isNotEmpty);
      expect(Strings.waitingReassurance, 'سيتم إشعارك عندما يحين دورك');
    });
  });

  group('PurchaseScreen store-detail layout', () {
    testWidgets('renders store detail block and pay button when not blocked', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      final repo = harness.repo;
      final controller = harness.controller;
      final store = (await repo.getStoreById(seededStoreId))!;

      await tester.pumpWidget(
        wrapWithMaterial(
          PurchaseScreen(
            controller: controller,
            storeId: store.id,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Store detail hierarchy
      expect(find.text(store.name), findsOneWidget);
      expect(find.byType(StatusChip), findsOneWidget);
      expect(find.text(Strings.available), findsOneWidget);
      expect(
        find.text(Strings.bagsRemaining(store.bagsRemaining, store.dailyBagLimit)),
        findsOneWidget,
      );

      // Price shown once, on the buy button itself — not as a separate row
      expect(find.text(Strings.priceLabel), findsNothing);
      expect(find.text(Strings.payButton), findsOneWidget);
      expect(find.text(Strings.viewOrder), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('renders soldOut status chip when store has no bags remaining', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      final repo = harness.repo;
      final controller = harness.controller;
      final store = (await repo.getStoreById(seededStoreId))!;

      // Allocation is owner-only server-side, so become the owner to drain
      // the store, then go back to the buyer the screen renders for.
      repo.currentUserId = seededOwnerId;
      await controller.saveAllocation(
        store.id,
        dailyBagLimit: 0,
        batchSize: 20,
        today: todayDateString(),
      );
      repo.currentUserId = seededBuyerId;

      await tester.pumpWidget(
        wrapWithMaterial(
          PurchaseScreen(
            controller: controller,
            storeId: store.id,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(store.name), findsOneWidget);
      expect(find.text(Strings.soldOut), findsOneWidget);
      expect(find.text(Strings.available), findsNothing);
      expect(
        find.text(Strings.bagsRemaining(0, 0)),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('PurchaseScreen blocker handling', () {
    testWidgets('shows dailyLimitReached when blocker matches same store', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      final repo = harness.repo;
      final controller = harness.controller;
      final store = (await repo.getStoreById(seededStoreId))!;

      // Reserve at this store
      await controller.buy(
        storeId: store.id,
        date: todayDateString(),
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          PurchaseScreen(
            controller: controller,
            storeId: store.id,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Store detail block still renders
      expect(find.text(store.name), findsOneWidget);

      // Same store blocker message
      expect(find.text(Strings.dailyLimitReached), findsOneWidget);
      expect(find.text(Strings.viewOrder), findsOneWidget);
      expect(find.text(Strings.payButton), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('shows dailyLimitReachedOtherStore when blocker is from different store', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      final repo = harness.repo;
      final controller = harness.controller;
      final store1 = (await repo.getStoreById(seededStoreId))!;
      final store2 = (await repo.getStoreById('store-shati'))!;

      // Reserve at store 1
      await controller.buy(
        storeId: store1.id,
        date: todayDateString(),
      );

      // Now view purchase screen for store 2
      await tester.pumpWidget(
        wrapWithMaterial(
          PurchaseScreen(
            controller: controller,
            storeId: store2.id,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Store detail block renders store 2's info
      expect(find.text(store2.name), findsOneWidget);

      // Blocker message refers to store 1 (where the user actually reserved)
      final expectedMessage = Strings.dailyLimitReachedOtherStore(store1.name);
      expect(find.text(expectedMessage), findsOneWidget);
      expect(find.text(Strings.dailyLimitReached), findsNothing);

      // Action button is viewOrder, not payButton
      expect(find.text(Strings.viewOrder), findsOneWidget);
      expect(find.text(Strings.payButton), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
