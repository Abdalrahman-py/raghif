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

    const fullPayload = QrPayload(
      purchaseId: '7',
      userName: 'سارة',
      storeName: 'مخبز السلام',
      purchaseDate: '2026-09-04',
      nationalId: '900111222',
      storeId: 2,
    );

    test('toJson produces correct map structure and keys', () {
      expect(payload.toJson(), {
        'v': qrPayloadVersion,
        'purchase_id': 'purchase_123',
        'user_name': 'أحمد محمود',
        'store_name': 'مخبز الأمل',
        'purchase_date': '2026-09-03',
      });
    });

    test('v1 toJson includes version, omits absent optional fields', () {
      expect(fullPayload.toJson(), {
        'v': qrPayloadVersion,
        'purchase_id': '7',
        'user_name': 'سارة',
        'store_name': 'مخبز السلام',
        'purchase_date': '2026-09-04',
        'national_id': '900111222',
        'store_id': 2,
      });
    });

    test('encode produces valid JSON matching toJson', () {
      final encoded = payload.encode();
      final decodedMap = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decodedMap['purchase_id'], 'purchase_123');
      expect(decodedMap['user_name'], 'أحمد محمود');
      expect(decodedMap['store_name'], 'مخبز الأمل');
      expect(decodedMap['purchase_date'], '2026-09-03');
      expect(decodedMap['v'], qrPayloadVersion);
    });

    test('decode restores exact QrPayload from valid JSON', () {
      final jsonStr = jsonEncode({
        'purchase_id': 'p99',
        'user_name': 'سارة',
        'store_name': 'مخبز السلام',
        'purchase_date': '2026-09-04',
        'national_id': '900111222',
        'store_id': 3,
      });
      final decoded = QrPayload.decode(jsonStr);
      expect(decoded.purchaseId, 'p99');
      expect(decoded.userName, 'سارة');
      expect(decoded.storeName, 'مخبز السلام');
      expect(decoded.purchaseDate, '2026-09-04');
      expect(decoded.nationalId, '900111222');
      expect(decoded.storeId, 3);
    });

    test('round-trip encode and decode preserves equality', () {
      for (final p in [payload, fullPayload]) {
        final encoded = p.encode();
        final roundTripped = QrPayload.decode(encoded);
        expect(roundTripped, equals(p));
        expect(roundTripped.hashCode, equals(p.hashCode));
      }
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

    test('legacy code without v key still decodes (pre-versioning)', () {
      final legacyJson = jsonEncode({
        'purchase_id': 'purchase_123',
        'user_name': 'أحمد محمود',
        'store_name': 'مخبز الأمل',
        'purchase_date': '2026-09-03',
      });
      final decoded = QrPayload.tryDecode(legacyJson);
      expect(decoded, isNotNull);
      expect(decoded?.purchaseId, 'purchase_123');
      expect(decoded?.nationalId, isNull);
      expect(decoded?.storeId, isNull);
      expect(decoded, equals(payload));
    });

    test('unknown future version is rejected, not mis-decoded', () {
      final futureJson = jsonEncode({
        'v': qrPayloadVersion + 1,
        'purchase_id': 'x',
        'user_name': 'a',
        'store_name': 'b',
        'purchase_date': 'c',
      });
      expect(QrPayload.tryDecode(futureJson), isNull);
      expect(() => QrPayload.decode(futureJson), throwsFormatException);
    });
  });
}
