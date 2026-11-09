import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/main.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_queue_repository.dart';

import 'support/queue_test_harness.dart';

void main() {
  testWidgets(
    'RaghifApp opens fresh onboarding directly, with no launch screen',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final authBloc = AuthBloc(authRepository: FakeAuthRepository());
      await tester.pumpWidget(
        RaghifApp(
          authBloc: authBloc,
          guestRepository: FakeQueueRepository.seeded(),
          queueController: buildQueueHarness().controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ابدأ التجربة'), findsNothing);
      expect(find.text(Strings.onboardingTitle1), findsOneWidget);
      expect(
        find.text(Strings.onboardingGetStarted),
        findsNothing,
      ); // not on slide 1

      // App is forced RTL regardless of device locale.
      expect(
        find.byWidgetPredicate(
          (w) => w is Directionality && w.textDirection == TextDirection.rtl,
        ),
        findsWidgets,
      );

      // RaghifApp's own State.dispose() closes the bloc/queue controller it's
      // given. Unmount it here — as the test's own last step, rather than in
      // addTearDown (which runs after Flutter's own end-of-test invariant
      // check, too late to matter) — and pump once more so any Timer that
      // dispose schedules internally (e.g. drift's stream-cancellation
      // cleanup) gets to fire before that check runs.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'RaghifApp shows the guest bakery screen once onboarding is done',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'onboarding.seen': true});

      final authBloc = AuthBloc(authRepository: FakeAuthRepository());
      await tester.pumpWidget(
        RaghifApp(
          authBloc: authBloc,
          guestRepository: FakeQueueRepository.seeded(),
          queueController: buildQueueHarness().controller,
        ),
      );
      await tester.pumpAndSettle();

      // Signed out: bakeries first, an account only when asked for.
      expect(find.text(Strings.guestTagline), findsOneWidget);
      expect(find.text(Strings.guestStoresTitle), findsOneWidget);
      expect(find.text(Strings.phoneLabel), findsNothing);

      // See the first test's comment: unmount inline, not via addTearDown.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'signing out from the running app asks, then returns to the guest screen',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'onboarding.seen': true});
      const buyer = UserModel(
        id: 'user-buyer',
        phone: '0599111111',
        name: 'أحمد ناصر',
        verificationStatus: VerificationStatus.verified,
      );
      final authBloc = AuthBloc(
        authRepository: FakeAuthRepository(
          users: const [buyer],
          sessionUserId: 'user-buyer',
        ),
      );
      await tester.pumpWidget(
        RaghifApp(
          authBloc: authBloc,
          guestRepository: FakeQueueRepository.seeded(),
          queueController: buildQueueHarness().controller,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      final logout = find.widgetWithText(OutlinedButton, 'تسجيل الخروج');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      expect(logout.hitTestable(), findsOneWidget);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(find.text(Strings.logoutConfirmTitle), findsOneWidget);

      // Confirm with the dialog's own button, not the app bar's tooltip.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(Strings.logout),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.logoutConfirmTitle), findsNothing);
      expect(find.text(Strings.guestTagline), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'signing out from a pushed screen clears the stack: login, no way back',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'onboarding.seen': true});
      const buyer = UserModel(
        id: 'user-buyer',
        phone: '0599111111',
        name: 'أحمد ناصر',
        verificationStatus: VerificationStatus.verified,
      );
      final authBloc = AuthBloc(
        authRepository: FakeAuthRepository(
          users: const [buyer],
          sessionUserId: 'user-buyer',
        ),
      );
      await tester.pumpWidget(
        RaghifApp(
          authBloc: authBloc,
          guestRepository: FakeQueueRepository.seeded(),
          queueController: buildQueueHarness().controller,
        ),
      );
      await tester.pumpAndSettle();

      // Open a bakery (a pushed route), go back, then sign out from the
      // account tab: the stack must still end up clean.
      await tester.tap(find.text('عرض المخبز').first);
      await tester.pumpAndSettle();
      expect(find.text(Strings.storeDetailsTitle), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('حسابي').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تسجيل الخروج'));
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(Strings.logout),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.storeDetailsTitle), findsNothing);
      expect(find.text(Strings.guestTagline), findsOneWidget);
      // Back from login must leave the app, not reopen the signed-out screen.
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      expect(navigator.canPop(), isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
