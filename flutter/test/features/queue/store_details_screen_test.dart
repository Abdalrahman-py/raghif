import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/store_list_entry.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/queue_controller.dart';
import 'package:raghif/core/widgets/primary_button.dart';
import 'package:raghif/features/queue/store_details_screen.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockQueueRepository repo;
  late MockAuthBloc authBloc;
  late QueueController controller;

  const demoUser = DemoUser(
    id: 1,
    phone: demoBuyerPhone,
    pin: '1234',
    role: UserRole.buyer,
    name: 'أحمد ناصر',
  );

  StoreModel store({
    bool isOpen = true,
    int bagsRemaining = 10,
  }) => StoreModel(
    id: 1,
    name: 'مخبز الرمال',
    isOpen: isOpen,
    dailyBagLimit: 300,
    bagsRemaining: bagsRemaining,
    ownerPhone: '0599000001',
    openTime: '08:00',
    closeTime: '10:00',
    area: 'الرمال',
  );

  setUp(() {
    repo = MockQueueRepository();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    when(() => repo.watchStores()).thenAnswer((_) => const Stream.empty());
    when(() => repo.setStorePinned(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
          pinned: any(named: 'pinned'),
        )).thenAnswer((_) async {});
    controller = QueueController(repo);
  });

  void stubEntries(List<StoreListEntry> entries) {
    when(() => repo.watchStoreListForUser(
          userId: any(named: 'userId'),
          today: any(named: 'today'),
        )).thenAnswer((_) => Stream.value(entries));
  }

  Future<void> pumpDetails(
    WidgetTester tester,
    StoreListEntry entry,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: StoreDetailsScreen(
            controller: controller,
            currentUser: demoUser,
            entry: entry,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the store, its area and availability', (tester) async {
    final entry = StoreListEntry(store: store());
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    expect(find.text('مخبز الرمال'), findsOneWidget);
    expect(find.text('الرمال'), findsOneWidget);
    expect(find.text(Strings.available), findsOneWidget);
    expect(
      find.text(Strings.bagsRemaining(10, 300)),
      findsOneWidget,
    );
    expect(find.text(Strings.purchaseWindowRange('08:00', '10:00')),
        findsOneWidget);
  });

  testWidgets('explains a sold-out store instead of showing bags',
      (tester) async {
    final entry = StoreListEntry(store: store(bagsRemaining: 0));
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    expect(find.text(Strings.soldOut), findsWidgets);
    // The buy CTA is laid out but disabled.
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows my order today with a receipt action', (tester) async {
    final entry = StoreListEntry(
      store: store(),
      todayStatus: PurchaseStatus.notified,
      todayPurchaseId: 42,
    );
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    expect(find.text(Strings.myOrderTodayTitle), findsOneWidget);
    expect(find.text(Strings.orderReady), findsOneWidget);
    expect(find.text(Strings.paidBadge), findsOneWidget);
    expect(find.text(Strings.showReceiptButton), findsOneWidget);
  });

  testWidgets('no order section for a store the buyer is not using today',
      (tester) async {
    final entry = StoreListEntry(
      store: store(),
      lastPurchaseDate: '2026-01-01',
    );
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    expect(find.text(Strings.myOrderTodayTitle), findsNothing);
    expect(
      find.text(Strings.lastPurchaseFrom('2026-01-01')),
      findsOneWidget,
    );
  });

  testWidgets('pin toggle pins the store', (tester) async {
    final entry = StoreListEntry(store: store());
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    await tester.tap(find.text(Strings.pinStore));
    await tester.pump();

    verify(
      () => repo.setStorePinned(
        userId: demoUser.id,
        storeId: 1,
        pinned: true,
      ),
    ).called(1);
  });

  testWidgets('a pinned store offers the un-pin label', (tester) async {
    final entry = StoreListEntry(store: store(), pinned: true);
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    expect(find.text(Strings.unpinStore), findsOneWidget);
  });

  testWidgets('the buy action is available for an open store', (tester) async {
    final entry = StoreListEntry(store: store());
    stubEntries([entry]);
    await pumpDetails(tester, entry);

    expect(find.text(Strings.reserveBagButton), findsOneWidget);
  });
}
