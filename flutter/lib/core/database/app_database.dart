import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Local schema per spec.md's "Database Schema (local SQLDelight)" section.
/// Prototype is LOCAL-ONLY: on-device sqlite, no Supabase, no hosting.
///
/// Only the `users` table is defined so far — `stores` and `purchases` land
/// with the screens that need them (see TASKS.md backlog).
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phone => text().unique()();
  TextColumn get nationalId => text().unique()();
  TextColumn get pinHash => text()();
  TextColumn get name => text()();

  /// 'buyer' or 'owner'. Not part of spec.md's schema (owner identification
  /// there is "hardcoded by phone number" against a stores table), but that
  /// table doesn't exist yet — kept here, matching the Kotlin prototype's
  /// UserEntity.role, until store-based owner lookup lands.
  TextColumn get role => text().withDefault(const Constant('buyer'))();
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'bread_proto');
  }
}
