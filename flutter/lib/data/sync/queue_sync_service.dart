import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/app_database.dart';

/// Fills the on-device cache from Supabase.
///
/// Every table is pulled with a plain `select`, so RLS decides the scope
/// rather than any client-side filter: a buyer sees their own purchases, an
/// owner additionally sees their store's purchases and the profiles of the
/// buyers in them. Getting that wrong would be a privacy bug, so the rule
/// lives in one place — the policies — and this just mirrors whatever comes
/// back.
///
/// Pull order matters: `purchases` and `scan_events` reference `stores` and
/// `users`, so those land first.
///
/// Errors are swallowed. Reads are allowed to be stale — a failed refresh
/// leaves the last good cache in place and the UI keeps rendering. Writes
/// do not get this treatment; they fail loudly (see
/// [BackendUnavailableException]).
class QueueSyncService {
  QueueSyncService({required SupabaseClient client, required AppDatabase db})
      : _client = client,
        _db = db;

  final SupabaseClient _client;
  final AppDatabase _db;

  bool get _hasSession => _client.auth.currentSession != null;

  /// One full refresh. Individual steps are independent: a failure in one
  /// doesn't abandon the rest, so a buyer with no owned store still gets
  /// their stores and purchases even though the scan pull returns nothing.
  Future<void> refreshAll() async {
    await pullStores();
    if (!_hasSession) return;
    await pullProfiles();
    await pullPurchases();
    await pullPins();
    await pullScanEvents();
  }

  /// Stores are world-readable, so this works signed out too — the buyer can
  /// browse bakeries before logging in.
  Future<void> pullStores() async {
    await _guard(() async {
      final rows = await _client.from('stores').select();
      await _db.batch((b) {
        for (final row in (rows as List).cast<Map<String, dynamic>>()) {
          b.insert(
            _db.stores,
            StoresCompanion.insert(
              id: row['id'] as String,
              name: (row['name'] as String?) ?? '',
              ownerId: Value(row['owner_id'] as String?),
              isOpen: Value((row['is_open'] as bool?) ?? false),
              dailyBagLimit: Value((row['daily_bag_limit'] as int?) ?? 0),
              bagsRemaining: Value((row['bags_remaining'] as int?) ?? 0),
              openTime: Value(_hhmm(row['open_time'] as String?)),
              closeTime: Value(_hhmm(row['close_time'] as String?)),
              batchSize: Value((row['batch_size'] as int?) ?? 20),
              area: Value((row['area'] as String?) ?? ''),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<void> pullProfiles() async {
    await _guard(() async {
      final rows = await _client.from('profiles').select();
      await _db.batch((b) {
        for (final row in (rows as List).cast<Map<String, dynamic>>()) {
          b.insert(
            _db.users,
            UsersCompanion.insert(
              id: row['id'] as String,
              phone: Value((row['phone'] as String?) ?? ''),
              nationalId: Value((row['national_id'] as String?) ?? ''),
              name: Value((row['name'] as String?) ?? ''),
              role: Value((row['role'] as String?) ?? 'buyer'),
              jawwalPayNumber: Value(row['jawwal_pay_number'] as String?),
              verificationStatus:
                  Value((row['verification_status'] as String?) ?? 'pending'),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<void> pullPurchases() async {
    await _guard(() async {
      final rows = await _client.from('purchases').select();
      final list = (rows as List).cast<Map<String, dynamic>>();
      final knownUsers = (await _db.select(_db.users).get())
          .map((u) => u.id)
          .toSet();
      final knownStores = (await _db.select(_db.stores).get())
          .map((s) => s.id)
          .toSet();

      await _db.batch((b) {
        for (final row in list) {
          // A purchase whose buyer or store this device may not read would
          // violate the cache's own foreign keys; skip rather than invent a
          // placeholder row that the UI would render as a blank customer.
          if (!knownUsers.contains(row['user_id']) ||
              !knownStores.contains(row['store_id'])) {
            continue;
          }
          b.insert(
            _db.purchases,
            PurchasesCompanion.insert(
              id: row['id'] as String,
              storeId: row['store_id'] as String,
              userId: row['user_id'] as String,
              purchaseDate: row['purchase_date'] as String,
              batchNumber: Value((row['batch_number'] as int?) ?? 1),
              status: _status(row['status'] as String?),
              createdAt: _millis(row['created_at'] as String?),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<void> pullPins() async {
    await _guard(() async {
      final rows = await _client.from('store_pins').select();
      await _db.delete(_db.storePins).go();
      await _db.batch((b) {
        for (final row in (rows as List).cast<Map<String, dynamic>>()) {
          b.insert(
            _db.storePins,
            StorePinsCompanion.insert(
              userId: row['user_id'] as String,
              storeId: row['store_id'] as String,
              createdAt: _millis(row['created_at'] as String?),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<void> pullScanEvents() async {
    await _guard(() async {
      final rows = await _client.from('scan_events').select();
      await _db.batch((b) {
        for (final row in (rows as List).cast<Map<String, dynamic>>()) {
          b.insert(
            _db.scanEvents,
            ScanEventsCompanion.insert(
              id: row['id'] as String,
              storeId: row['store_id'] as String,
              purchaseId: Value(row['purchase_id'] as String?),
              outcome: (row['outcome'] as String?) ?? '',
              scannedName: Value(row['scanned_name'] as String?),
              scannedNationalId: Value(row['scanned_national_id'] as String?),
              scannedAt: _millis(row['scanned_at'] as String?),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } catch (_) {
      // Stale cache beats a blank screen; writes are what must not be silent.
    }
  }

  /// Postgres `time` comes back as "HH:mm:ss"; the UI wants "HH:mm".
  static String? _hhmm(String? value) {
    if (value == null || value.length < 5) return value;
    return value.substring(0, 5);
  }

  static int _millis(String? iso) =>
      DateTime.tryParse(iso ?? '')?.millisecondsSinceEpoch ??
      DateTime.now().millisecondsSinceEpoch;

  static PurchaseStatus _status(String? value) => switch (value) {
        'notified' => PurchaseStatus.notified,
        'collected' => PurchaseStatus.collected,
        _ => PurchaseStatus.waiting,
      };
}
