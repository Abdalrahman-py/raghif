import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/domain/models/purchase_model.dart';

void main() {
  const today = '2026-11-22';
  const tomorrow = '2026-11-23';
  PurchaseModel p(String id, String date, PurchaseStatus status) =>
      PurchaseModel(
        id: id,
        storeId: 's',
        userId: 'u',
        purchaseDate: date,
        batchNumber: 1,
        status: status,
        createdAtMillis: 0,
      );

  List<String> ids(List<PurchaseModel> rows) =>
      bookingsToShow(rows, today).map((r) => r.id).toList();

  test('today and tomorrow both show, oldest date first', () {
    expect(
      ids([
        p('b', tomorrow, PurchaseStatus.waiting),
        p('a', today, PurchaseStatus.notified),
      ]),
      ['a', 'b'],
    );
  });

  test("today's collected booking stays; a collected future one does not", () {
    expect(
      ids([
        p('a', today, PurchaseStatus.collected),
        p('b', tomorrow, PurchaseStatus.collected),
      ]),
      ['a'],
    );
  });

  test('past bookings never show', () {
    expect(ids([p('old', '2026-11-21', PurchaseStatus.waiting)]), isEmpty);
  });
}
