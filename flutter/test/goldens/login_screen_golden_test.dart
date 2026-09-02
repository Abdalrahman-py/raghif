import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/auth_repository.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/auth/login_screen.dart';

import 'test_fonts.dart';

void main() {
  testWidgets('LoginScreen matches golden', (WidgetTester tester) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: LoginScreen(
          authRepository: AuthRepository(db),
          sessionStore: SessionStore(),
          onLoginBuyer: (_) {},
          onLoginOwner: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('login_screen.png'),
    );
  });
}
