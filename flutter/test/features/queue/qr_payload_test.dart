import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/features/queue/qr_payload.dart';

void main() {
  group('QrPayload', () {
    const payload = QrPayload(
      purchaseId: 'purchase_123',
      userName: 'أحمد محمود',
      storeName: 'مخبز الأمل',
      purchaseDate: '2026-09-03',
    );

    test('toJson produces correct map structure and keys', () {
      final json = payload.toJson();
      expect(json, {
        'purchase_id': 'purchase_123',
        'user_name': 'أحمد محمود',
        'store_name': 'مخبز الأمل',
        'purchase_date': '2026-09-03',
      });
    });

    test('encode produces valid JSON matching toJson', () {
      final encoded = payload.encode();
      final decodedMap = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decodedMap['purchase_id'], 'purchase_123');
      expect(decodedMap['user_name'], 'أحمد محمود');
      expect(decodedMap['store_name'], 'مخبز الأمل');
      expect(decodedMap['purchase_date'], '2026-09-03');
    });

    test('decode restores exact QrPayload from valid JSON', () {
      final jsonStr = jsonEncode({
        'purchase_id': 'p99',
        'user_name': 'سارة',
        'store_name': 'مخبز السلام',
        'purchase_date': '2026-09-04',
      });
      final decoded = QrPayload.decode(jsonStr);
      expect(decoded.purchaseId, 'p99');
      expect(decoded.userName, 'سارة');
      expect(decoded.storeName, 'مخبز السلام');
      expect(decoded.purchaseDate, '2026-09-04');
    });

    test('round-trip encode and decode preserves equality', () {
      final encoded = payload.encode();
      final roundTripped = QrPayload.decode(encoded);
      expect(roundTripped, equals(payload));
      expect(roundTripped.hashCode, equals(payload.hashCode));
    });

    test('decode throws FormatException on malformed input', () {
      expect(() => QrPayload.decode('not valid json'), throwsFormatException);
      expect(() => QrPayload.decode('[1, 2, 3]'), throwsFormatException);
    });

    test('tryDecode returns valid QrPayload on well-formed JSON', () {
      final decoded = QrPayload.tryDecode(payload.encode());
      expect(decoded, equals(payload));
    });

    test('tryDecode returns null on malformed or missing key JSON', () {
      expect(QrPayload.tryDecode('invalid json string'), isNull);
      expect(QrPayload.tryDecode('{"some_key": "val"}'), isNull);
      expect(
        QrPayload.tryDecode('{"purchase_id": "1", "user_name": "a"}'),
        isNull,
      );
    });
  });
}
