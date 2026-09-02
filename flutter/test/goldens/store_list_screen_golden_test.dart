import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/queue/queue_controller.dart';
import 'package:raghif/features/queue/store_list_screen.dart';

import 'test_fonts.dart';

void main() {
  testWidgets('StoreListScreen matches golden', (WidgetTester tester) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final controller = QueueController();
    const user = DemoUser(
      phone: demoBuyerPhone,
      pin: demoBuyerPin,
      role: UserRole.buyer,
      name: 'أحمد ناصر',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: StoreListScreen(controller: controller, currentUser: user),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(StoreListScreen),
      matchesGoldenFile('store_list_screen.png'),
    );
  });
}
