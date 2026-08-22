import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/auth/login_screen.dart';

/// Registers the bundled Noto Sans Arabic weights with the test font loader
/// so the golden render matches what the app actually ships, instead of
/// falling back to the test harness's default test font.
Future<void> _loadAppFonts() async {
  final fontLoader = FontLoader('NotoSansArabic');
  fontLoader.addFont(
    rootBundle.load('assets/fonts/NotoSansArabic-VariableFont.ttf'),
  );
  await fontLoader.load();
}

void main() {
  testWidgets('LoginScreen matches golden', (WidgetTester tester) async {
    await _loadAppFonts();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: LoginScreen(onLoginBuyer: () {}, onLoginOwner: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('login_screen.png'),
    );
  });
}
