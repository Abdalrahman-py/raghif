import 'dart:math';

/// Mock service for simulating Jawwal Pay payment authorization.
///
/// In this prototype, there is no real SMS gateway or Jawwal Pay business API.
/// This service generates a 4-digit OTP client-side, displays it on-screen,
/// and validates user input.
class MockJawwalPayService {
  MockJawwalPayService({Random? random, String? initialCode})
    : _random = random ?? Random(),
      _currentCode = initialCode;

  final Random _random;
  String? _currentCode;

  /// Returns the existing generated code, or generates a new 4-digit code
  /// if none has been created yet.
  String generateCode() {
    _currentCode ??= (_random.nextInt(9000) + 1000).toString();
    return _currentCode!;
  }

  /// The active OTP code, or null if not yet generated.
  String? get code => _currentCode;

  /// Resend re-displays the same generated code rather than issuing a new one.
  String resendCode() {
    return generateCode();
  }

  /// Verifies the entered code.
  /// Returns `true` if the entered code matches the generated code, `false` otherwise.
  bool verifyCode(String entered) {
    if (_currentCode == null) return false;
    return entered.trim() == _currentCode;
  }

  /// Reset the service state if needed.
  void reset() {
    _currentCode = null;
  }
}
