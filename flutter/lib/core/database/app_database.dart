import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/converters.dart';

export 'tables/converters.dart' show PurchaseStatus;

part 'app_database.g.dart';

/// On-device schema for the prototype (spec.md "Database Schema (local SQLDelight)").
///
/// SQLDelight has no Dart/Flutter codegen target, so `drift` fills the same
/// role here: SQL-first table definitions in `tables/*.drift` generate the
/// typesafe Dart row classes and query API below.
@DriftDatabase(
  include: {
    'tables/stores.drift',
    'tables/users.drift',
    'tables/purchases.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'raghif');
  }
}
