import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/app_database.dart';

/// Bridges the local drift `stores` cache and Supabase's `stores` table.
///
/// ponytail: matches local↔remote rows by `name` the first time (store
/// names are unique in this single-pilot deployment) instead of a proper
/// per-row provisioning flow — fine for the ~1-10 stores in spec.md's pilot
/// scope; if the store list grows past hand-managed size, match on a real
/// stable key instead.
class QueueSyncService {
  QueueSyncService({required SupabaseClient client, required AppDatabase db})
      : _client = client,
        _db = db;

  final SupabaseClient _client;
  final AppDatabase _db;

  /// Buyer-side: refreshes local store rows from Supabase's public store
  /// list (RLS allows anyone to read `stores`) so a buyer sees another
  /// owner's live allocation/open-state changes. Best-effort — swallows
  /// errors so a flaky connection never blocks the (drift-backed) UI.
  Future<void> pullStoresDown() async {
    try {
      final rows = await _client.from('stores').select();
      for (final row in rows as List) {
        final remoteId = row['id'] as String;
        final name = row['name'] as String;

        final byRemoteId = await (_db.select(_db.stores)
              ..where((s) => s.remoteId.equals(remoteId)))
            .getSingleOrNull();
        final target = byRemoteId ??
            await (_db.select(_db.stores)..where((s) => s.name.equals(name)))
                .getSingleOrNull();
        if (target == null) {
          // A store this device has never seen locally — the pilot's buyer
          // list is demo-seeded up front, so skip rather than invent a row.
          continue;
        }

        await (_db.update(_db.stores)..where((s) => s.id.equals(target.id)))
            .write(
          StoresCompanion(
            isOpen: Value(row['is_open'] as bool),
            dailyBagLimit: Value(row['daily_bag_limit'] as int),
            bagsRemaining: Value(row['bags_remaining'] as int),
            openTime: Value(row['open_time'] as String?),
            closeTime: Value(row['close_time'] as String?),
            batchSize: Value(row['batch_size'] as int),
            area: Value(row['area'] as String? ?? ''),
            remoteId: Value(remoteId),
          ),
        );
      }
    } catch (_) {
      // offline or transient error — local drift data stands as-is.
    }
  }

  /// Owner-side: links [localStoreId] to a Supabase `stores` row owned by
  /// the currently-authenticated user, creating one if this owner has none
  /// yet. Returns the remote id, or null if there's no active session.
  Future<String?> ensureStoreLinked(int localStoreId) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) return null;

    final store = await (_db.select(_db.stores)
          ..where((s) => s.id.equals(localStoreId)))
        .getSingleOrNull();
    if (store == null) return null;
    if (store.remoteId != null) return store.remoteId;

    final existing = await _client
        .from('stores')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    final String remoteId;
    if (existing != null) {
      remoteId = existing['id'] as String;
    } else {
      final inserted = await _client
          .from('stores')
          .insert({
            'name': store.name,
            'owner_id': ownerId,
            'is_open': store.isOpen,
            'daily_bag_limit': store.dailyBagLimit,
            'bags_remaining': store.bagsRemaining,
            'open_time': store.openTime,
            'close_time': store.closeTime,
            'batch_size': store.batchSize,
            'area': store.area,
          })
          .select()
          .single();
      remoteId = inserted['id'] as String;
    }

    await (_db.update(_db.stores)..where((s) => s.id.equals(localStoreId)))
        .write(StoresCompanion(remoteId: Value(remoteId)));
    return remoteId;
  }
}
