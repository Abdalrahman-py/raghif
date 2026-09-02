import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'qr_payload.g.dart';

/// QR Receipt payload containing purchase and user details.
@JsonSerializable()
class QrPayload extends Equatable {
  const QrPayload({
    required this.purchaseId,
    required this.userName,
    required this.storeName,
    required this.purchaseDate,
  });

  factory QrPayload.fromJson(Map<String, dynamic> json) =>
      _$QrPayloadFromJson(json);

  factory QrPayload.fromEncodedString(String encoded) {
    final map = jsonDecode(encoded) as Map<String, dynamic>;
    return QrPayload.fromJson(map);
  }

  @JsonKey(name: 'purchase_id')
  final String purchaseId;

  @JsonKey(name: 'user_name')
  final String userName;

  @JsonKey(name: 'store_name')
  final String storeName;

  @JsonKey(name: 'purchase_date')
  final String purchaseDate;

  Map<String, dynamic> toJson() => _$QrPayloadToJson(this);

  String toEncodedString() => jsonEncode(toJson());

  @override
  List<Object?> get props => [purchaseId, userName, storeName, purchaseDate];
}
