import 'package:drift/drift.dart';

import 'purchase_status.dart';

part 'database.g.dart';

/// On-device schema for the bread-queue prototype (spec.md § Database Schema).
///
/// This only defines the schema and generated Dart types; picking the
/// concrete [QueryExecutor] (native sqlite3, in-memory, ...) is left to the
/// call site so production wiring can land separately.
@DriftDatabase(include: {'database.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
