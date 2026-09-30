import 'package:equatable/equatable.dart';
import '../../core/database/tables/converters.dart';

export '../../core/database/tables/converters.dart' show PurchaseStatus;

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
      ];
}
