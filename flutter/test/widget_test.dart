import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/data/repositories/auth_repository_impl.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/main.dart';

void main() {
  testWidgets('RaghifApp shows onboarding on a fresh install', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sessionStore = SessionStore();

    final authBloc = AuthBloc(
      authRepository: AuthRepositoryImpl(db: db, sessionStore: sessionStore),
      sessionStore: sessionStore,
    );
    await tester.pumpWidget(RaghifApp(authBloc: authBloc));
    await tester.pumpAndSettle();

    expect(find.text(Strings.onboardingTitle1), findsOneWidget);
    expect(find.text(Strings.onboardingGetStarted), findsNothing); // not on slide 1

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
    await tester.pump();
  });

  testWidgets('RaghifApp renders the login screen once onboarding is done',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding.seen': true});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sessionStore = SessionStore();

    final authBloc = AuthBloc(
      authRepository: AuthRepositoryImpl(db: db, sessionStore: sessionStore),
      sessionStore: sessionStore,
    );
    await tester.pumpWidget(RaghifApp(authBloc: authBloc));
    await tester.pumpAndSettle();

    expect(find.text(Strings.appTitle), findsOneWidget);
    expect(find.text(Strings.requestOtpButton), findsOneWidget);
    expect(find.text(Strings.personalIdLabel), findsOneWidget);
    expect(find.text(Strings.loginWithPinInstead), findsOneWidget);

    // See the first test's comment: unmount inline, not via addTearDown.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
