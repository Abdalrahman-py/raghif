import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/payment/mock_jawwal_pay_service.dart';
import 'package:raghif/features/payment/payment_number_screen.dart';
import 'package:raghif/features/queue/confirmation_screen.dart';
import 'package:raghif/features/queue/purchase_flow.dart';
import 'package:raghif/features/queue/queue_logic.dart';

import '../../support/queue_test_harness.dart';

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
        await tester.ensureVisible(find.text(Strings.proceedToOtp));
        await tester.tap(find.text(Strings.proceedToOtp));
        await tester.pumpAndSettle();

        // 3. OTP screen shows the code on-screen
        expect(find.text(Strings.paymentOtpTitle), findsOneWidget);
        expect(find.text(Strings.demoOtpNotification('7391')), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // 4. Enter wrong code and tap confirm payment
        await tester.enterText(find.byType(TextField), '0000');
        await tester.ensureVisible(find.text(Strings.confirmPaymentButton));
        await tester.tap(find.text(Strings.confirmPaymentButton));
        await tester.pumpAndSettle();

        // Verify wrong entry shows an error and stays on OTP screen
        expect(find.text(Strings.wrongOtpError), findsOneWidget);
        expect(find.text(Strings.paymentOtpTitle), findsOneWidget);
        expect(find.text(Strings.paymentSuccessTitle), findsNothing);

        // 5. Tap resend code — verifies same code is retained and error is cleared
        await tester.ensureVisible(find.text(Strings.resendCodeButton));
        await tester.tap(find.text(Strings.resendCodeButton));
        await tester.pumpAndSettle();
        expect(find.text(Strings.demoOtpNotification('7391')), findsOneWidget);
        expect(find.text(Strings.wrongOtpError), findsNothing);

        // 6. Enter correct code and tap confirm payment
        await tester.enterText(find.byType(TextField), '7391');
        await tester.ensureVisible(find.text(Strings.confirmPaymentButton));
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

      await tester.ensureVisible(find.text(Strings.proceedToOtp));

      await tester.tap(find.text(Strings.proceedToOtp));
      await tester.pumpAndSettle();

      expect(find.text(Strings.registerError), findsOneWidget);
      expect(find.text(Strings.paymentOtpTitle), findsNothing);
    });
  });

  group('Buying a bag: reserve first, then choose payment', () {
    const testUser = DemoUser(
      id: seededBuyerId,
      phone: '0599111111',
      pin: '1234',
      role: UserRole.buyer,
      name: 'أحمد ناصر',
    );

    Widget launcher(controller, String storeId) => wrapWithMaterial(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => startPurchase(
                context,
                controller: controller,
                currentUser: testUser,
                storeId: storeId,
              ),
              child: const Text('buy'),
            ),
          ),
        ),
      ),
    );

    /// Number screen -> OTP -> success -> back to the flow.
    Future<void> payThroughWallet(WidgetTester tester) async {
      await tester.ensureVisible(find.text(Strings.proceedToOtp));
      await tester.tap(find.text(Strings.proceedToOtp));
      await tester.pumpAndSettle();
      final bannerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('رمز التحقق (رسالة تجريبية): ') ?? false),
      );
      final otp = (tester.widget(bannerFinder) as Text).data!
          .split(': ')
          .last
          .trim();
      await tester.enterText(find.byType(TextField), otp);
      await tester.ensureVisible(find.text(Strings.confirmPaymentButton));
      await tester.tap(find.text(Strings.confirmPaymentButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(Strings.completeReservationButton));
      await tester.tap(find.text(Strings.completeReservationButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }

    Future<void> tearDownTree(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }

    testWidgets('the bag is reserved before any payment screen opens', (
      tester,
    ) async {
      final harness = buildQueueHarness();

      await tester.pumpWidget(launcher(harness.controller, seededStoreId));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();

      expect(find.text(Strings.bagHeldTitle), findsOneWidget);
      expect(find.text(Strings.paymentTitle), findsNothing);
      expect(harness.repo.reserveCalls, 1);
      expect(
        await harness.controller.blockingPurchaseFor(
          testUser.id,
          todayDateString(),
        ),
        isNotNull,
      );

      await tester.tap(find.text(Strings.payCashOption));
      await tester.pumpAndSettle();
      await tearDownTree(tester);
    });

    testWidgets(
      'Jawwal: the simulated payment is recorded but never marks the bag paid',
      (tester) async {
        final harness = buildQueueHarness();
        final controller = harness.controller;

        await tester.pumpWidget(launcher(controller, seededStoreId));
        await tester.tap(find.text('buy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Strings.payWithJawwalOption));
        await tester.pumpAndSettle();
        expect(find.text(Strings.paymentTitle), findsOneWidget);

        await payThroughWallet(tester);

        expect(find.byType(ConfirmationScreen), findsOneWidget);
        expect(harness.repo.walletPaymentCalls, 1);
        final booked = await controller.blockingPurchaseFor(
          testUser.id,
          todayDateString(),
        );
        expect(booked!.paymentMethod, 'simulated');
        expect(booked.isPrepaid, isFalse);
        expect(find.text(Strings.paymentMethodSimulated), findsOneWidget);
        expect(find.text(Strings.paidAlready), findsNothing);
        expect(find.byKey(const Key('amount-due')), findsOneWidget);

        await tearDownTree(tester);
      },
    );

    testWidgets('cash at pickup records no payment', (tester) async {
      final harness = buildQueueHarness();
      final controller = harness.controller;

      await tester.pumpWidget(launcher(controller, seededStoreId));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.payCashOption));
      await tester.pumpAndSettle();

      expect(find.text(Strings.paymentTitle), findsNothing);
      expect(find.byType(ConfirmationScreen), findsOneWidget);
      expect(harness.repo.walletPaymentCalls, 0);
      final booked = await controller.blockingPurchaseFor(
        testUser.id,
        todayDateString(),
      );
      expect(booked!.paymentMethod, isNull);
      expect(find.text(Strings.paymentMethodCash), findsOneWidget);

      await tearDownTree(tester);
    });

    testWidgets('backing out of the wallet keeps the booking, cash due', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      final controller = harness.controller;

      await tester.pumpWidget(launcher(controller, seededStoreId));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.payWithJawwalOption));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(Strings.back));
      await tester.tap(find.text(Strings.back));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationScreen), findsOneWidget);
      expect(harness.repo.walletPaymentCalls, 0);
      expect(
        (await controller.blockingPurchaseFor(
          testUser.id,
          todayDateString(),
        ))!.paymentMethod,
        isNull,
      );
      expect(find.text(Strings.paymentMethodCash), findsOneWidget);

      await tearDownTree(tester);
    });

    testWidgets('a failed payment record keeps the booking, cash due', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      harness.repo.failWalletPayment = true;

      await tester.pumpWidget(launcher(harness.controller, seededStoreId));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.payWithJawwalOption));
      await tester.pumpAndSettle();
      await payThroughWallet(tester);

      expect(find.byType(ConfirmationScreen), findsOneWidget);
      expect(harness.repo.walletPaymentCalls, 1);
      expect(
        (await harness.controller.blockingPurchaseFor(
          testUser.id,
          todayDateString(),
        ))!.paymentMethod,
        isNull,
      );
      expect(find.text(Strings.paymentMethodCash), findsOneWidget);

      await tearDownTree(tester);
    });

    testWidgets('a double tap reserves once', (tester) async {
      final harness = buildQueueHarness();

      await tester.pumpWidget(launcher(harness.controller, seededStoreId));
      await tester.tap(find.text('buy'));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();

      expect(harness.repo.reserveCalls, 1);
      expect(find.text(Strings.bagHeldTitle), findsOneWidget);

      await tester.tap(find.text(Strings.payCashOption));
      await tester.pumpAndSettle();
      await tearDownTree(tester);
    });

    testWidgets('a closed bakery is reported before any payment screen', (
      tester,
    ) async {
      final harness = buildQueueHarness();

      await tester.pumpWidget(
        launcher(harness.controller, seededClosedStoreId),
      );
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();

      expect(find.text(Strings.soldOut), findsOneWidget);
      expect(find.text(Strings.bagHeldTitle), findsNothing);
      expect(find.text(Strings.paymentTitle), findsNothing);

      await tearDownTree(tester);
    });

    testWidgets('a buyer who already booked today is sent to that receipt', (
      tester,
    ) async {
      final harness = buildQueueHarness();
      final controller = harness.controller;
      await controller.buy(storeId: seededStoreId, date: todayDateString());

      await tester.pumpWidget(launcher(controller, 'store-shati'));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();

      expect(find.text(Strings.paymentTitle), findsNothing);
      expect(find.byType(ConfirmationScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
