import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/cache/offline_cache.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/store_list_entry.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const store = StoreModel(
    id: 's1',
    name: 'مخبز الرمال',
    isOpen: true,
    dailyBagLimit: 100,
    bagsRemaining: 40,
    area: 'الرمال',
    governorate: 'غزة',
    openTime: '06:00',
    closeTime: '14:00',
    bagPrice: 3,
  );

  const purchase = PurchaseModel(
    id: 'p1',
    storeId: 's1',
    userId: 'u1',
    purchaseDate: '2026-11-06',
    batchNumber: 2,
    status: PurchaseStatus.notified,
    createdAtMillis: 1000,
    userName: 'أحمد',
    storeName: 'مخبز الرمال',
    paymentMethod: 'jawwal_pay',
    originalPurchaseDate: '2026-11-05',
  );

  test('the bakery list survives a round trip, per user', () async {
    final cache = OfflineCache();
    final entry = StoreListEntry(
      store: store,
      pinned: true,
      todayStatus: PurchaseStatus.waiting,
      todayPurchaseId: 'p1',
      lastPurchaseDate: '2026-11-06',
    );
    await cache.saveStoreList('u1', [entry]);

    expect(await cache.loadStoreList('u1'), [entry]);
    expect(await cache.loadStoreList('someone-else'), isEmpty);
  });

  test('a receipt survives a round trip', () async {
    final cache = OfflineCache();
    await cache.savePurchase(purchase);
    expect(await cache.loadPurchase('p1'), purchase);
    expect(await cache.loadPurchase('missing'), isNull);
  });

  test('only the latest receipts are kept', () async {
    final cache = OfflineCache();
    for (var i = 0; i < 12; i++) {
      await cache.savePurchase(purchase.copyWith(id: 'p$i'));
    }
    expect(await cache.loadPurchase('p0'), isNull);
    expect(await cache.loadPurchase('p1'), isNull);
    expect(await cache.loadPurchase('p11'), isNotNull);
  });

  test('clear removes everything (sign-out)', () async {
    final cache = OfflineCache();
    await cache.savePurchase(purchase);
    await cache.saveStoreList('u1', [StoreListEntry(store: store)]);
    await cache.clear();
    expect(await cache.loadPurchase('p1'), isNull);
    expect(await cache.loadStoreList('u1'), isEmpty);
  });

  test('a broken saved value reads as empty, not as a crash', () async {
    SharedPreferences.setMockInitialValues({
      'cache.stores.u1': 'not json',
      'cache.purchase.p1': '{"id":1}',
    });
    final cache = OfflineCache();
    expect(await cache.loadStoreList('u1'), isEmpty);
    expect(await cache.loadPurchase('p1'), isNull);
  });

  test('the owner store and the queue survive a round trip', () async {
    final cache = OfflineCache();
    await cache.saveOwnerStore('o1', store);
    await cache.saveQueue('s1', '2026-11-06', [purchase]);

    expect(await cache.loadOwnerStore('o1'), store);
    expect(await cache.loadOwnerStore('other'), isNull);
    expect(await cache.loadQueue('s1', '2026-11-06'), [purchase]);
    // A queue saved for another day is not today's queue.
    expect(await cache.loadQueue('s1', '2026-11-07'), isNull);
  });
}
