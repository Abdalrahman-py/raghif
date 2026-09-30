import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/login_screen.dart';

import 'test_fonts.dart';

import '../support/fake_auth_repository.dart';
import '../support/finders.dart';

/// The login screen is the most-seen screen in the app and the one a returning
/// buyer opens in a hurry. Three goldens: the National ID step and the code step
/// at the standard size, plus the National ID step on the 320x640dp deployment
/// target, where the form, its helper text and the demo block all have to fit.
void main() {
  const buyer = UserModel(
    id: 'user-buyer',
    phone: '0599111111',
    nationalId: '900111222',
    name: 'أحمد ناصر',
  );

  Future<void> pumpLogin(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = logicalSize * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final authBloc = AuthBloc(
      authRepository: FakeAuthRepository(users: const [buyer]),
      sessionStore: SessionStore(),
    );
    // addTearDown runs LIFO, so registering close() first and the unmount
    // second means the unmount fires first -- closing a bloc while a
    // BlocBuilder is still subscribed to it can hang (see widget_test.dart).
    addTearDown(authBloc.close);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('LoginScreen National ID step matches golden (360x800dp)', (
    tester,
  ) async {
    await pumpLogin(tester, logicalSize: const Size(360, 800));

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('login_screen.png'),
    );
  });

  testWidgets('LoginScreen National ID step on a small phone (320x640dp)', (
    tester,
  ) async {
    await pumpLogin(tester, logicalSize: const Size(320, 640));

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('login_screen_small.png'),
    );
  });

  testWidgets('LoginScreen code step matches golden (360x800dp)', (
    tester,
  ) async {
    await pumpLogin(tester, logicalSize: const Size(360, 800));

    await tester.enterText(
      fieldByLabel(Strings.personalIdLabel),
      buyer.nationalId,
    );
    await tester.tap(find.text(Strings.requestOtpButton));
    // No pumpAndSettle here: the resend countdown is a live periodic timer, so
    // settling against it never finishes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('login_otp_step.png'),
    );
  });
}
