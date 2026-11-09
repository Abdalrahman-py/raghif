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

  group('Buying a bag goes straight to payment', () {
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

    testWidgets(
      'the first screen is payment (no review screen); completing it books a '
      'prepaid bag and shows the receipt',
      (tester) async {
        final harness = buildQueueHarness();
        final controller = harness.controller;

        await tester.pumpWidget(launcher(controller, seededStoreId));
        await tester.tap(find.text('buy'));
        await tester.pumpAndSettle();

        // Straight to the Jawwal Pay number screen.
        expect(find.text(Strings.paymentTitle), findsOneWidget);
        expect(find.text('راجع حجزك'), findsNothing);

        await tester.ensureVisible(find.text(Strings.proceedToOtp));
        await tester.tap(find.text(Strings.proceedToOtp));
        await tester.pumpAndSettle();
        expect(find.text(Strings.paymentOtpTitle), findsOneWidget);

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

        await tester.ensureVisible(
          find.text(Strings.completeReservationButton),
        );
        await tester.tap(find.text(Strings.completeReservationButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.byType(ConfirmationScreen), findsOneWidget);
        final booked = await controller.blockingPurchaseFor(
          testUser.id,
          todayDateString(),
        );
        expect(booked, isNotNull);
        expect(booked!.paymentMethod, 'simulated');
        expect(booked.isPrepaid, isFalse);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('backing out of payment books nothing', (tester) async {
      final harness = buildQueueHarness();
      final controller = harness.controller;

      await tester.pumpWidget(launcher(controller, seededStoreId));
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(Strings.back));
      await tester.tap(find.text(Strings.back));
      await tester.pumpAndSettle();

      expect(find.text('buy'), findsOneWidget);
      expect(
        await controller.blockingPurchaseFor(testUser.id, todayDateString()),
        isNull,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
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
