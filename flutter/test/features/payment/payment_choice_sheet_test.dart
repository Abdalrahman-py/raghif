import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/queue/purchase_flow.dart';

void main() {
  // The sheet opens right after a bag is reserved; with large system text it
  // must scroll, not overflow and hide the cash option.
  for (final scale in [1.0, 2.0]) {
    testWidgets('payment choice sheet fits 320x640 at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      PaymentChoice? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    picked = await showModalBottomSheet<PaymentChoice>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const PaymentChoiceSheet(),
                    ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final cash = find.text(Strings.payCashOption);
      await tester.ensureVisible(cash);
      await tester.pumpAndSettle();
      await tester.tap(cash);
      await tester.pumpAndSettle();
      expect(picked, PaymentChoice.cash);
    });
  }
}
