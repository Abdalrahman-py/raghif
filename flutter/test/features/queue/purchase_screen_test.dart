import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/domain/models/purchase_model.dart';

void main() {
  group('Strings unit tests', () {
    test(
      'dailyLimitReachedOtherStore handles names with and without bakery prefix',
      () {
        expect(
          Strings.dailyLimitReachedOtherStore('مخبز الرمال'),
          'لقد قمت بالحجز من مخبز الرمال اليوم بالفعل',
        );
        expect(
          Strings.dailyLimitReachedOtherStore('الشاطئ'),
          'لقد قمت بالحجز من مخبز الشاطئ اليوم بالفعل',
        );
        expect(
          Strings.dailyLimitReachedOtherStore(''),
          'لقد قمت بالحجز من مخبز آخر اليوم بالفعل',
        );
        expect(
          Strings.dailyLimitReachedOtherStore('   '),
          'لقد قمت بالحجز من مخبز آخر اليوم بالفعل',
        );
      },
    );

    test('waitingReassurance is non-empty reassurance text', () {
      expect(Strings.waitingReassurance, isNotEmpty);
      expect(Strings.waitingReassurance, 'سيتم إشعارك عندما يحين دورك');
    });
  });

  group('Price and payment record', () {
    test('prices read as whole shekels or with two decimals', () {
      expect(Strings.shekels(3), '3');
      expect(Strings.shekels(4.5), '4.50');
      expect(Strings.payWalletButton(3), 'ادفع 3 شيكل');
      expect(StoreModel.defaultBagPrice, 3.0);
    });

    test('a wallet payment marks the booking as prepaid', () {
      const unpaid = PurchaseModel(
        id: 'p',
        storeId: 's',
        userId: 'u',
        purchaseDate: '2026-11-05',
        batchNumber: 1,
        status: PurchaseStatus.waiting,
        createdAtMillis: 0,
      );
      expect(unpaid.isPrepaid, isFalse);
      expect(unpaid.copyWith(paymentMethod: 'jawwal_pay').isPrepaid, isTrue);
      expect(unpaid.copyWith(paymentMethod: 'cash').isPrepaid, isFalse);
    });
  });
}
