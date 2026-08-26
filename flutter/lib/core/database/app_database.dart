import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Generated Dart types for the local schema defined in `tables.drift`
/// (`stores`, `users`, `purchases` — see spec.md's schema section).
///
/// This class only declares the schema; wiring a real sqlite driver
/// (native database file, connection lifecycle) is a follow-up task.
@DriftDatabase(include: {'tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
