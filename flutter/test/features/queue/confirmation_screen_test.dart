import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/confirmation_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

void main() {
  const testUser = DemoUser(
    phone: '0599111111',
    pin: '1234',
    role: UserRole.buyer,
    name: 'أحمد محمود',
    jawwalPayNumber: '0599111111',
  );

  group('ConfirmationScreen QR Receipt', () {
    testWidgets('renders QR code and receipt info once purchase is present', (
      tester,
    ) async {
      // Built inside the test body, not setUp() — setUp() runs outside
      // testWidgets' own FakeAsync zone, and a controller/database built
      // there can't reliably deliver .watch() stream data inside the test
      // body (see owner_customers_screen_test.dart for the full story).
      // An explicit, awaited-seed repository is used instead of bare
      // QueueController() — its own no-DI fallback fires ensureSeeded()
      // unawaited, so buy() below could race ahead of the seed data.
      final db = AppDatabase(NativeDatabase.memory());
      final repository = QueueRepositoryImpl(db);
      await repository.ensureSeeded();
      final controller = QueueController(repository);
      final store = controller.stores.first;
      final purchase = await controller.buy(
        userId: testUser.id,
        storeId: store.id,
        date: '2026-09-03',
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          ConfirmationScreen(
            controller: controller,
            purchaseId: purchase.id,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify receipt titles and share/save buttons are visible
      expect(find.text(Strings.receiptQrTitle), findsOneWidget);
      expect(find.text(Strings.receiptQrSubtitle), findsOneWidget);
      expect(find.text(Strings.shareQrButton), findsOneWidget);
      expect(find.text(Strings.saveQrButton), findsOneWidget);

      // Verify QrImageView is rendered
      expect(find.byType(QrImageView), findsOneWidget);

      // Verify reassurance message is displayed and fake estimated time clock is NOT shown
      expect(find.text(Strings.statusWaiting), findsOneWidget);
      expect(find.text(Strings.waitingReassurance), findsOneWidget);
      expect(find.text(Strings.estimatedTime), findsNothing);

      // Verify queue position and batch chips
      expect(find.textContaining(Strings.queuePosition), findsOneWidget);
      expect(find.text(Strings.batchLabel(purchase.batchNumber)), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('shows statusNotified when purchase is notified', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = QueueRepositoryImpl(db);
      await repository.ensureSeeded();
      final controller = QueueController(repository);
      final store = controller.stores.first;
      final purchase = await controller.buy(
        userId: testUser.id,
        storeId: store.id,
        date: '2026-09-03',
      );

      // Transition batch to notified
      await controller.notifyNextBatch(store.id, '2026-09-03');

      await tester.pumpWidget(
        wrapWithMaterial(
          ConfirmationScreen(
            controller: controller,
            purchaseId: purchase.id,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.statusNotified), findsOneWidget);
      expect(find.text(Strings.statusWaiting), findsNothing);
      expect(find.text(Strings.waitingReassurance), findsNothing);
      expect(find.text(Strings.estimatedTime), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty shrink when purchase is not found', (
      tester,
    ) async {
      final controller = QueueController();
      await tester.pumpWidget(
        wrapWithMaterial(
          ConfirmationScreen(
            controller: controller,
            purchaseId: 'non_existent_id',
            currentUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsNothing);
      expect(find.text(Strings.receiptQrTitle), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
