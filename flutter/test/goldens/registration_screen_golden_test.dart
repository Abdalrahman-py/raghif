import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import 'tolerant_golden_comparator.dart';
import 'test_fonts.dart';

/// The sign-up form is the first screen a new user fills in, and the one most
/// likely to be filled on a 320dp phone in daylight. These goldens pin its
/// two-section hierarchy, the RTL placement of the inline errors, and that
/// nothing clips on the small deployment target.
void main() {
  setUpAll(() {
    goldenFileComparator = TolerantGoldenComparator(
      Uri.parse('test/goldens/registration_screen_golden_test.dart'),
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size logicalSize,
    bool submitEmptyForm = false,
  }) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = logicalSize * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    // The screen reads AuthBloc for its loading/error state, so it needs a real
    // one even though nothing is submitted here.
    final authBloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      sessionStore: SessionStore(),
    );
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const RegistrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (submitEmptyForm) {
      // Inline validation: the state a user sees on their first tap of
      // "تسجيل حساب جديد" with nothing filled in.
      await tester.ensureVisible(find.text(Strings.registerButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.registerButton));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('RegistrationScreen matches golden (360x800dp)', (tester) async {
    await pumpScreen(tester, logicalSize: const Size(360, 800));

    await expectLater(
      find.byType(RegistrationScreen),
      matchesGoldenFile('registration_screen.png'),
    );
  });

  testWidgets('RegistrationScreen matches golden on a small phone '
      '(320x640dp)', (tester) async {
    await pumpScreen(tester, logicalSize: const Size(320, 640));

    await expectLater(
      find.byType(RegistrationScreen),
      matchesGoldenFile('registration_screen_small.png'),
    );
  });

  testWidgets('RegistrationScreen shows per-field errors (360x800dp)', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      logicalSize: const Size(360, 800),
      submitEmptyForm: true,
    );

    await expectLater(
      find.byType(RegistrationScreen),
      matchesGoldenFile('registration_screen_errors.png'),
    );
  });
}
