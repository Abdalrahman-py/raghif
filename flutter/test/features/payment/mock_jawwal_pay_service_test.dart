import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/features/payment/mock_jawwal_pay_service.dart';

void main() {
  group('MockJawwalPayService', () {
    late MockJawwalPayService service;

    setUp(() {
      service = MockJawwalPayService();
    });

    test('generates a 4-digit code', () {
      final code = service.generateCode();
      expect(code.length, equals(4));
      expect(int.tryParse(code), isNotNull);
      expect(service.code, equals(code));
    });

    test('correct code -> verified', () {
      final code = service.generateCode();
      expect(service.verifyCode(code), isTrue);
      expect(service.verifyCode(' $code '), isTrue);
    });

    test('wrong code -> rejected, still retryable', () {
      final code = service.generateCode();
      final wrongCode = code == '1111' ? '2222' : '1111';

      expect(service.verifyCode(wrongCode), isFalse);
      expect(service.verifyCode('0000'), isFalse);
      // Still retryable with the original code
      expect(service.verifyCode(code), isTrue);
    });

    test('resend -> same code re-displayed (not regenerated)', () {
      final initialCode = service.generateCode();
      final resentCode = service.resendCode();

      expect(resentCode, equals(initialCode));
      expect(service.code, equals(initialCode));
    });

    test('accepts initial deterministic code for testing', () {
      final testService = MockJawwalPayService(initialCode: '4821');
      expect(testService.code, equals('4821'));
      expect(testService.generateCode(), equals('4821'));
      expect(testService.verifyCode('4821'), isTrue);
      expect(testService.verifyCode('9999'), isFalse);
    });

    test('reset clears active code', () {
      service.generateCode();
      expect(service.code, isNotNull);
      service.reset();
      expect(service.code, isNull);
    });
  });
}
