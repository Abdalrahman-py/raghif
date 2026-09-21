import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tolerant_golden_comparator.dart';
import 'test_fonts.dart';

/// The intro is the first thing installed, on the cheapest hardware, often
/// before any account exists. These goldens pin the artwork badge, the copy
/// block's centring in RTL, and — most importantly — that the 320x640dp target
/// doesn't clip the copy or run the primary action off the screen.
void main() {
  setUpAll(() {
    goldenFileComparator = TolerantGoldenComparator(
      Uri.parse('test/goldens/onboarding_screen_golden_test.dart'),
    );
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required Size logicalSize,
    int dotsToTap = 0,
  }) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = logicalSize * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: OnboardingScreen(onDone: () {}),
      ),
    );
    await tester.pumpAndSettle();

    if (dotsToTap > 0) {
      await tester.tap(find.byKey(ValueKey('onboarding-dot-$dotsToTap')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('OnboardingScreen first slide matches golden (360x800dp)', (
    tester,
  ) async {
    await pumpOnboarding(tester, logicalSize: const Size(360, 800));

    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('onboarding_screen.png'),
    );
  });

  testWidgets('OnboardingScreen first slide matches golden on a small phone '
      '(320x640dp)', (tester) async {
    await pumpOnboarding(tester, logicalSize: const Size(320, 640));

    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('onboarding_screen_small.png'),
    );
  });

  testWidgets('OnboardingScreen last slide matches golden (360x800dp)', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      logicalSize: const Size(360, 800),
      dotsToTap: 2,
    );

    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('onboarding_screen_last.png'),
    );
  });
}
