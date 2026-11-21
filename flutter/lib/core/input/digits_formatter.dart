import 'package:flutter/services.dart';

/// Digits-only input that also accepts Arabic-Indic (٠-٩) and Persian (۰-۹)
/// digits, turning them into 0-9. `FilteringTextInputFormatter.digitsOnly`
/// drops them silently, so on an Arabic keyboard the field looked dead.
class AsciiDigitsFormatter extends TextInputFormatter {
  const AsciiDigitsFormatter();

  static String normalize(String input) {
    final out = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        out.writeCharCode(rune);
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        out.writeCharCode(rune - 0x0660 + 0x30);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        out.writeCharCode(rune - 0x06F0 + 0x30);
      }
    }
    return out.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = normalize(newValue.text);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
