import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/owner_dashboard_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';
import 'package:raghif/features/queue/store_list_screen.dart';
import '../../goldens/test_fonts.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late QueueController controller;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    controller = QueueController();
    when(() => mockAuthBloc.state).thenReturn(const Authenticated(
      UserModel(
        id: 1,
        phone: '0599111111',
        nationalId: '900111222',
        name: 'أحمد ناصر',
        role: UserRole.buyer,
        verificationStatus: VerificationStatus.verified,
      ),
    ));
  });

  testWidgets('StoreListScreen logout button dispatches LogoutRequestedEvent',
      (tester) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    const demoUser = DemoUser(
      phone: '0599111111',
      pin: '1234',
      role: UserRole.buyer,
      name: 'أحمد ناصر',
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: StoreListScreen(
            controller: controller,
            currentUser: demoUser,
          ),
        ),
      ),
    );

    final logoutButton = find.byTooltip(Strings.logout);
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pump();

    verify(() => mockAuthBloc.add(const LogoutRequestedEvent())).called(1);
  });

  testWidgets('OwnerDashboardScreen logout button dispatches LogoutRequestedEvent',
      (tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OwnerDashboardScreen(
            controller: controller,
            storeId: demoOwnerStoreId,
          ),
        ),
      ),
    );

    final logoutButton = find.byTooltip(Strings.logout);
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pump();

    verify(() => mockAuthBloc.add(const LogoutRequestedEvent())).called(1);
  });
}
