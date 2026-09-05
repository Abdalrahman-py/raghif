import 'package:equatable/equatable.dart';

class CustomerSummaryModel extends Equatable {
  const CustomerSummaryModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.totalPurchases,
    required this.lastPurchaseDate,
  });

  final int userId;
  final String name;
  final String phone;
  final int totalPurchases;
  final String lastPurchaseDate;

  @override
  List<Object?> get props => [
        userId,
        name,
        phone,
        totalPurchases,
        lastPurchaseDate,
      ];
}
