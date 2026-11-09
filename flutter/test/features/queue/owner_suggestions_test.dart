import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/store_day_summary.dart';
import 'package:raghif/features/queue/queue_logic.dart';

PurchaseModel _p(int id, int batch, PurchaseStatus status) => PurchaseModel(
  id: 'purchase-$id',
  storeId: 'store-1',
  userId: 'user-$id',
  purchaseDate: '2026-08-01',
  batchNumber: batch,
  status: status,
  createdAtMillis: id,
);

void main() {
  group('suggestNextBatch', () {
    test('suggests the next batch once earlier buyers are mostly gone', () {
      final queue = [
        for (var i = 0; i < 18; i++) _p(i, 1, PurchaseStatus.collected),
        _p(30, 1, PurchaseStatus.notified),
        _p(31, 1, PurchaseStatus.notified),
        _p(40, 2, PurchaseStatus.waiting),
        _p(41, 2, PurchaseStatus.waiting),
        _p(42, 2, PurchaseStatus.waiting),
      ];
      final s = suggestNextBatch(queue, batchSize: 20);
      expect(s?.batch, 2);
      expect(s?.count, 3);
    });

    test('stays quiet while many called buyers are still on their way', () {
      final queue = [
        for (var i = 0; i < 12; i++) _p(i, 1, PurchaseStatus.notified),
        _p(40, 2, PurchaseStatus.waiting),
      ];
      expect(suggestNextBatch(queue, batchSize: 20), isNull);
    });

    test('stays quiet when nobody is waiting', () {
      final queue = [_p(1, 1, PurchaseStatus.collected)];
      expect(suggestNextBatch(queue, batchSize: 20), isNull);
    });

    test('suggests the first batch when nothing has been called yet', () {
      final queue = [_p(1, 1, PurchaseStatus.waiting)];
      expect(suggestNextBatch(queue, batchSize: 20)?.batch, 1);
    });
  });

  group('weeklyStats', () {
    test('totals the newest seven days and finds the best day', () {
      final days = [
        for (var d = 1; d <= 9; d++)
          StoreDaySummary(
            date: '2026-08-${d.toString().padLeft(2, '0')}',
            sold: d * 10,
            collected: d * 9,
            notCollected: d,
            cashTotal: d * 5.0,
          ),
        const StoreDaySummary(
          date: '2026-08-10',
          sold: 0,
          collected: 0,
          notCollected: 0,
        ),
      ];
      final w = weeklyStats(days);
      // Newest 7 entries are 10th (empty, skipped) and 4th..9th.
      expect(w.days, 6);
      expect(w.sold, 40 + 50 + 60 + 70 + 80 + 90);
      expect(w.bestDate, '2026-08-09');
      expect(w.collectedPercent, 90);
    });

    test('is all zeros with no sales', () {
      final w = weeklyStats(const []);
      expect(w.sold, 0);
      expect(w.collectedPercent, 0);
      expect(w.dailyAverage, 0);
      expect(w.bestDate, isNull);
    });
  });
}
