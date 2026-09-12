import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/store_day_summary.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:raghif/features/queue/owner_history_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

void main() {
  late MockQueueRepository repo;
  late QueueController controller;

  setUp(() {
    repo = MockQueueRepository();
    when(() => repo.watchStores()).thenAnswer((_) => const Stream.empty());
    controller = QueueController(repo);
  });

  PurchaseModel purchase(
    int id,
    PurchaseStatus status, {
    String name = 'أحمد ناصر',
    String? nationalId = '900111222',
    String? phone = '0599111111',
  }) => PurchaseModel(
    id: id,
    storeId: 1,
    userId: 1,
    purchaseDate: '2026-08-01',
    batchNumber: 1,
    status: status,
    createdAtMillis: 1,
    userName: name,
    userPhone: phone,
    userNationalId: nationalId,
  );

  Future<void> pumpHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: OwnerHistoryScreen(controller: controller, storeId: 1),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists each day with sold / collected / outstanding counts',
      (tester) async {
    when(() => repo.getDailySummaries(1, limit: any(named: 'limit')))
        .thenAnswer(
      (_) async => const [
        StoreDaySummary(
          date: '2026-08-02',
          sold: 120,
          collected: 117,
          notCollected: 3,
        ),
        StoreDaySummary(
          date: '2026-08-01',
          sold: 8,
          collected: 8,
          notCollected: 0,
        ),
      ],
    );

    await pumpHistory(tester);

    expect(find.text('2026-08-02'), findsOneWidget);
    expect(find.text(Strings.historySold(120)), findsOneWidget);
    expect(find.text(Strings.historyCollected(117)), findsOneWidget);
    expect(find.text(Strings.historyNotCollected(3)), findsOneWidget);
    // A fully collected day doesn't warn about leftovers.
    expect(find.text(Strings.historyNotCollected(0)), findsNothing);
  });

  testWidgets('empty history shows the placeholder', (tester) async {
    when(() => repo.getDailySummaries(1, limit: any(named: 'limit')))
        .thenAnswer((_) async => const []);

    await pumpHistory(tester);

    expect(find.text(Strings.historyEmpty), findsOneWidget);
  });

  testWidgets('tapping a day opens that day with its buyers', (tester) async {
    when(() => repo.getDailySummaries(1, limit: any(named: 'limit')))
        .thenAnswer(
      (_) async => const [
        StoreDaySummary(
          date: '2026-08-02',
          sold: 2,
          collected: 1,
          notCollected: 1,
        ),
      ],
    );
    when(() => repo.getQueueForStore(1, '2026-08-02')).thenAnswer(
      (_) async => [
        purchase(1, PurchaseStatus.collected),
        purchase(2, PurchaseStatus.waiting, name: 'محمود سعيد'),
      ],
    );

    await pumpHistory(tester);
    await tester.tap(find.text('2026-08-02'));
    await tester.pumpAndSettle();

    expect(find.text(Strings.historyDayTitle('2026-08-02')), findsOneWidget);
    expect(find.text('أحمد ناصر'), findsOneWidget);
    expect(find.text('محمود سعيد'), findsOneWidget);
    expect(find.text(Strings.statusCollectedShort), findsWidgets);
    expect(find.text(Strings.statusWaitingShort), findsWidgets);
  });
}
