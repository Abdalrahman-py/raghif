import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/main.dart';

import 'support/fake_auth_repository.dart';

import 'support/queue_test_harness.dart';

void main() {
  testWidgets('RaghifApp shows onboarding on a fresh install', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sessionStore = SessionStore();

    final authBloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      sessionStore: sessionStore,
    );
    await tester.pumpWidget(
      RaghifApp(
        authBloc: authBloc,
        queueController: buildQueueHarness().controller,
      ),
    );
    await tester.pumpAndSettle();

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
  });

  testWidgets('RaghifApp renders the login screen once onboarding is done', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding.seen': true});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sessionStore = SessionStore();

    final authBloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      sessionStore: sessionStore,
    );
    await tester.pumpWidget(
      RaghifApp(
        authBloc: authBloc,
        queueController: buildQueueHarness().controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Strings.loginIdTitle), findsOneWidget);
    expect(find.text(Strings.personalIdLabel), findsOneWidget);
    expect(find.text(Strings.continueButton), findsOneWidget);

    // See the first test's comment: unmount inline, not via addTearDown.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('signing out from the running app asks, then returns to login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding.seen': true,
      'session.userId': 'user-buyer',
    });
    const buyer = UserModel(
      id: 'user-buyer',
      phone: '0599111111',
      nationalId: '900111222',
      name: 'أحمد ناصر',
      verificationStatus: VerificationStatus.verified,
    );
    final authBloc = AuthBloc(
      authRepository: FakeAuthRepository(users: const [buyer]),
      sessionStore: SessionStore(),
    );
    await tester.pumpWidget(
      RaghifApp(
        authBloc: authBloc,
        queueController: buildQueueHarness().controller,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip(Strings.logout), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.logout));
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
    expect(find.text(Strings.loginIdTitle), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
