import 'package:equatable/equatable.dart';

import 'store_model.dart';
import '../../core/database/tables/converters.dart';

/// One row of the buyer's store list: the store itself plus that buyer's own
/// context for it. Everything here is per (user, store) — it's what lets the
/// list float the stores the buyer actually uses to the top and show extra
/// status detail on those cards.
class StoreListEntry extends Equatable {
  const StoreListEntry({
    required this.store,
    this.pinned = false,
    this.todayStatus,
    this.lastPurchaseDate,
  });

  final StoreModel store;

  /// Buyer pinned this store → it always sorts to the top of the list.
  final bool pinned;

  /// Today's order at this store for this buyer, if any. A purchase row only
  /// exists after payment succeeded, so its presence also means "paid".
  final PurchaseStatus? todayStatus;

  /// Most recent purchase date at this store ("YYYY-MM-DD"), any day. Null
  /// when the buyer has never bought here.
  final String? lastPurchaseDate;

  bool get hasOrderToday => todayStatus != null;

  /// Paid, and the bag hasn't been handed over yet.
  bool get awaitingPickup =>
      todayStatus == PurchaseStatus.waiting ||
      todayStatus == PurchaseStatus.notified;

  bool get pickedUp => todayStatus == PurchaseStatus.collected;

  /// Buyer has history here (today or any earlier day).
  bool get isFamiliar => hasOrderToday || lastPurchaseDate != null;

  StoreListEntry copyWith({bool? pinned}) => StoreListEntry(
    store: store,
    pinned: pinned ?? this.pinned,
    todayStatus: todayStatus,
    lastPurchaseDate: lastPurchaseDate,
  );

  @override
  List<Object?> get props => [store, pinned, todayStatus, lastPurchaseDate];
}
