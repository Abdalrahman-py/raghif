import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/features/queue/queue_logic.dart';

/// "Today" is the Asia/Hebron date whatever the device's zone. Instants below
/// are UTC; transitions come from `zdump -v Asia/Hebron`.
void main() {
  String at(int y, int mo, int d, int h, [int mi = 0]) =>
      todayDateString(DateTime.utc(y, mo, d, h, mi));

  test('winter: UTC+2, the date flips at 22:00 UTC', () {
    expect(at(2026, 1, 15, 21, 59), '2026-01-15');
    expect(at(2026, 1, 15, 22, 0), '2026-01-16');
  });

  test('summer: UTC+3, the date flips at 21:00 UTC', () {
    expect(at(2026, 7, 1, 20, 59), '2026-07-01');
    expect(at(2026, 7, 1, 21, 0), '2026-07-02');
  });

  test('summer time starts Sat 2026-03-28 00:00 UTC', () {
    expect(hebronUtcOffsetHours(DateTime.utc(2026, 3, 27, 23, 59)), 2);
    expect(hebronUtcOffsetHours(DateTime.utc(2026, 3, 28)), 3);
    // Midnight before the switch is still on +2.
    expect(at(2026, 3, 27, 21, 59), '2026-03-27');
    expect(at(2026, 3, 27, 22, 0), '2026-03-28');
  });

  test('summer time ends Fri 2026-10-23 23:00 UTC', () {
    expect(hebronUtcOffsetHours(DateTime.utc(2026, 10, 23, 22, 59)), 3);
    expect(hebronUtcOffsetHours(DateTime.utc(2026, 10, 23, 23)), 2);
    // Local midnight of Oct 24 is 21:00 UTC on Oct 23, still summer.
    expect(at(2026, 10, 23, 20, 59), '2026-10-23');
    expect(at(2026, 10, 23, 21, 0), '2026-10-24');
  });

  test('ignores the device zone: a local DateTime maps by its instant', () {
    final instant = DateTime.utc(2026, 11, 22, 22, 30);
    expect(todayDateString(instant.toLocal()), '2026-11-23');
    expect(todayDateString(instant), '2026-11-23');
  });

  test('outside the table, April–September counts as summer', () {
    expect(hebronUtcOffsetHours(DateTime.utc(2040, 7, 1)), 3);
    expect(hebronUtcOffsetHours(DateTime.utc(2040, 12, 1)), 2);
  });
}
