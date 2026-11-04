import 'package:equatable/equatable.dart';

class StoreModel extends Equatable {
  const StoreModel({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.dailyBagLimit,
    required this.bagsRemaining,
    this.ownerId,
    this.batchSize = 20,
    this.openTime,
    this.closeTime,
    this.area = '',
    this.governorate,
    this.status = StoreStatus.active,
  });

  /// Supabase `stores.id`. Same value on device, on the server and in a
  /// QR payload.
  final String id;
  final String name;
  final bool isOpen;
  final int dailyBagLimit;
  final int bagsRemaining;

  /// Supabase profiles UUID of the owner; null for the browse-only demo
  /// bakeries that nobody manages.
  final String? ownerId;
  final int batchSize;

  /// Today's purchase window, "HH:mm" 24h, set by the owner. Null when not
  /// set yet — informational only, doesn't itself gate [isOpen].
  final String? openTime;
  final String? closeTime;

  /// Neighborhood the bakery sits in (e.g. الرمال). Empty when unknown —
  /// shown as a filter chip on the buyer store list, not an address.
  final String area;
  final String? governorate;

  /// Set by the administrator, not the owner: [StoreStatus.active],
  /// [StoreStatus.paused] (visible, but nobody can book) or
  /// [StoreStatus.archived] (hidden from buyers; only reachable here through a
  /// booking the buyer already has). Independent of [isOpen], which is the
  /// owner's own daily switch.
  final String status;

  bool get isPaused => status == StoreStatus.paused;
  bool get isArchived => status == StoreStatus.archived;
  bool get isSoldOut => bagsRemaining <= 0;
  bool get canPurchase => status == StoreStatus.active && isOpen && !isSoldOut;
  bool get isAvailable => canPurchase;
  bool get hasPurchaseWindow => openTime != null && closeTime != null;

  StoreModel copyWith({
    String? id,
    String? name,
    bool? isOpen,
    int? dailyBagLimit,
    int? bagsRemaining,
    String? ownerId,
    int? batchSize,
    String? openTime,
    String? closeTime,
    String? area,
    String? governorate,
    String? status,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isOpen: isOpen ?? this.isOpen,
      dailyBagLimit: dailyBagLimit ?? this.dailyBagLimit,
      bagsRemaining: bagsRemaining ?? this.bagsRemaining,
      ownerId: ownerId ?? this.ownerId,
      batchSize: batchSize ?? this.batchSize,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      area: area ?? this.area,
      governorate: governorate ?? this.governorate,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    isOpen,
    dailyBagLimit,
    bagsRemaining,
    ownerId,
    batchSize,
    openTime,
    closeTime,
    area,
    governorate,
    status,
  ];
}

/// The values of `stores.status`.
abstract final class StoreStatus {
  static const active = 'active';
  static const paused = 'paused';
  static const archived = 'archived';
}
