import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:raghif/core/i18n/strings.dart';
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

  late QueueController controller;

  setUp(() {
    controller = QueueController();
  });

  group('ConfirmationScreen QR Receipt', () {
    testWidgets('renders QR code and receipt info once purchase is present', (
      tester,
    ) async {
      final store = controller.stores.first;
      final purchase = controller.buy(
        userId: testUser.phone,
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

      // Verify receipt titles and share button are visible
      expect(find.text(Strings.receiptQrTitle), findsOneWidget);
      expect(find.text(Strings.receiptQrSubtitle), findsOneWidget);
      expect(find.text(Strings.shareQrButton), findsOneWidget);

      // Verify QrImageView is rendered
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('renders empty shrink when purchase is not found', (
      tester,
    ) async {
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
    });
  });
}
