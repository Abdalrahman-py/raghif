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
    // RaghifApp's own State.dispose() closes the bloc it's given. Unmount
    // it (rather than calling authBloc.close() ourselves) so that happens
    // while nothing is still subscribed — closing a bloc a live
    // BlocBuilder is listening to deadlocks pumpAndSettle-style teardown.
    addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });

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
    addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });

    await tester.pumpWidget(RaghifApp(authBloc: authBloc));
    await tester.pumpAndSettle();

    expect(find.text(Strings.appTitle), findsOneWidget);
    expect(find.text(Strings.requestOtpButton), findsOneWidget);
    expect(find.text(Strings.personalIdLabel), findsOneWidget);
    expect(find.text(Strings.loginWithPinInstead), findsOneWidget);
  });
}
