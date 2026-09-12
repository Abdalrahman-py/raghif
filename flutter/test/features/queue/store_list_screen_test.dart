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
import 'package:raghif/features/queue/store_list_screen.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Replaces the old pixel golden on this screen: a golden breaks on every
/// layout tweak and on every Flutter upgrade (font/AA rendering shifts), while
/// these assertions describe the behaviour we actually care about — search,
/// area chips, pinning, and the richer card for stores the buyer uses.
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

  StoreModel store(
    int id,
    String name, {
    String area = '',
    bool isOpen = true,
    int bagsRemaining = 10,
  }) => StoreModel(
    id: id,
    name: name,
    isOpen: isOpen,
    dailyBagLimit: 300,
    bagsRemaining: bagsRemaining,
    ownerPhone: '05990000$id',
    area: area,
  );

  setUp(() {
    repo = MockQueueRepository();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    when(() => repo.watchStores()).thenAnswer((_) => const Stream.empty());
    when(
      () => repo.setStorePinned(
        userId: any(named: 'userId'),
        storeId: any(named: 'storeId'),
        pinned: any(named: 'pinned'),
      ),
    ).thenAnswer((_) async {});
    controller = QueueController(repo);
  });

  void stubEntries(List<StoreListEntry> entries) {
    when(
      () => repo.watchStoreListForUser(
        userId: any(named: 'userId'),
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) => Stream.value(entries));
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall enough that all three cards build (ListView is lazy), and a
    // phone-ish width so the layout matches the app.
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
          home: StoreListScreen(controller: controller, currentUser: demoUser),
        ),
      ),
    );
    // Store list arrives through the controller's own subscription.
    await tester.pump();
  }

  List<StoreListEntry> threeStores() => [
    StoreListEntry(
      store: store(1, 'مخبز الرمال', area: 'الرمال'),
      pinned: true,
    ),
    StoreListEntry(
      store: store(2, 'مخبز الشاطئ', area: 'الشاطئ'),
      todayStatus: PurchaseStatus.waiting,
      lastPurchaseDate: '2026-01-01',
    ),
    StoreListEntry(
      store: store(3, 'مخبز النصيرات', area: 'النصيرات', isOpen: false, bagsRemaining: 0),
    ),
  ];

  testWidgets('renders search, area chips and every store', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    expect(find.text(Strings.storeSearchHint), findsOneWidget);
    expect(find.text(Strings.areaAllLabel), findsOneWidget);
    expect(find.text('الرمال'), findsWidgets);
    expect(find.text('مخبز الرمال'), findsOneWidget);
    expect(find.text('مخبز الشاطئ'), findsOneWidget);
    expect(find.text('مخبز النصيرات'), findsOneWidget);
  });

  testWidgets('the familiar store card carries order, paid and last-visit detail',
      (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    expect(find.text(Strings.myStoreBadge), findsOneWidget);
    expect(find.text(Strings.orderWaiting), findsOneWidget);
    expect(find.text(Strings.paidBadge), findsOneWidget);
    expect(
      find.text(Strings.lastPurchaseFrom('2026-01-01')),
      findsOneWidget,
    );
  });

  testWidgets('search narrows the list by store name', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'الشاطئ');
    await tester.pump();

    expect(find.text('مخبز الشاطئ'), findsOneWidget);
    expect(find.text('مخبز الرمال'), findsNothing);
  });

  testWidgets('search also matches the area', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'النصيرات');
    await tester.pump();

    expect(find.text('مخبز النصيرات'), findsOneWidget);
    expect(find.text('مخبز الرمال'), findsNothing);
  });

  testWidgets('tapping an area chip filters to that area', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    await tester.tap(find.text('الشاطئ').first);
    await tester.pump();

    expect(find.text('مخبز الشاطئ'), findsOneWidget);
    expect(find.text('مخبز الرمال'), findsNothing);
  });

  testWidgets('no matches shows the empty-search message', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump();

    expect(find.text(Strings.noMatchingStores), findsOneWidget);
  });

  testWidgets('pin button pins an un-pinned store to the top', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    // Two un-pinned stores in the list; tapping the first one pins it.
    await tester.tap(find.byTooltip(Strings.pinStore).first);
    await tester.pump();

    verify(
      () => repo.setStorePinned(
        userId: demoUser.id,
        storeId: any(named: 'storeId'),
        pinned: true,
      ),
    ).called(1);
  });

  testWidgets('an already-pinned store offers un-pinning', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    expect(find.byTooltip(Strings.unpinStore), findsOneWidget);
  });

  testWidgets('tapping a store card opens its details screen', (tester) async {
    stubEntries(threeStores());
    await pumpScreen(tester);

    await tester.tap(find.text('مخبز الرمال'));
    await tester.pumpAndSettle();

    expect(find.text(Strings.storeDetailsTitle), findsOneWidget);
  });
}
