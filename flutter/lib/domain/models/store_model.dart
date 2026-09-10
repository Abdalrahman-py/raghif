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
    this.openTime,
    this.closeTime,
    this.area = '',
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

  /// Today's purchase window, "HH:mm" 24h, set by the owner. Null when not
  /// set yet — informational only, doesn't itself gate [isOpen].
  final String? openTime;
  final String? closeTime;

  /// Neighborhood the bakery sits in (e.g. الرمال). Empty when unknown —
  /// shown as a filter chip on the buyer store list, not an address.
  final String area;

  bool get isSoldOut => bagsRemaining <= 0;
  bool get canPurchase => isOpen && !isSoldOut;
  bool get isAvailable => canPurchase;
  bool get hasPurchaseWindow => openTime != null && closeTime != null;

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
    String? openTime,
    String? closeTime,
    String? area,
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
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      area: area ?? this.area,
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
    openTime,
    closeTime,
    area,
  ];
}
