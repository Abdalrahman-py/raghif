import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/features/guest/pending_booking.dart';
import 'package:raghif/features/navigation/buyer_shell.dart';
import 'package:raghif/features/queue/buyer_stores_home.dart';
import 'package:raghif/features/queue/queue_logic.dart' show todayDateString;
import '../../support/fake_auth_repository.dart';
import '../../support/fake_notification_repository.dart';
import '../../support/queue_test_harness.dart';

void main() {
  test('PendingBooking remembers a bakery once and forgets it when read', () {
    PendingBooking.set('store-1');
    expect(PendingBooking.storeId, 'store-1');
    expect(PendingBooking.take(), 'store-1');
    expect(PendingBooking.take(), isNull);
  });

  testWidgets('a bakery chosen before signing up opens its booking summary', (
    tester,
  ) async {
    final harness = buildQueueHarness();
    final bloc = AuthBloc(authRepository: FakeAuthRepository());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: BuyerShell(
            controller: harness.controller,
            openStoreId: seededStoreId,
            currentUser: const DemoUser(
              id: seededBuyerId,
              name: 'أحمد ناصر',
              phone: '0599111111',
              pin: '',
              role: UserRole.buyer,
            ),
            notifications: FakeNotificationRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Straight to payment: no review screen in between.
    expect(find.text(Strings.paymentTitle), findsOneWidget);
    expect(find.text('راجع حجزك'), findsNothing);
  });

  testWidgets('the home opens on "my bakeries" and "all" is one tap away', (
    tester,
  ) async {
    final harness = buildQueueHarness(actingAs: seededBuyerId);
    await harness.controller.buy(
      storeId: seededStoreId,
      date: todayDateString(),
    );
    final bloc = AuthBloc(authRepository: FakeAuthRepository());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: BuyerShell(
            controller: harness.controller,
            currentUser: const DemoUser(
              id: seededBuyerId,
              name: 'أحمد ناصر',
              phone: '0599111111',
              pin: '',
              role: UserRole.buyer,
            ),
            notifications: FakeNotificationRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Only the bakery bought from is listed, under the first (selected) chip.
    final mine = find.widgetWithText(FilterChip, 'مخابزي');
    expect(tester.widget<FilterChip>(mine).selected, isTrue);
    expect(find.byType(BakeryCard), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'الكل'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(mine).selected, isFalse);
    expect(find.byType(BakeryCard).evaluate().length, greaterThan(1));
  });

  testWidgets(
    'home geographic selection filters existing list; tabs retain auth',
    (tester) async {
      final harness = buildQueueHarness();
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(
          users: const [
            UserModel(
              id: seededBuyerId,
              name: 'أحمد ناصر',
              phone: '0599111111',
              verificationStatus: VerificationStatus.verified,
            ),
          ],
          sessionUserId: seededBuyerId,
        ),
      );
      addTearDown(bloc.close);
      bloc.add(const CheckAuthSessionEvent());
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (_, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: BuyerShell(
              controller: harness.controller,
              currentUser: const DemoUser(
                id: seededBuyerId,
                name: 'أحمد ناصر',
                phone: '0599111111',
                pin: '',
                role: UserRole.buyer,
              ),
              notifications: FakeNotificationRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // New home: governorate filter chips and bakery cards, no pickers.
      expect(find.text('اختار المحافظة'), findsNothing);
      expect(find.text('كل المخابز'), findsOneWidget);
      expect(find.text('مخبز الرمال'), findsOneWidget);
      expect(find.text('مخبز الشاطئ'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'غزة'));
      await tester.pumpAndSettle();
      expect(find.text('مخبز الرمال'), findsOneWidget);
      expect(find.text('اشترِ ربطة'), findsWidgets);
      expect(find.text('عرض المخبز'), findsWidgets);
      // Search by name narrows the list and says so when nothing matches.
      await tester.enterText(find.byKey(const Key('store-search')), 'الرمال');
      await tester.pumpAndSettle();
      expect(find.text('مخبز الرمال'), findsOneWidget);
      expect(find.text('مخبز الشاطئ'), findsNothing);
      await tester.enterText(find.byKey(const Key('store-search')), 'لا يوجد');
      await tester.pumpAndSettle();
      expect(find.text(Strings.noMatchingStores), findsOneWidget);
      await tester.enterText(find.byKey(const Key('store-search')), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('حجزي'));
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد طلب اليوم'), findsOneWidget);
      await tester.tap(find.text('حسابي').last);
      await tester.pumpAndSettle();
      expect(find.text('0599111111'), findsOneWidget);
      expect(bloc.state, isA<Authenticated>());
      await tester.pumpWidget(const SizedBox.shrink());
      harness.controller.dispose();
      harness.repo.dispose();
    },
  );
}
