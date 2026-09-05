import 'package:equatable/equatable.dart';

class StoreModel extends Equatable {
  const StoreModel({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.dailyBagLimit,
    required this.bagsRemaining,
    required this.ownerPhone,
    this.batchSize = 20,
    this.batchRound = 1,
    this.allocationDate = '',
  });

  final int id;
  final String name;
  final bool isOpen;
  final int dailyBagLimit;
  final int bagsRemaining;
  final String ownerPhone;
  final int batchSize;
  final int batchRound;
  final String allocationDate;

  bool get isSoldOut => bagsRemaining <= 0;
  bool get canPurchase => isOpen && !isSoldOut;
  bool get isAvailable => canPurchase;

  StoreModel copyWith({
    int? id,
    String? name,
    bool? isOpen,
    int? dailyBagLimit,
    int? bagsRemaining,
    String? ownerPhone,
    int? batchSize,
    int? batchRound,
    String? allocationDate,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isOpen: isOpen ?? this.isOpen,
      dailyBagLimit: dailyBagLimit ?? this.dailyBagLimit,
      bagsRemaining: bagsRemaining ?? this.bagsRemaining,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      batchSize: batchSize ?? this.batchSize,
      batchRound: batchRound ?? this.batchRound,
      allocationDate: allocationDate ?? this.allocationDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isOpen,
        dailyBagLimit,
        bagsRemaining,
        ownerPhone,
        batchSize,
        batchRound,
        allocationDate,
      ];
}
