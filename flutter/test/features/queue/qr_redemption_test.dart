import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/features/queue/qr_payload.dart';
import 'package:raghif/features/queue/qr_redemption.dart';
import 'package:raghif/domain/models/purchase_model.dart';

void main() {
  const payload = QrPayload(
    purchaseId: '7',
    userName: 'أحمد',
    storeName: 'مخبز الرمال',
    purchaseDate: '2026-09-05',
  );

  PurchaseModel purchase({
    int id = 7,
    int storeId = 1,
    PurchaseStatus status = PurchaseStatus.notified,
  }) {
    return PurchaseModel(
      id: id,
      storeId: storeId,
      userId: 1,
      purchaseDate: '2026-09-05',
      batchNumber: 1,
      status: status,
      createdAtMillis: 0,
      userName: 'أحمد',
      userPhone: '0599000001',
      userNationalId: '900111222',
      storeName: 'مخبز الرمال',
    );
  }

  group('evaluateQrRedemption', () {
    test('notified purchase at this store -> checkedIn', () {
      final result = evaluateQrRedemption(
        payload: payload,
        purchase: purchase(),
        ownerStoreId: 1,
      );
      expect(result.outcome, QrRedemptionOutcome.checkedIn);
      expect(result.purchase?.id, 7);
    });

    test('already collected -> duplicate scan', () {
      final result = evaluateQrRedemption(
        payload: payload,
        purchase: purchase(status: PurchaseStatus.collected),
        ownerStoreId: 1,
      );
      expect(result.outcome, QrRedemptionOutcome.alreadyCollected);
    });

    test('waiting purchase -> batch not called yet, carries batch number', () {
      final result = evaluateQrRedemption(
        payload: payload,
        purchase: purchase(status: PurchaseStatus.waiting),
        ownerStoreId: 1,
      );
      expect(result.outcome, QrRedemptionOutcome.batchNotCalledYet);
      expect(result.batchNumber, 1);
    });

    test('no local match -> notFoundHere, payload still available', () {
      final result = evaluateQrRedemption(
        payload: payload,
        purchase: null,
        ownerStoreId: 1,
      );
      expect(result.outcome, QrRedemptionOutcome.notFoundHere);
      expect(result.payload.userName, 'أحمد');
      expect(result.purchase, isNull);
    });

    test('purchase belonging to another store -> wrongStore', () {
      final result = evaluateQrRedemption(
        payload: payload,
        purchase: purchase(storeId: 2),
        ownerStoreId: 1,
      );
      expect(result.outcome, QrRedemptionOutcome.wrongStore);
      expect(result.actualStoreName, 'مخبز الرمال');
    });
  });
}
