import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raghif/main.dart';
import 'package:raghif/core/i18n/strings.dart';

void main() {
  testWidgets('RaghifApp renders the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RaghifApp());

    expect(find.text(Strings.appTitle), findsOneWidget);
    expect(find.text(Strings.loginButton), findsOneWidget);
    expect(find.text(Strings.phoneLabel), findsOneWidget);
    expect(find.text(Strings.pinLabel), findsOneWidget);

    // App is forced RTL regardless of device locale.
    expect(
      find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );
  });
}
