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
/// Guard: seeds at most once per calendar day. Re-running on the same day is
/// a no-op; opening the app on a later day lays down a fresh day's story and
/// leaves earlier days in place for the owner history screen. That matters for
/// a demo: a build installed today would otherwise show an empty queue
/// tomorrow, because every queue read filters on today's date.
class DemoContentSeeder {
  DemoContentSeeder(this._db);

  final AppDatabase _db;

  /// Bags the demo store starts each day with, matching its base seed row.
  static const _demoStoreDailyBags = 45;

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
      area: 'تل الهوا',
    ),
    (
      name: 'مخبز الزيتون',
      ownerPhone: '0599000006',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 150,
      openTime: '07:30',
      closeTime: '09:30',
      area: 'الزيتون',
    ),
    (
      name: 'مخبز النور',
      ownerPhone: '0599000007',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 0,
      openTime: '06:30',
      closeTime: '08:30',
      area: 'الشيخ رضوان',
    ),
    (
      name: 'مخبز السلام',
      ownerPhone: '0599000008',
      isOpen: true,
      dailyBagLimit: 300,
      bagsRemaining: 200,
      openTime: '08:00',
      closeTime: '10:00',
      area: 'جباليا',
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
    // No-op if today's story is already seeded. Earlier days stay untouched.
    final today = todayDateString();
    final alreadySeededToday = await (_db.select(_db.purchases)
          ..where((p) => p.purchaseDate.equals(today))
          ..limit(1))
        .getSingleOrNull();
    if (alreadySeededToday != null) return;

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
                area: Value(s.area),
              ),
            );
      }

      // 2) Dummy buyers.
      final buyerIds = <int>[];
      for (final b in _dummyBuyers) {
        if (b.nationalId == demoBuyerNationalId || b.phone == demoBuyerPhone) {
          continue; // never shadow the live demo buyer
        }
        final existing = await (_db.select(_db.users)
              ..where((u) => u.nationalId.equals(b.nationalId)))
            .getSingleOrNull();
        if (existing != null) {
          buyerIds.add(existing.id);
          continue; // seeded on an earlier day
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
      // Batch size 3 so the seeded queue visibly spans 3 batches. Bags are
      // restocked to the day's allocation minus the 9 seeded reservations —
      // WFP delivers daily, so a new day starts from a full allocation.
      await (_db.update(_db.stores)..where((s) => s.id.equals(demoStore.id)))
          .write(
        const StoresCompanion(
          batchSize: Value(3),
          bagsRemaining: Value(_demoStoreDailyBags - 9),
        ),
      );

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
