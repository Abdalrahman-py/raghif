import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/tables/converters.dart';
import 'package:raghif/domain/models/store_list_entry.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/features/queue/store_list_logic.dart';

StoreModel _store(
  int id,
  String name, {
  String area = '',
  bool isOpen = true,
  int bagsRemaining = 10,
}) => StoreModel(
  id: id,
  name: name,
  isOpen: isOpen,
  dailyBagLimit: 300,
  bagsRemaining: bagsRemaining,
  ownerPhone: '05990000$id',
  area: area,
);

void main() {
  group('sortStoreEntries', () {
    test('pinned stores come first, then today orders, then history', () {
      final pinned = StoreListEntry(
        store: _store(1, 'مخبز الرمال'),
        pinned: true,
      );
      final today = StoreListEntry(
        store: _store(2, 'مخبز الشاطئ'),
        todayStatus: PurchaseStatus.waiting,
        lastPurchaseDate: '2026-09-05',
      );
      final history = StoreListEntry(
        store: _store(3, 'مخبز النصيرات'),
        lastPurchaseDate: '2026-09-01',
      );
      final fresh = StoreListEntry(store: _store(4, 'مخبز الأمل'));

      final sorted = sortStoreEntries([fresh, history, today, pinned]);

      expect(sorted.map((e) => e.store.id).toList(), [1, 2, 3, 4]);
    });

    test('within a group, the most recent purchase wins', () {
      final older = StoreListEntry(
        store: _store(1, 'مخبز الرمال'),
        lastPurchaseDate: '2026-09-01',
      );
      final newer = StoreListEntry(
        store: _store(2, 'مخبز الشاطئ'),
        lastPurchaseDate: '2026-09-05',
      );

      final sorted = sortStoreEntries([older, newer]);

      expect(sorted.map((e) => e.store.id).toList(), [2, 1]);
    });

    test('otherwise alphabetical by store name', () {
      final a = StoreListEntry(store: _store(1, 'أ'));
      final b = StoreListEntry(store: _store(2, 'ب'));

      final sorted = sortStoreEntries([b, a]);

      expect(sorted.map((e) => e.store.name).toList(), ['أ', 'ب']);
    });

    test('does not mutate the input list', () {
      final input = [
        StoreListEntry(store: _store(1, 'ب')),
        StoreListEntry(store: _store(2, 'أ')),
      ];

      sortStoreEntries(input);

      expect(input.first.store.name, 'ب');
    });
  });

  group('filterStoreEntries', () {
    final entries = [
      StoreListEntry(store: _store(1, 'مخبز الرمال', area: 'الرمال')),
      StoreListEntry(store: _store(2, 'مخبز الشاطئ', area: 'الشاطئ')),
      StoreListEntry(store: _store(3, 'مخبز النصيرات', area: 'النصيرات')),
    ];

    test('filters by store name', () {
      final visible = filterStoreEntries(entries, query: 'الشاطئ');

      expect(visible.map((e) => e.store.id).toList(), [2]);
    });

    test('filters by area name too', () {
      final visible = filterStoreEntries(entries, query: 'النصيرات');

      expect(visible.map((e) => e.store.id).toList(), [3]);
    });

    test('filters by selected area chip', () {
      final visible = filterStoreEntries(entries, area: 'الرمال');

      expect(visible.map((e) => e.store.id).toList(), [1]);
    });

    test('blank query and null area return everything', () {
      expect(filterStoreEntries(entries, query: '  ').length, 3);
      expect(filterStoreEntries(entries).length, 3);
    });
  });

  group('areasOf', () {
    test('returns distinct non-empty areas in first-seen order', () {
      final entries = [
        StoreListEntry(store: _store(1, 'أ', area: 'الرمال')),
        StoreListEntry(store: _store(2, 'ب', area: '')),
        StoreListEntry(store: _store(3, 'ج', area: 'الشاطئ')),
        StoreListEntry(store: _store(4, 'د', area: 'الرمال')),
      ];

      expect(areasOf(entries), ['الرمال', 'الشاطئ']);
    });
  });

  group('purchaseDateLabel', () {
    test('today and yesterday get friendly labels', () {
      expect(purchaseDateLabel('2026-09-06', '2026-09-06'), 'اليوم');
      expect(purchaseDateLabel('2026-09-05', '2026-09-06'), 'أمس');
    });

    test('older dates stay as the raw date', () {
      expect(purchaseDateLabel('2026-09-01', '2026-09-06'), '2026-09-01');
    });

    test('handles month boundaries', () {
      expect(purchaseDateLabel('2026-08-31', '2026-09-01'), 'أمس');
    });
  });

  group('StoreListEntry flags', () {
    test('awaitingPickup covers waiting and notified, not collected', () {
      expect(
        StoreListEntry(
          store: _store(1, 'أ'),
          todayStatus: PurchaseStatus.waiting,
        ).awaitingPickup,
        isTrue,
      );
      expect(
        StoreListEntry(
          store: _store(1, 'أ'),
          todayStatus: PurchaseStatus.notified,
        ).awaitingPickup,
        isTrue,
      );
      expect(
        StoreListEntry(
          store: _store(1, 'أ'),
          todayStatus: PurchaseStatus.collected,
        ).awaitingPickup,
        isFalse,
      );
    });

    test('isFamiliar is true for history even without an order today', () {
      final entry = StoreListEntry(
        store: _store(1, 'أ'),
        lastPurchaseDate: '2026-09-01',
      );

      expect(entry.isFamiliar, isTrue);
      expect(entry.hasOrderToday, isFalse);
    });
  });
}
