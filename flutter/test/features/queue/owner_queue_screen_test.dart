import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/features/queue/owner_queue_screen.dart';
import 'package:raghif/features/queue/queue_controller.dart';
import 'package:raghif/features/queue/queue_logic.dart';

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

void main() {
  group('OwnerQueueScreen pickup helpers', () {
    testWidgets('shows national ID + phone on buyer rows and filters by ID '
        'suffix while hiding the notify button during a search', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = QueueRepositoryImpl(db);
      await repository.ensureSeeded();
      final controller = QueueController(repository);

      final store = controller.stores.first;
      final buyers = await db.select(db.users).get();
      final buyer = buyers.firstWhere((u) => u.role == 'buyer');
      final date = todayDateString();
      final purchase = await controller.buy(
        userId: buyer.id,
        storeId: store.id,
        date: date,
      );
      expect(purchase.userNationalId, buyer.nationalId);

      await tester.pumpWidget(
        wrapWithMaterial(
          OwnerQueueScreen(controller: controller, storeId: store.id),
        ),
      );
      await tester.pumpAndSettle();

      // Row carries the buyer's national ID so pickup identity can be verified.
      expect(find.textContaining(buyer.nationalId), findsOneWidget);
      expect(find.textContaining(buyer.phone), findsOneWidget);
      // A waiting buyer means the next batch can be notified — button visible.
      expect(find.textContaining(Strings.notifyNextBatch(1)), findsOneWidget);
      // Scan entry point is present.
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);

      // Searching by ID suffix keeps the matching row…
      await tester.enterText(
        find.byType(TextField),
        buyer.nationalId.substring(buyer.nationalId.length - 3),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(buyer.nationalId), findsOneWidget);
      // …but the notify action is hidden while searching, so a lookup
      // can never accidentally release a batch.
      expect(find.textContaining(Strings.notifyNextBatch(1)), findsNothing);

      // A non-matching suffix shows the no-results state and no rows.
      await tester.enterText(find.byType(TextField), '000');
      await tester.pumpAndSettle();
      expect(find.text(Strings.buyerSearchNoResults), findsOneWidget);
      expect(find.textContaining(buyer.nationalId), findsNothing);

      // Clearing the search restores the full queue and the notify button.
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.textContaining(buyer.nationalId), findsOneWidget);
      expect(find.textContaining(Strings.notifyNextBatch(1)), findsOneWidget);

      await db.close();
    });
  });
}
