import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/payment/mock_jawwal_pay_service.dart';
import 'package:raghif/features/payment/payment_number_screen.dart';
import 'package:raghif/features/queue/confirmation_screen.dart';
import 'package:raghif/features/queue/purchase_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';
import 'package:raghif/features/queue/queue_logic.dart';

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

void main() {
  group('Payment screen sequence', () {
    testWidgets(
      'number-confirm -> OTP screen shows code -> wrong entry shows error and stays put -> correct entry navigates to success',
      (tester) async {
        final service = MockJawwalPayService(initialCode: '7391');

        await tester.pumpWidget(
          wrapWithMaterial(
            PaymentNumberScreen(initialNumber: '0599111111', service: service),
          ),
        );

        // 1. Verify number-confirm screen renders
        expect(find.text(Strings.paymentTitle), findsOneWidget);
        expect(find.text('0599111111'), findsOneWidget);
        expect(find.text(Strings.proceedToOtp), findsOneWidget);

        // 2. Tap proceed to OTP
        await tester.tap(find.text(Strings.proceedToOtp));
        await tester.pumpAndSettle();

        // 3. OTP screen shows the code on-screen
        expect(find.text(Strings.paymentOtpTitle), findsOneWidget);
        expect(find.text(Strings.demoOtpNotification('7391')), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // 4. Enter wrong code and tap confirm payment
        await tester.enterText(find.byType(TextField), '0000');
        await tester.tap(find.text(Strings.confirmPaymentButton));
        await tester.pumpAndSettle();

        // Verify wrong entry shows an error and stays on OTP screen
        expect(find.text(Strings.wrongOtpError), findsOneWidget);
        expect(find.text(Strings.paymentOtpTitle), findsOneWidget);
        expect(find.text(Strings.paymentSuccessTitle), findsNothing);

        // 5. Tap resend code — verifies same code is retained and error is cleared
        await tester.tap(find.text(Strings.resendCodeButton));
        await tester.pumpAndSettle();
        expect(find.text(Strings.demoOtpNotification('7391')), findsOneWidget);
        expect(find.text(Strings.wrongOtpError), findsNothing);

        // 6. Enter correct code and tap confirm payment
        await tester.enterText(find.byType(TextField), '7391');
        await tester.tap(find.text(Strings.confirmPaymentButton));
        await tester.pumpAndSettle();

        // 7. Verify navigation to success screen
        expect(
          find.text(Strings.paymentSuccessTitle),
          findsNWidgets(2),
        ); // AppBar + body
        expect(find.text(Strings.completeReservationButton), findsOneWidget);
      },
    );

    testWidgets('Number screen validation rejects empty phone number', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterial(const PaymentNumberScreen(initialNumber: '')),
      );

      await tester.tap(find.text(Strings.proceedToOtp));
      await tester.pumpAndSettle();

      expect(find.text(Strings.registerError), findsOneWidget);
      expect(find.text(Strings.paymentOtpTitle), findsNothing);
    });
  });

  group('PurchaseScreen Jawwal Pay integration', () {
    late AppDatabase db;
    late QueueController controller;
    const testUser = DemoUser(
      phone: '0599111111',
      pin: '1234',
      role: UserRole.buyer,
      name: 'أحمد ناصر',
      jawwalPayNumber: '0599111111',
    );

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final repository = QueueRepositoryImpl(db);
      await repository.ensureSeeded();
      controller = QueueController(repository);
    });

    tearDown(() async {
      controller.dispose();
      await db.close();
    });

    testWidgets(
      'tapping buy pushes payment flow; completing payment creates reservation',
      (tester) async {
        final store = controller.stores.first;

        await tester.pumpWidget(
          wrapWithMaterial(
            PurchaseScreen(
              controller: controller,
              storeId: store.id,
              currentUser: testUser,
            ),
          ),
        );

        // Verify on PurchaseScreen
        expect(find.text(Strings.purchaseTitle), findsOneWidget);
        expect(find.text(Strings.payButton), findsOneWidget);

        // Tap "ادفع 3 شيكل"
        await tester.tap(find.text(Strings.payButton));
        await tester.pumpAndSettle();

        // Pushed number confirm screen
        expect(find.text(Strings.paymentTitle), findsOneWidget);
        expect(find.text(Strings.proceedToOtp), findsOneWidget);

        // Tap proceed to OTP
        await tester.tap(find.text(Strings.proceedToOtp));
        await tester.pumpAndSettle();

        expect(find.text(Strings.paymentOtpTitle), findsOneWidget);

        // Find the generated OTP from the notification banner text
        final bannerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('رمز التحقق (رسالة تجريبية): ') ?? false),
        );
        expect(bannerFinder, findsOneWidget);
        final bannerText = (tester.widget(bannerFinder) as Text).data!;
        final otp = bannerText.split(': ').last.trim();

        // Enter OTP and confirm
        await tester.enterText(find.byType(TextField), otp);
        await tester.tap(find.text(Strings.confirmPaymentButton));
        await tester.pumpAndSettle();

        // Landed on PaymentSuccessScreen
        expect(find.text(Strings.completeReservationButton), findsOneWidget);

        // Tap complete reservation
        await tester.tap(find.text(Strings.completeReservationButton));
        // Pump to trigger pop cascade and the _pay() delayed future
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        // Verify that the reservation was created and we are now on ConfirmationScreen
        expect(find.byType(ConfirmationScreen), findsOneWidget);
        expect(find.text(Strings.confirmationTitle), findsOneWidget);

        // Verify reservation exists in QueueController
        final blocker = await controller.blockingPurchaseFor(
          testUser.phone,
          store.id,
          todayDateString(),
        );
        expect(blocker, isNotNull);

        // Unmount here (not via addTearDown, which runs after Flutter's
        // own end-of-test invariant check) so PurchaseScreen/ConfirmationScreen's
        // drift .watch() subscriptions cancel — and their internal cleanup
        // Timer fires via the follow-up pump() — before that check runs.
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );

    testWidgets('canceling payment flow does not create reservation', (
      tester,
    ) async {
      final store = controller.stores.first;

      await tester.pumpWidget(
        wrapWithMaterial(
          PurchaseScreen(
            controller: controller,
            storeId: store.id,
            currentUser: testUser,
          ),
        ),
      );

      // Tap "ادفع 3 شيكل"
      await tester.tap(find.text(Strings.payButton));
      await tester.pumpAndSettle();

      // On number screen, tap back
      await tester.tap(find.text(Strings.back));
      await tester.pumpAndSettle();

      // Back on PurchaseScreen
      expect(find.text(Strings.purchaseTitle), findsOneWidget);

      // Verify NO purchase was made
      final blocker = await controller.blockingPurchaseFor(
        testUser.phone,
        store.id,
        todayDateString(),
      );
      expect(blocker, isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
