/// Simulated Jawwal Pay authorization, until the real provider is connected
/// (launch plan, phase 5).
///
/// There is no SMS and no Jawwal Pay merchant API yet, so the "message" with the
/// verification code is faked on screen and the code is always [simulatedCode].
/// This only gates the *simulated* payment: it never signs anybody in, and the
/// payment it leads to is recorded server-side as `provider = 'simulated'`, not
/// as money received. Replace this class with the real gateway behind the same
/// four calls (`generateCode`, `resendCode`, `verifyCode`, `reset`).
class MockJawwalPayService {
  MockJawwalPayService({String? initialCode}) : _currentCode = initialCode;

  /// The one code every simulated payment accepts.
  static const simulatedCode = '1234';

  String? _currentCode;

  /// The code "sent" to the wallet's phone.
  String generateCode() {
    _currentCode ??= simulatedCode;
    return _currentCode!;
  }

  /// The active code, or null if none was "sent" yet.
  String? get code => _currentCode;

  /// Resending shows the same code again.
  String resendCode() => generateCode();

  /// Whether [entered] is the code that was "sent".
  bool verifyCode(String entered) {
    if (_currentCode == null) return false;
    return entered.trim() == _currentCode;
  }

  void reset() {
    _currentCode = null;
  }
}
