import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/queue/owner_dashboard_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';

import '../../support/queue_test_harness.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late QueueController controller;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    controller = buildQueueHarness().controller;
    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        UserModel(
          id: 'user-1',
          phone: '0599111111',
          name: 'أحمد ناصر',
          role: UserRole.buyer,
          verificationStatus: VerificationStatus.verified,
        ),
      ),
    );
  });

  testWidgets(
    'OwnerDashboardScreen has no logout button; the profile avatar replaces '
    'the bakery logo',
    (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: MaterialApp(
            theme: AppTheme.light,
            home: OwnerDashboardScreen(
              controller: controller,
              storeId: seededStoreId,
            ),
          ),
        ),
      );

      expect(find.byTooltip(Strings.logout), findsNothing);
      expect(find.byTooltip('حسابي'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    },
  );
}
