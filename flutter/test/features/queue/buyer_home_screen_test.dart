import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/buyer_home_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockQueueRepository repo;
  late MockAuthBloc authBloc;
  late QueueController controller;

  const demoUser = DemoUser(
    id: 'user-buyer',
    phone: demoBuyerPhone,
    pin: '1234',
    role: UserRole.buyer,
    name: 'أحمد ناصر',
  );

  PurchaseModel order({
    PurchaseStatus status = PurchaseStatus.waiting,
    int batchNumber = 2,
    String id = 'purchase-7',
    String date = '2026-08-01',
    String? paymentMethod,
  }) => PurchaseModel(
    id: id,
    storeId: 'store-1',
    userId: 'user-1',
    purchaseDate: date,
    paymentMethod: paymentMethod,
    batchNumber: batchNumber,
    status: status,
    createdAtMillis: 1,
    userName: 'أحمد ناصر',
    userPhone: '0599111111',
    storeName: 'مخبز الرمال',
  );

  setUp(() {
    repo = MockQueueRepository();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    when(() => repo.watchStores()).thenAnswer((_) => const Stream.empty());
    controller = QueueController(repo);
  });

  Future<void> pumpHome(WidgetTester tester) async {
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
          home: BuyerHomeScreen(controller: controller, currentUser: demoUser),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void stubOrders(List<PurchaseModel> orders) {
    when(
      () => repo.upcomingPurchases(any(), any()),
    ).thenAnswer((_) async => orders);
  }

  void stubTodayOrder(PurchaseModel? purchase) =>
      stubOrders([if (purchase != null) purchase]);

  Future<void> stubLiveOrder(PurchaseModel purchase) async {
    when(
      () => repo.watchPurchaseById(purchase.id),
    ).thenAnswer((_) => Stream.value(purchase));
  }

  testWidgets('no order today → plain empty state, no browse button', (
    tester,
  ) async {
    stubTodayOrder(null);
    await pumpHome(tester);

    expect(find.text(Strings.buyerHomeNoOrder), findsOneWidget);
    // Nothing to browse from here: the stores are on the home tab.
    expect(find.text(Strings.browseStoresButton), findsNothing);
  });

  testWidgets('server unreachable → says so with a retry, not "no order"', (
    tester,
  ) async {
    when(
      () => repo.upcomingPurchases(any(), any()),
    ).thenAnswer((_) async => throw const BackendUnavailableException('x'));
    await pumpHome(tester);

    expect(find.text(Strings.offlineRead), findsOneWidget);
    expect(find.text(Strings.buyerHomeNoOrder), findsNothing);

    stubTodayOrder(null);
    await tester.tap(find.text(Strings.retryButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.offlineRead), findsNothing);
    expect(find.text(Strings.buyerHomeNoOrder), findsOneWidget);
  });

  testWidgets('shows the current order with store, status and batch', (
    tester,
  ) async {
    final purchase = order(status: PurchaseStatus.notified, batchNumber: 3);
    stubTodayOrder(purchase);
    await stubLiveOrder(purchase);

    await pumpHome(tester);

    expect(find.text('مخبز الرمال'), findsOneWidget);
    expect(find.text('#purchase-7'), findsOneWidget);
    expect(find.text(Strings.buyerHomeBatch(3)), findsOneWidget);
    // Ready-for-pickup reassurance, not an invented ETA.
    expect(find.text(Strings.batchReadyNotificationBody), findsOneWidget);
  });

  testWidgets('a waiting order shows the waiting state without an ETA', (
    tester,
  ) async {
    final purchase = order(status: PurchaseStatus.waiting);
    stubTodayOrder(purchase);
    await stubLiveOrder(purchase);

    await pumpHome(tester);

    // The banner says it; no separate status chip repeats it.
    expect(find.text(Strings.statusWaiting), findsNothing);
    expect(find.text(Strings.batchReadyNotificationBody), findsNothing);
  });

  testWidgets('offers the receipt QR at any time', (tester) async {
    final purchase = order();
    stubTodayOrder(purchase);
    await stubLiveOrder(purchase);

    await pumpHome(tester);

    expect(find.text(Strings.showReceiptButton), findsOneWidget);
  });

  testWidgets('an empty home offers no receipt button', (tester) async {
    stubTodayOrder(null);
    await pumpHome(tester);

    expect(find.text(Strings.showReceiptButton), findsNothing);
  });

  testWidgets('payment chip: paid only when prepaid through the wallet', (
    tester,
  ) async {
    final cashDue = Strings.cashDueChip(StoreModel.defaultBagPrice);
    for (final (method, paid) in [
      ('jawwal_pay', true),
      ('simulated', false),
      (null, false),
    ]) {
      final purchase = order(paymentMethod: method);
      stubTodayOrder(purchase);
      await stubLiveOrder(purchase);
      await pumpHome(tester);

      expect(
        find.text(Strings.paidBadge),
        paid ? findsOneWidget : findsNothing,
        reason: '$method',
      );
      expect(find.text(cashDue), paid ? findsNothing : findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('today and a postponed tomorrow booking each get a card', (
    tester,
  ) async {
    final todays = order(id: 'today-1', date: '2026-08-01');
    final moved = order(id: 'tomorrow-1', date: '2099-01-02');
    stubOrders([todays, moved]);
    await stubLiveOrder(todays);
    await stubLiveOrder(moved);

    await pumpHome(tester);

    expect(find.text('#today-1'), findsOneWidget);
    expect(find.text('#tomorrow-1'), findsOneWidget);
    expect(find.text(Strings.showReceiptButton), findsNWidgets(2));
  });
}
