import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/registration_screen.dart';
import 'package:raghif/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Pumps the carousel and hands back how many times it reported being done —
  /// the screen only signals through [OnboardingScreen.onDone], main.dart does
  /// the actual swapping.
  Future<List<int>> pumpOnboarding(WidgetTester tester) async {
    final doneCount = <int>[0];
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        // The sign-up handoff pushes RegistrationScreen, which reads AuthBloc.
        value: AuthBloc(
          authRepository: FakeAuthRepository(),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          // main.dart forces RTL; the slides have to be measured that way.
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: OnboardingScreen(onDone: () => doneCount[0]++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return doneCount;
  }

  testWidgets('opens on the first slide and says where the user is', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.text(Strings.onboardingPageOf(1, 3)), findsOneWidget);
    expect(find.text(Strings.onboardingTitle1), findsOneWidget);
    expect(find.text(Strings.onboardingBody1), findsOneWidget);
    // The last slide is the only one that offers the sign-up decision.
    expect(find.text(Strings.onboardingGetStarted), findsNothing);
    expect(find.text(Strings.onboardingHaveAccount), findsNothing);
  });

  testWidgets(
    'steps through with the primary button and ends on the decision',
    (tester) async {
      await pumpOnboarding(tester);

      await tester.tap(find.text(Strings.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text(Strings.onboardingPageOf(2, 3)), findsOneWidget);
      expect(find.text(Strings.onboardingTitle2), findsOneWidget);

      await tester.tap(find.text(Strings.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text(Strings.onboardingPageOf(3, 3)), findsOneWidget);
      expect(find.text(Strings.onboardingTitle3), findsOneWidget);
      // Both ways out are real buttons: returning users no longer depend on the
      // small skip link to get back into their account.
      expect(find.text(Strings.onboardingGetStarted), findsOneWidget);
      expect(find.text(Strings.onboardingHaveAccount), findsOneWidget);
      expect(find.text(Strings.onboardingNext), findsNothing);
    },
  );

  testWidgets('the dots jump straight to a slide', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-dot-2')));
    await tester.pumpAndSettle();

    expect(find.text(Strings.onboardingTitle3), findsOneWidget);
    expect(find.text(Strings.onboardingPageOf(3, 3)), findsOneWidget);
  });

  testWidgets('skip reports done so main can show login', (tester) async {
    final doneCount = await pumpOnboarding(tester);

    await tester.tap(find.text(Strings.onboardingSkip));
    await tester.pumpAndSettle();

    expect(doneCount[0], 1);
  });

  testWidgets('the last slide hands off to sign-up', (tester) async {
    final doneCount = await pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-dot-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.onboardingGetStarted));
    await tester.pumpAndSettle();

    expect(doneCount[0], 1);
    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('a returning user from the last slide reports done too', (
    tester,
  ) async {
    final doneCount = await pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-dot-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.onboardingHaveAccount));
    await tester.pumpAndSettle();

    expect(doneCount[0], 1);
  });
}
