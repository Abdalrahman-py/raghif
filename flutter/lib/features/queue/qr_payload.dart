import 'dart:convert';

/// Encapsulates the receipt data encoded into the QR code displayed on
/// [ConfirmationScreen] and scanned on [OwnerQueueScreen].
class QrPayload {
  const QrPayload({
    required this.purchaseId,
    required this.userName,
    required this.storeName,
    required this.purchaseDate,
  });

  final String purchaseId;
  final String userName;
  final String storeName;
  final String purchaseDate;

  Map<String, dynamic> toJson() => {
    'purchase_id': purchaseId,
    'user_name': userName,
    'store_name': storeName,
    'purchase_date': purchaseDate,
  };

  String encode() => jsonEncode(toJson());

  factory QrPayload.fromJson(Map<String, dynamic> json) {
    return QrPayload(
      purchaseId: json['purchase_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      purchaseDate: json['purchase_date'] as String? ?? '',
    );
  }

  factory QrPayload.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid QR payload format');
    }
    return QrPayload.fromJson(decoded);
  }

  static QrPayload? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (!decoded.containsKey('purchase_id') ||
          !decoded.containsKey('user_name') ||
          !decoded.containsKey('store_name') ||
          !decoded.containsKey('purchase_date')) {
        return null;
      }
      return QrPayload.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrPayload &&
          runtimeType == other.runtimeType &&
          purchaseId == other.purchaseId &&
          userName == other.userName &&
          storeName == other.storeName &&
          purchaseDate == other.purchaseDate;

  @override
  int get hashCode =>
      Object.hash(purchaseId, userName, storeName, purchaseDate);

  @override
  String toString() =>
      'QrPayload(purchaseId: $purchaseId, userName: $userName, storeName: $storeName, purchaseDate: $purchaseDate)';
}
