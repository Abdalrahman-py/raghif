import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/features/queue/qr_redemption.dart';
import 'package:raghif/features/queue/scan_feedback.dart';

void main() {
  test('only a checked-in scan is a success tone', () {
    expect(
      scanFeedbackFor(QrRedemptionOutcome.checkedIn),
      ScanFeedback.success,
    );
  });

  test('every other outcome gets the failure buzz', () {
    final others = QrRedemptionOutcome.values.where(
      (o) => o != QrRedemptionOutcome.checkedIn,
    );

    expect(others, isNotEmpty);
    for (final outcome in others) {
      expect(
        scanFeedbackFor(outcome),
        ScanFeedback.failure,
        reason: '${outcome.name} must not sound like a successful handover',
      );
    }
  });
}
