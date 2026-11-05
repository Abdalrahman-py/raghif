import 'package:equatable/equatable.dart';

/// A purchase's position in the collection workflow (spec.md `purchases.status`).
enum PurchaseStatus { waiting, notified, collected }

class PurchaseModel extends Equatable {
  const PurchaseModel({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.purchaseDate,
    required this.batchNumber,
    required this.status,
    required this.createdAtMillis,
    this.userName,
    this.userPhone,
    this.userNationalId,
    this.storeName,
    this.postponementCount = 0,
    this.paymentMethod,
  });

  final String id;
  final String storeId;
  final String userId;
  final String purchaseDate;
  final int batchNumber;
  final PurchaseStatus status;
  final int createdAtMillis;
  final String? userName;
  final String? userPhone;
  final String? userNationalId;
  final String? storeName;
  final int postponementCount;

  /// How this bag was paid: `jawwal_pay`, `cash` (taken at collection), or
  /// null while nothing is recorded yet (cash is due at pickup).
  final String? paymentMethod;

  /// Paid through the wallet before pickup: the bakery takes no cash.
  bool get isPrepaid => paymentMethod == 'jawwal_pay';

  PurchaseModel copyWith({
    String? id,
    String? storeId,
    String? userId,
    String? purchaseDate,
    int? batchNumber,
    PurchaseStatus? status,
    int? createdAtMillis,
    String? userName,
    String? userPhone,
    String? userNationalId,
    String? storeName,
    int? postponementCount,
    String? paymentMethod,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      userId: userId ?? this.userId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userNationalId: userNationalId ?? this.userNationalId,
      storeName: storeName ?? this.storeName,
      postponementCount: postponementCount ?? this.postponementCount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    id,
    storeId,
    userId,
    purchaseDate,
    batchNumber,
    status,
    createdAtMillis,
    userName,
    userPhone,
    userNationalId,
    storeName,
    postponementCount,
    paymentMethod,
  ];
}
