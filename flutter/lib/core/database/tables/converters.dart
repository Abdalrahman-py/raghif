import 'package:drift/drift.dart';

/// A purchase's position in the collection workflow (spec.md `purchases.status`).
enum PurchaseStatus { waiting, notified, collected }

class PurchaseStatusConverter extends TypeConverter<PurchaseStatus, String> {
  const PurchaseStatusConverter();

  @override
  PurchaseStatus fromSql(String fromDb) => PurchaseStatus.values.byName(fromDb);

  @override
  String toSql(PurchaseStatus value) => value.name;
}
