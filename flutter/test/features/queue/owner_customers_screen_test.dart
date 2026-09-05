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

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl repository;
  late QueueController controller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = QueueRepositoryImpl(db);
    await repository.ensureSeeded();
    controller = QueueController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  group('OwnerCustomersScreen', () {
    testWidgets('displays empty state when no purchases exist', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
      await tester.pumpWidget(
        wrapWithMaterial(
          OwnerCustomersScreen(
            controller: controller,
            storeId: demoOwnerStoreId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.customersTitle), findsOneWidget);
      expect(find.text(Strings.customersEmpty), findsOneWidget);
    });

    testWidgets('displays customer info when purchases exist', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
      final user = await db.into(db.users).insert(
        UsersCompanion.insert(
          phone: '0599888777',
          nationalId: '988877766',
          pinHash: 'hash',
          name: 'خالد محمود',
        ),
      );

      await repository.reserveBag(
        userId: user,
        storeId: demoOwnerStoreId,
        date: '2026-09-02',
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          OwnerCustomersScreen(
            controller: controller,
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
    });

    testWidgets('OwnerDashboardScreen navigates to OwnerCustomersScreen', (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
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
              controller: controller,
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
    });
  });
}
