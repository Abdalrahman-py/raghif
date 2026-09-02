/// Mock in-memory models mirroring spec.md's SQLDelight schema (stores,
/// purchases). Replaced by real SQLDelight-backed queries in a follow-up —
/// see spec.md's Database Schema section for the on-device source of truth.
enum PurchaseStatus { waiting, notified, collected }

class Store {
  Store({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.dailyBagLimit,
    required this.bagsRemaining,
    this.batchSize = 20,
    this.batchRound = 1,
    this.allocationDate = '',
  });

  final String id;
  String name;
  bool isOpen;
  int dailyBagLimit;
  int bagsRemaining;
  int batchSize;
  // Bumped every time the owner tops up allocation — a purchase made under an
  // older round no longer blocks a same-day repurchase once the round moves on.
  int batchRound;
  // yyyy-MM-dd this store's current allocation was set.
  String allocationDate;

  bool get isAvailable => isOpen && bagsRemaining > 0;
}

class Purchase {
  const Purchase({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.purchaseDate,
    required this.batchNumber,
    required this.status,
    required this.createdAtMillis,
    this.batchRoundAtPurchase = 1,
  });

  final String id;
  final String storeId;
  final String userId;
  final String purchaseDate;
  final int batchNumber;
  final PurchaseStatus status;
  final int createdAtMillis;
  final int batchRoundAtPurchase;

  Purchase copyWith({PurchaseStatus? status}) => Purchase(
    id: id,
    storeId: storeId,
    userId: userId,
    purchaseDate: purchaseDate,
    batchNumber: batchNumber,
    status: status ?? this.status,
    createdAtMillis: createdAtMillis,
    batchRoundAtPurchase: batchRoundAtPurchase,
  );
}
