import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/verification/wallet_verification_screen.dart';

Widget _app({
  String? number = '0599123456',
  void Function(String, String)? onVerify,
  String? error,
  bool busy = false,
}) => MaterialApp(
  theme: AppTheme.light,
  home: WalletVerificationScreen(
    initialNumber: number,
    onVerify: onVerify ?? (_, _) {},
    onLogout: () {},
    error: error,
    busy: busy,
  ),
);

Future<void> _tap(WidgetTester t, String text) async {
  await t.ensureVisible(find.text(text));
  await t.tap(find.text(text));
  await t.pump();
}

void main() {
  testWidgets('rejects a malformed number before sending a code', (t) async {
    await t.pumpWidget(_app(number: '123'));
    await _tap(t, Strings.walletVerifySend);
    await t.pump();
    expect(find.text(Strings.jawwalPayInvalid), findsOneWidget);
    expect(find.text(Strings.walletVerifyConfirm), findsNothing);
  });

  testWidgets('wrong code is refused locally, 1234 goes to the callback', (
    t,
  ) async {
    final calls = <(String, String)>[];
    await t.pumpWidget(_app(onVerify: (n, c) => calls.add((n, c))));
    await _tap(t, Strings.walletVerifySend);
    await t.pump();
    expect(find.text(Strings.walletVerifyConfirm), findsOneWidget);

    await t.enterText(find.byType(TextField), '0000');
    await _tap(t, Strings.walletVerifyConfirm);
    await t.pump();
    expect(find.text(Strings.wrongOtpError), findsOneWidget);
    expect(calls, isEmpty);

    await t.enterText(find.byType(TextField), '1234');
    await _tap(t, Strings.walletVerifyConfirm);
    await t.pump();
    expect(calls, [('0599123456', '1234')]);
  });

  testWidgets('change number returns to the number step', (t) async {
    await t.pumpWidget(_app());
    await _tap(t, Strings.walletVerifySend);
    await t.pump();
    await _tap(t, Strings.walletVerifyChangeNumber);
    await t.pump();
    expect(find.text(Strings.walletVerifySend), findsOneWidget);
  });

  testWidgets('shows the server error and blocks a second submit when busy', (
    t,
  ) async {
    final calls = <String>[];
    await t.pumpWidget(
      _app(
        error: Strings.walletVerifyFailed,
        busy: true,
        onVerify: (n, c) => calls.add(c),
      ),
    );
    expect(find.text(Strings.walletVerifyFailed), findsOneWidget);
    await _tap(t, Strings.walletVerifySend);
    await t.pump();
    await t.enterText(find.byType(TextField), '1234');
    await _tap(t, Strings.walletVerifyConfirm);
    await t.pump();
    expect(calls, isEmpty);
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('stays scrollable at $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(_app());
      await _tap(t, Strings.walletVerifySend);
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
