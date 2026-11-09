import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/features/legal/legal_screens.dart';

void main() {
  testWidgets('privacy policy shows its sections and the support number', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LegalScreen.privacy()));

    expect(find.text(Strings.privacyTitle), findsOneWidget);
    expect(find.text('ما الذي نجمعه'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining(Strings.supportWhatsapp),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining(Strings.supportWhatsapp), findsOneWidget);
  });

  testWidgets('terms of use show their sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LegalScreen.terms()));

    expect(find.text(Strings.termsTitle), findsOneWidget);
    expect(find.text('الدفع'), findsOneWidget);
  });

  test('every recovery message gives support\'s WhatsApp number', () {
    for (final text in [
      Strings.forgotPinBody,
      Strings.loginLocked,
      Strings.phoneChangeViaSupport,
      Strings.deleteAccountBody,
      Strings.ownerViaSupport,
    ]) {
      expect(text, contains('+972599060214'));
    }
  });
}
