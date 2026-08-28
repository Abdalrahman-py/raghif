import 'package:drift/drift.dart';

/// Mirrors the `status` enum on the `purchases` table in spec.md:
/// `waiting` -> `notified` -> `collected`.
enum PurchaseStatus { waiting, notified, collected }

class PurchaseStatusConverter extends TypeConverter<PurchaseStatus, String>
    with JsonTypeConverter2<PurchaseStatus, String, String> {
  const PurchaseStatusConverter();

  @override
  PurchaseStatus fromSql(String fromDb) => PurchaseStatus.values.byName(fromDb);

  @override
  String toSql(PurchaseStatus value) => value.name;

  @override
  PurchaseStatus fromJson(String json) => fromSql(json);

  @override
  String toJson(PurchaseStatus value) => toSql(value);
}
