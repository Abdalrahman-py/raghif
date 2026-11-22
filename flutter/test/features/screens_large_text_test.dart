import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/store_list_entry.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/account/account_screen.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/queue/buyer_stores_home.dart';

import '../support/fake_auth_repository.dart';

/// The constitution's large-text promise for the redesigned screens: at 2x
/// system text on a 320dp phone nothing overflows. (The حجزي cards are covered
/// in buyer_home_screen_test.dart.)
void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('account screen fits at 2x text', (tester) async {
    const user = UserModel(id: 'a', phone: '0599111111', name: 'أحمد ناصر');
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(users: [user], sessionUserId: 'a'),
    );
    addTearDown(bloc.close);
    bloc.add(const CheckAuthSessionEvent());
    await pump(
      tester,
      BlocProvider.value(value: bloc, child: const AccountScreen()),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('أحمد ناصر'), findsOneWidget);
  });

  for (final open in [true, false]) {
    testWidgets('bakery card fits at 2x text (open: $open)', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BakeryCard(
                entry: StoreListEntry(
                  store: StoreModel(
                    id: 's',
                    name: 'مخبز الشاطئ الغربي',
                    area: 'الشاطئ',
                    isOpen: open,
                    dailyBagLimit: 300,
                    bagsRemaining: open ? 120 : 0,
                    openTime: '06:00',
                    closeTime: '14:00',
                  ),
                ),
                onBuy: () {},
                onOpen: () {},
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
