import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/input/digits_formatter.dart';

void main() {
  test('Arabic-Indic and Persian digits become ASCII, the rest is dropped', () {
    expect(AsciiDigitsFormatter.normalize('٠٥٦٨ ٠٠٠٠٠٢'), '0568000002');
    expect(AsciiDigitsFormatter.normalize('۲۵۸۰'), '2580');
    expect(AsciiDigitsFormatter.normalize('+972-59a'), '97259');
  });

  test('a typed Arabic digit lands in the field as an ASCII digit', () {
    const formatter = AsciiDigitsFormatter();
    final out = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '٢',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    expect(out.text, '2');
    expect(out.selection.baseOffset, 1);
  });
}
