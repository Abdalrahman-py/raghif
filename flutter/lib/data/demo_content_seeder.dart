import 'package:drift/drift.dart';

import '../core/auth/demo_accounts.dart';
import '../core/auth/pin_hash.dart';
import '../core/database/app_database.dart';
import '../features/queue/queue_logic.dart';

/// Richer demo content for the prototype walkthrough (P0-1).
///
/// The base `ensureSeeded()` calls create exactly the pilot footprint: the
/// demo buyer + owner, and 3 stores. This seeder layers the full demo story
/// on top, so a fresh install shows a believable day at first glance:
///
/// - 7 stores instead of 3 (extra bakeries, open/closed/sold-out variety)
/// - ~9 dummy registered buyers (distinct from the live demo buyer أحمد)
/// - today's purchases at the demo store spanning all three pickup states
///   (WAITING / NOTIFIED / COLLECTED), grouped into 3 batches of 3
///
/// Constraints honored:
/// - The live demo buyer (أحمد ناصر, [demoBuyerNationalId]) gets NO seeded
///   purchase — the one-bag-per-ID-per-day rule would block the live buy.
/// - Dummy buyers carry their own IDs and phones.
/// - Kept OUT of `ensureSeeded()` on purpose, so existing tests that call
///   `ensureSeeded()` see the old minimal footprint and stay green.
///
/// Guard: runs only when the database is still at the base footprint (no
/// purchases ever, no extra stores/users) — i.e. right after a fresh install.
/// Re-running on an already-seeded install is a no-op.
class DemoContentSeeder {
  DemoContentSeeder(this._db);

  final AppDatabase _db;

  /// Extra bakeries beyond the 3 base ones (total = 7).
  static const _extraStores = [
    (
      name: 'مخبز الأمل',
      ownerPhone: '0599000005',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 60,
      openTime: '07:00',
      closeTime: '09:00',
    ),
    (
      name: 'مخبز الزيتون',
      ownerPhone: '0599000006',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 150,
      openTime: '07:30',
      closeTime: '09:30',
    ),
    (
      name: 'مخبز النور',
      ownerPhone: '0599000007',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 0,
      openTime: '06:30',
      closeTime: '08:30',
    ),
    (
      name: 'مخبز السلام',
      ownerPhone: '0599000008',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 200,
      openTime: '08:00',
      closeTime: '10:00',
    ),
  ];

  /// Dummy buyers (9). Live demo buyer أحمد (900111222) intentionally absent.
  static const _dummyBuyers = [
    (name: 'محمود سعيد', nationalId: '900111333', phone: '0599111333'),
    (name: 'إبراهيم حمدان', nationalId: '900111444', phone: '0599111444'),
    (name: 'سارة عبد الرحمن', nationalId: '900111555', phone: '0599111555'),
    (name: 'ليلى المصري', nationalId: '900111666', phone: '0599111666'),
    (name: 'عمر الخطيب', nationalId: '900111777', phone: '0599111777'),
    (name: 'فاطمة الزهراء', nationalId: '900111888', phone: '0599111888'),
    (name: 'يوسف النجار', nationalId: '900111999', phone: '0599111999'),
    (name: 'مريم خالد', nationalId: '900222111', phone: '0599222111'),
    (name: 'حسن عباس', nationalId: '900222222', phone: '0599222333'),
  ];

  /// Seeded queue sizes per status at the demo store (batch size 3 ⇒ 3 batches).
  Future<void> seedIfFresh() async {
    // No-op unless the DB is still at the base footprint: no purchases at
    // all, and only the base stores/users present.
    final purchases = await _db.select(_db.purchases).get();
    if (purchases.isNotEmpty) return;
    final stores = await _db.select(_db.stores).get();
    if (stores.length > 3) return;
    final users = await _db.select(_db.users).get();
    if (users.length > 2) return;

    await _db.transaction(() async {
      // 1) Extra stores.
      for (final s in _extraStores) {
        final exists = await (_db.select(_db.stores)
              ..where((row) => row.ownerPhone.equals(s.ownerPhone)))
            .getSingleOrNull();
        if (exists != null) continue;
        await _db.into(_db.stores).insert(
              StoresCompanion.insert(
                name: s.name,
                ownerPhone: s.ownerPhone,
                isOpen: Value(s.isOpen),
                dailyBagLimit: s.dailyBagLimit,
                bagsRemaining: s.bagsRemaining,
                openTime: Value(s.openTime),
                closeTime: Value(s.closeTime),
              ),
            );
      }

      // 2) Dummy buyers.
      final buyerIds = <int>[];
      for (final b in _dummyBuyers) {
        if (b.nationalId == demoBuyerNationalId || b.phone == demoBuyerPhone) {
          continue; // never shadow the live demo buyer
        }
        final id = await _db.into(_db.users).insert(
              UsersCompanion.insert(
                phone: b.phone,
                nationalId: b.nationalId,
                pinHash: hashPin(b.phone, demoBuyerPin),
                name: b.name,
                role: const Value('buyer'),
                jawwalPayNumber: Value(b.phone),
                verificationStatus: const Value('verified'),
              ),
            );
        buyerIds.add(id);
      }

      // 3) Demo-store queue: collected → notified → waiting (chronological),
      //    with the demo store's batch size tightened to 3 so the queue
      //    visibly spans 3 batches (1 collected, 2 notified, 3 waiting).
      final demoStore = await (_db.select(_db.stores)
            ..where((s) => s.ownerPhone.equals(demoOwnerPhone)))
          .getSingle();
      await (_db.update(_db.stores)..where((s) => s.id.equals(demoStore.id)))
          .write(const StoresCompanion(batchSize: Value(3)));

      final today = todayDateString();
      final now = DateTime.now().millisecondsSinceEpoch;
      // Minutes ago per row, oldest first; index within each status group.
      var purchaseUserId = 0;
      Future<void> seedPurchase(
        PurchaseStatus status,
        List<int> minutesAgo,
      ) async {
        for (final m in minutesAgo) {
          final userId = buyerIds[purchaseUserId++ % buyerIds.length];
          await _db.into(_db.purchases).insert(
                PurchasesCompanion.insert(
                  storeId: demoStore.id,
                  userId: userId,
                  purchaseDate: today,
                  batchNumber: status == PurchaseStatus.waiting
                      ? 3
                      : status == PurchaseStatus.notified
                          ? 2
                          : 1,
                  status: status,
                  createdAt: now - m * 60000,
                ),
              );
        }
      }

      await seedPurchase(
        PurchaseStatus.collected,
        [190, 170, 150],
      );
      await seedPurchase(
        PurchaseStatus.notified,
        [90, 70, 50],
      );
      await seedPurchase(
        PurchaseStatus.waiting,
        [30, 20, 10],
      );
    });
  }
}
