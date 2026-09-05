import '../../domain/models/purchase_model.dart';
import 'qr_payload.dart';

/// How a scanned receipt resolved against the owner's local data.
enum QrRedemptionOutcome {
  /// Purchase found, notified, arrival toggled by the caller — bag handed over.
  checkedIn,

  /// Already marked collected earlier — duplicate scan.
  alreadyCollected,

  /// Purchase exists but its batch has not been notified yet.
  batchNotCalledYet,

  /// Decoded fine but no matching purchase in this device's data
  /// (expected in the prototype — no cross-device sync; see issue #28).
  notFoundHere,

  /// Matches a purchase, but one belonging to a different store.
  wrongStore,
}

/// Outcome of matching a decoded receipt against local data, keeping the
/// decoded payload so the UI can always show what was encoded.
class QrRedemptionResult {
  const QrRedemptionResult({
    required this.outcome,
    required this.payload,
    this.purchase,
  });

  final QrRedemptionOutcome outcome;
  final QrPayload payload;
  final PurchaseModel? purchase;

  int? get batchNumber => purchase?.batchNumber;
  String? get actualStoreName => purchase?.storeName;
}

/// Pure decode-and-match logic, deliberately separated from the camera widget
/// so redemption rules are unit-testable without a camera (issue #28 testing
/// decision). The caller applies [QrRedemptionOutcome.checkedIn] by toggling
/// arrival on the returned [QrRedemptionResult.purchase].
QrRedemptionResult evaluateQrRedemption({
  required QrPayload payload,
  required PurchaseModel? purchase,
  required int ownerStoreId,
}) {
  if (purchase == null) {
    return QrRedemptionResult(
      outcome: QrRedemptionOutcome.notFoundHere,
      payload: payload,
    );
  }

  if (purchase.storeId != ownerStoreId) {
    return QrRedemptionResult(
      outcome: QrRedemptionOutcome.wrongStore,
      payload: payload,
      purchase: purchase,
    );
  }

  final outcome = switch (purchase.status) {
    PurchaseStatus.notified => QrRedemptionOutcome.checkedIn,
    PurchaseStatus.collected => QrRedemptionOutcome.alreadyCollected,
    PurchaseStatus.waiting => QrRedemptionOutcome.batchNotCalledYet,
  };
  return QrRedemptionResult(
    outcome: outcome,
    payload: payload,
    purchase: purchase,
  );
}
