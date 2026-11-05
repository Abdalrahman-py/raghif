import 'package:equatable/equatable.dart';

/// One day of a store's sales, for the owner's history browser.
///
/// [sold] counts every purchase that day; [collected] how many were handed
/// over; [notCollected] the rest (waiting + notified, i.e. paid but not picked
/// up). End-of-day leftovers are exactly `notCollected`.
class StoreDaySummary extends Equatable {
  const StoreDaySummary({
    required this.date,
    required this.sold,
    required this.collected,
    required this.notCollected,
    this.cashTotal = 0,
  });

  final String date;
  final int sold;
  final int collected;
  final int notCollected;

  /// Cash taken that day, in shekels (from the `payments` the server wrote when
  /// bags were collected).
  final double cashTotal;

  bool get everythingCollected => notCollected == 0;

  @override
  List<Object?> get props => [date, sold, collected, notCollected, cashTotal];
}
