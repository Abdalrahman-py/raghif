import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/data/repositories/auth_repository_impl.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
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
    final sessionStore = SessionStore();

    final authBloc = AuthBloc(
      authRepository: AuthRepositoryImpl(db: db, sessionStore: sessionStore),
      sessionStore: sessionStore,
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

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('login_screen.png'),
    );
  });
}
