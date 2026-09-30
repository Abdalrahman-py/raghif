import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/queue/owner_dashboard_screen.dart';
import 'package:raghif/features/queue/queue_logic.dart';

import '../support/queue_test_harness.dart';
import 'tolerant_golden_comparator.dart';
import 'test_fonts.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Renders the owner dashboard in the state that matters: bags running low, one
/// buyer already paid and waiting to collect, nothing unsaved. Hierarchy, the
/// RTL placement of the counter and the pinned action are then checked as
/// pixels rather than as widget lookups.
///
/// Two sizes, because the 28sp counter and the two-up time pickers have to
/// survive both: a mid-range phone (360x800dp logical, the size the other
/// goldens use) and a small old one (320x640dp), which is the deployment
/// target per UI_SPEC.md. A RenderFlex overflow fails these tests outright.
void main() {
  setUpAll(() {
    goldenFileComparator = TolerantGoldenComparator(
      Uri.parse('test/goldens/owner_dashboard_screen_golden_test.dart'),
    );
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = logicalSize * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const Authenticated(
        UserModel(
          id: seededOwnerId,
          phone: '0599000002',
          nationalId: '900333444',
          name: 'صاحب المخبز',
          role: UserRole.owner,
          verificationStatus: VerificationStatus.verified,
        ),
      ),
    );
    addTearDown(authBloc.close);

    final harness = buildQueueHarness(actingAs: seededBuyerId);
    addTearDown(harness.controller.dispose);
    addTearDown(harness.repo.dispose);

    // Store-rimal is seeded with 45 of 300 bags left today. Sell 30 across
    // earlier dates (one bag per ID per day is enforced, so each needs its own
    // date) to push it under the low-stock threshold, then one today — that
    // buyer is the live "بانتظار الاستلام" count, and the counter lands on 14.
    final today = DateTime.now();
    for (var i = 0; i < 30; i++) {
      await harness.repo.reserveBag(
        storeId: seededStoreId,
        date: todayDateString(today.subtract(Duration(days: i + 1))),
      );
    }
    await harness.repo.reserveBag(
      storeId: seededStoreId,
      date: todayDateString(),
    );

    // The screen being rendered is the owner's, and the owner-only writes it
    // offers are attributed to the signed-in user.
    harness.repo.currentUserId = seededOwnerId;

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          // The app forces RTL in main.dart; the golden has to match.
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: OwnerDashboardScreen(
            controller: harness.controller,
            storeId: seededStoreId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OwnerDashboardScreen matches golden (360x800dp)', (
    tester,
  ) async {
    await pumpDashboard(tester, logicalSize: const Size(360, 800));

    await expectLater(
      find.byType(OwnerDashboardScreen),
      matchesGoldenFile('owner_dashboard_screen.png'),
    );
  });

  testWidgets('OwnerDashboardScreen matches golden on a small phone '
      '(320x640dp)', (tester) async {
    await pumpDashboard(tester, logicalSize: const Size(320, 640));

    await expectLater(
      find.byType(OwnerDashboardScreen),
      matchesGoldenFile('owner_dashboard_screen_small.png'),
    );
  });
}
