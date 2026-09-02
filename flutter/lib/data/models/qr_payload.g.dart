// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrPayload _$QrPayloadFromJson(Map<String, dynamic> json) => QrPayload(
  purchaseId: json['purchase_id'] as String,
  userName: json['user_name'] as String,
  storeName: json['store_name'] as String,
  purchaseDate: json['purchase_date'] as String,
);

Map<String, dynamic> _$QrPayloadToJson(QrPayload instance) => <String, dynamic>{
  'purchase_id': instance.purchaseId,
  'user_name': instance.userName,
  'store_name': instance.storeName,
  'purchase_date': instance.purchaseDate,
};
