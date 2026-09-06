import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/queue/owner_dashboard_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Builds a fresh in-memory database + controller, pre-seeded and awaited.
/// Must be called from *inside* a testWidgets body — see
/// owner_customers_screen_test.dart's `_buildTestEnv` for why a bare
/// `QueueController()` (its unawaited internal seed) or a setUp()-built
/// controller can't reliably deliver `.watch()` stream data in a test body.
Future<QueueController> _buildTestController() async {
  final db = AppDatabase(NativeDatabase.memory());
  final repository = QueueRepositoryImpl(db);
  await repository.ensureSeeded();
  return QueueController(repository);
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        UserModel(
          id: 2,
          phone: '0599000002',
          nationalId: '900333444',
          name: 'صاحب المخبز',
          role: UserRole.owner,
          verificationStatus: VerificationStatus.verified,
        ),
      ),
    );
  });

  Future<QueueController> pumpDashboard(
    WidgetTester tester,
    dynamic storeId,
  ) async {
    final controller = await _buildTestController();
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OwnerDashboardScreen(controller: controller, storeId: storeId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    "shows the store's existing purchase window on the picker buttons",
    (tester) async {
      await pumpDashboard(tester, 1); // مخبز الرمال — seeded 08:00-10:00

      expect(find.text(Strings.openTimeLabel), findsOneWidget);
      expect(find.text(Strings.closeTimeLabel), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    },
  );

  testWidgets(
    'shows "not set" on the picker buttons when the store has no window yet',
    (tester) async {
      await pumpDashboard(tester, 3); // مخبز النصيرات — no window seeded

      expect(find.text(Strings.openTimeLabel), findsOneWidget);
      expect(find.text(Strings.closeTimeLabel), findsOneWidget);
      expect(find.text(Strings.notSetLabel), findsNWidgets(2));
    },
  );

  testWidgets('saving allocation keeps the currently-set purchase window', (
    tester,
  ) async {
    final controller = await pumpDashboard(tester, 1);

    await tester.ensureVisible(find.text(Strings.saveAllocation));
    await tester.tap(find.text(Strings.saveAllocation));
    await tester.pumpAndSettle();

    final store = controller.storeById(1);
    expect(store?.openTime, '08:00');
    expect(store?.closeTime, '10:00');
  });
}
