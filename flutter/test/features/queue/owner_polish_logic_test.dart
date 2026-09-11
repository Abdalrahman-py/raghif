import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/features/queue/queue_logic.dart';

PurchaseModel _p(
  int id,
  int batch,
  PurchaseStatus status,
) => PurchaseModel(
  id: id,
  storeId: 1,
  userId: id,
  purchaseDate: '2026-08-01',
  batchNumber: batch,
  status: status,
  createdAtMillis: id,
);

StoreModel _store({int remaining = 300, int limit = 300}) => StoreModel(
  id: 1,
  name: 'مخبز الرمال',
  isOpen: true,
  dailyBagLimit: limit,
  bagsRemaining: remaining,
  ownerPhone: '0599000001',
);

void main() {
  group('batchProgressForQueue', () {
    test('tallies picked / awaiting / waiting per batch, in order', () {
      final queue = [
        _p(1, 1, PurchaseStatus.collected),
        _p(2, 1, PurchaseStatus.notified),
        _p(3, 2, PurchaseStatus.waiting),
        _p(4, 2, PurchaseStatus.waiting),
      ];

      final progress = batchProgressForQueue(queue);

      expect(progress.map((p) => p.batch), [1, 2]);
      expect(progress[0].total, 2);
      expect(progress[0].picked, 1);
      expect(progress[0].awaitingPickup, 1);
      expect(progress[0].waiting, 0);
      expect(progress[0].allPicked, isFalse);

      expect(progress[1].picked, 0);
      expect(progress[1].waiting, 2);
    });

    test('a fully handed-over batch reports allPicked', () {
      final progress = batchProgressForQueue([
        _p(1, 1, PurchaseStatus.collected),
        _p(2, 1, PurchaseStatus.collected),
      ]);

      expect(progress.single.allPicked, isTrue);
    });

    test('empty queue → no batches', () {
      expect(batchProgressForQueue(const []), isEmpty);
    });
  });

  group('outstandingBefore', () {
    test('counts called-but-not-picked buyers from earlier batches only', () {
      final queue = [
        // Earlier batch, called, never picked up → counted.
        _p(1, 1, PurchaseStatus.notified),
        // Earlier batch, picked up → not counted.
        _p(2, 1, PurchaseStatus.collected),
        // Earlier batch (2 < 3), called, not picked up → counted.
        _p(3, 2, PurchaseStatus.notified),
        // The batch being released — not "outstanding before" it.
        _p(4, 3, PurchaseStatus.notified),
        // Not called yet → not counted.
        _p(5, 3, PurchaseStatus.waiting),
      ];

      expect(outstandingBefore(3, queue), 2);
    });

    test('nothing outstanding → zero', () {
      final queue = [_p(1, 1, PurchaseStatus.collected)];

      expect(outstandingBefore(2, queue), 0);
    });
  });

  group('pendingPickupCount', () {
    test('counts everything not yet collected', () {
      final queue = [
        _p(1, 1, PurchaseStatus.waiting),
        _p(2, 1, PurchaseStatus.notified),
        _p(3, 1, PurchaseStatus.collected),
      ];

      expect(pendingPickupCount(queue), 2);
    });
  });

  group('isLowStock', () {
    test('warns at or below the threshold', () {
      expect(isLowStock(_store(remaining: lowStockThreshold)), isTrue);
      expect(isLowStock(_store(remaining: lowStockThreshold + 1)), isFalse);
      expect(isLowStock(_store(remaining: 0)), isTrue);
    });
  });
}
