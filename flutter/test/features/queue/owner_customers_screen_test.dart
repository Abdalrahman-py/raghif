import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/owner_customers_screen.dart';
import 'package:raghif/features/queue/owner_dashboard_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

class _TestEnv {
  _TestEnv(this.db, this.repository, this.controller);

  final AppDatabase db;
  final QueueRepositoryImpl repository;
  final QueueController controller;
}

/// Builds a fresh in-memory database + controller. Must be called from
/// *inside* a testWidgets body, not from setUp() — setUp() runs outside
/// testWidgets' own FakeAsync zone, and a database built there can't
/// reliably deliver .watch() stream data inside the test body (its
/// microtasks/timers are bound to the wrong zone, so the stream never
/// appears to emit even though the query itself is correct). Not
/// explicitly closed: each test's database is fresh and short-lived, and
/// unmounting the widget (pumpWidget(SizedBox()) + pumpAndSettle) already
/// cancels its .watch() subscription cleanly — an extra explicit
/// controller.dispose()/db.close() afterward re-touches an already-settled
/// stream and reliably hangs (drift's internal cleanup Timer never
/// resolves).
Future<_TestEnv> _buildTestEnv() async {
  final db = AppDatabase(NativeDatabase.memory());
  final repository = QueueRepositoryImpl(db);
  await repository.ensureSeeded();
  final controller = QueueController(repository);
  return _TestEnv(db, repository, controller);
}

void main() {
  group('OwnerCustomersScreen', () {
    testWidgets('displays empty state when no purchases exist', (tester) async {
      final env = await _buildTestEnv();

      await tester.pumpWidget(
        wrapWithMaterial(
          OwnerCustomersScreen(
            controller: env.controller,
            storeId: demoOwnerStoreId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.customersTitle), findsOneWidget);
      expect(find.text(Strings.customersEmpty), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('displays customer info when purchases exist', (tester) async {
      final env = await _buildTestEnv();

      final user = await env.db.into(env.db.users).insert(
        UsersCompanion.insert(
          phone: '0599888777',
          nationalId: '988877766',
          pinHash: 'hash',
          name: 'خالد محمود',
        ),
      );

      await env.repository.reserveBag(
        userId: user,
        storeId: demoOwnerStoreId,
        date: '2026-09-02',
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          OwnerCustomersScreen(
            controller: env.controller,
            storeId: demoOwnerStoreId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.customersTitle), findsOneWidget);
      expect(find.text('خالد محمود'), findsOneWidget);
      expect(find.text('0599888777'), findsOneWidget);
      expect(find.text(Strings.totalPurchasesCount(1)), findsOneWidget);
      expect(find.text(Strings.lastPurchaseDate('2026-09-02')), findsOneWidget);
      expect(find.text(Strings.customersEmpty), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('OwnerDashboardScreen navigates to OwnerCustomersScreen', (tester) async {
      final env = await _buildTestEnv();
      final mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.state).thenReturn(const Authenticated(
        UserModel(
          id: 2,
          phone: demoOwnerPhone,
          nationalId: demoOwnerNationalId,
          name: demoOwnerName,
          role: UserRole.owner,
          verificationStatus: VerificationStatus.verified,
        ),
      ));

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: wrapWithMaterial(
            OwnerDashboardScreen(
              controller: env.controller,
              storeId: demoOwnerStoreId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.customersButton), findsOneWidget);

      await tester.tap(find.text(Strings.customersButton));
      await tester.pumpAndSettle();

      expect(find.byType(OwnerCustomersScreen), findsOneWidget);
      expect(find.text(Strings.customersTitle), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
