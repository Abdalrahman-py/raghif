import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/data/repositories/supabase_queue_repository.dart';
import 'package:raghif/domain/models/store_model.dart';

void main() {
  const open = StoreModel(
    id: 's',
    name: 'مخبز',
    isOpen: true,
    dailyBagLimit: 10,
    bagsRemaining: 5,
  );

  group('an administrator-set status gates booking', () {
    test('active and open with stock can be booked', () {
      expect(open.status, StoreStatus.active);
      expect(open.canPurchase, isTrue);
    });

    test('paused cannot be booked even when open with stock', () {
      final paused = open.copyWith(status: StoreStatus.paused);
      expect(paused.isPaused, isTrue);
      expect(paused.isOpen, isTrue);
      expect(paused.canPurchase, isFalse);
      expect(paused.isAvailable, isFalse);
    });

    test('archived cannot be booked', () {
      final archived = open.copyWith(status: StoreStatus.archived);
      expect(archived.isArchived, isTrue);
      expect(archived.canPurchase, isFalse);
    });

    test('the owner closing the store still closes it', () {
      expect(open.copyWith(isOpen: false).canPurchase, isFalse);
    });

    test('status takes part in equality', () {
      expect(open.copyWith(status: StoreStatus.paused), isNot(open));
    });
  });

  group('storeFromRow', () {
    Map<String, dynamic> row([String? status]) => {
      'id': 's',
      'name': 'مخبز',
      'is_open': true,
      'daily_bag_limit': 10,
      'bags_remaining': 5,
      if (status != null) 'status': status,
    };

    test('reads the status column', () {
      expect(
        SupabaseQueueRepository.storeFromRow(row('paused')).status,
        StoreStatus.paused,
      );
      expect(
        SupabaseQueueRepository.storeFromRow(row('archived')).status,
        StoreStatus.archived,
      );
    });

    test('a server that has no status column yet means active', () {
      final store = SupabaseQueueRepository.storeFromRow(row());
      expect(store.status, StoreStatus.active);
      expect(store.canPurchase, isTrue);
    });
  });
}
