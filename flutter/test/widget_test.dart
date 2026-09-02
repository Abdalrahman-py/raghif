import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/auth_repository.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/main.dart';

void main() {
  testWidgets('RaghifApp renders the login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      RaghifApp(authRepository: AuthRepository(db), sessionStore: SessionStore()),
    );
    await tester.pumpAndSettle();

    expect(find.text(Strings.appTitle), findsOneWidget);
    expect(find.text(Strings.loginButton), findsOneWidget);
    expect(find.text(Strings.phoneLabel), findsOneWidget);
    expect(find.text(Strings.pinLabel), findsOneWidget);

    // App is forced RTL regardless of device locale.
    expect(
      find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );
  });
}
