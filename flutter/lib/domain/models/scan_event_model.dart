import 'package:equatable/equatable.dart';

/// One QR scan attempt at pickup — the audit trail behind the owner's "scan
/// writes every detail to DB".
///
/// [outcome] holds the `QrRedemptionOutcome` name (checkedIn,
/// alreadyCollected, batchNotCalledYet, notFoundHere, wrongStore) or
/// `invalidCode` when the scanned data wasn't a receipt payload at all. Both
/// of those cases leave [purchaseId] null.
class ScanEventModel extends Equatable {
  const ScanEventModel({
    required this.id,
    required this.storeId,
    required this.outcome,
    required this.scannedAtMillis,
    this.purchaseId,
    this.scannedName,
    this.scannedNationalId,
  });

  final int id;
  final int storeId;
  final int? purchaseId;
  final String outcome;
  final String? scannedName;
  final String? scannedNationalId;
  final int scannedAtMillis;

  DateTime get scannedAt => DateTime.fromMillisecondsSinceEpoch(scannedAtMillis);

  /// True when the scan actually handed a bag over.
  bool get isCheckedIn => outcome == 'checkedIn';

  @override
  List<Object?> get props => [
    id,
    storeId,
    purchaseId,
    outcome,
    scannedName,
    scannedNationalId,
    scannedAtMillis,
  ];
}
