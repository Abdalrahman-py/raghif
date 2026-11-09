import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/data/repositories/supabase_queue_repository.dart';

void main() {
  Map<String, dynamic> row({String? original}) => {
    'id': 'p1',
    'store_id': 's1',
    'user_id': 'u1',
    'purchase_date': '2026-11-06',
    'batch_number': 1,
    'status': 'waiting',
    'created_at': '2026-11-05T08:00:00Z',
    'original_purchase_date': original,
  };

  test('a postponed booking keeps the day it was first made for', () {
    final p = SupabaseQueueRepository.purchaseFromRow(
      row(original: '2026-11-05'),
    );
    expect(p.originalPurchaseDate, '2026-11-05');
  });

  test('a booking that was never postponed has no original date', () {
    expect(
      SupabaseQueueRepository.purchaseFromRow(row()).originalPurchaseDate,
      isNull,
    );
  });
}
