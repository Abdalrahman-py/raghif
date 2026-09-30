import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/converters.dart';

export 'tables/converters.dart' show PurchaseStatus;

part 'app_database.g.dart';

/// On-device **cache** of the Supabase schema.
///
/// Every table here mirrors its `public.*` counterpart column for column and
/// is keyed by the same UUID. Rows arrive from the server through
/// `QueueSyncService`; nothing in the app writes a business fact here first.
/// Postgres decides, this remembers -- so the database can be deleted at any
/// point and the only cost is a refetch.
///
/// SQLDelight has no Dart/Flutter codegen target, so `drift` fills the same
/// role here: SQL-first table definitions in `tables/*.drift` generate the
/// typesafe Dart row classes and query API below.
@DriftDatabase(
  include: {
    'tables/stores.drift',
    'tables/users.drift',
    'tables/purchases.drift',
    'tables/store_pins.drift',
    'tables/scan_events.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v8 re-keyed every table from INTEGER AUTOINCREMENT to the Supabase
      // UUID and dropped the locally-seeded rows. There is no sensible
      // column-by-column upgrade from the old shape: the old ids named
      // records that only ever existed on this device. Since v8 this
      // database is a cache, so the honest migration is to throw it away and
      // let the sync service refill it from the server.
      if (from < 8) {
        for (final table in allTables) {
          await m.drop(table);
        }
        await m.createAll();
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'raghif',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
