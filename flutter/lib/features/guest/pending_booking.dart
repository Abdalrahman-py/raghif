import 'package:flutter/foundation.dart';

/// The bakery a visitor chose to book before they had an account.
///
/// Set when they tap "احجز رغيفك" on the guest screen and read once, by the
/// buyer app, after sign-up and verification, which then opens that bakery's
/// booking summary instead of dropping them on the home tab.
abstract final class PendingBooking {
  static final ValueNotifier<String?> _storeId = ValueNotifier<String?>(null);

  static String? get storeId => _storeId.value;

  static void set(String? storeId) => _storeId.value = storeId;

  /// Returns the pending bakery and forgets it.
  static String? take() {
    final id = _storeId.value;
    _storeId.value = null;
    return id;
  }
}
