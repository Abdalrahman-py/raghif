import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/store_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/login_screen.dart';
import 'package:raghif/features/auth/registration_screen.dart';
import 'package:raghif/features/guest/guest_home_screen.dart';
import '../../support/fake_queue_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Eight bakeries; s8 sold the most today, s1 the least.
class _Eight extends FakeQueueRepository {
  _Eight()
    : super(
        stores: [
          for (var i = 1; i <= 8; i++)
            StoreModel(
              id: 's$i',
              name: 'مخبز رقم $i',
              isOpen: true,
              dailyBagLimit: 100,
              // s8 sold the most today, s1 the least.
              bagsRemaining: 100 - i * 10,
              area: 'منطقة',
            ),
        ],
      );
}

class _FailingStores extends Fake implements QueueRepository {
  @override
  Future<List<StoreModel>> getStores() async => throw Exception('offline');
}

void main() {
  late AuthBloc bloc;

  setUp(() => bloc = AuthBloc(authRepository: MockAuthRepository()));
  tearDown(() async => bloc.close());

  Future<void> pump(WidgetTester tester, QueueRepository repo) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(home: GuestHomeScreen(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the bakeries and the day\'s stock with no account', (
    tester,
  ) async {
    final repo = FakeQueueRepository.seeded();
    final stores = await repo.getStores();
    await pump(tester, repo);

    expect(find.text(Strings.guestTagline), findsOneWidget);
    expect(find.text(stores.first.name), findsWidgets);
    // Nothing personal is asked for yet.
    expect(find.byType(TextField), findsNothing);
    final bookable = stores.where((s) => s.canPurchase).toList();
    final bags = bookable.fold<int>(0, (sum, s) => sum + s.bagsRemaining);
    expect(
      find.text(Strings.guestSummary(bookable.length, bags)),
      findsOneWidget,
    );
  });

  testWidgets('shows only the five that sold most today, most first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pump(tester, _Eight());

    for (final shown in [8, 7, 6, 5, 4]) {
      expect(find.text('مخبز رقم $shown'), findsOneWidget);
    }
    for (final hidden in [3, 2, 1]) {
      expect(find.text('مخبز رقم $hidden'), findsNothing);
    }
    final top = tester.getTopLeft(find.text('مخبز رقم 8')).dy;
    final next = tester.getTopLeft(find.text('مخبز رقم 7')).dy;
    expect(top, lessThan(next));
    // The summary still counts every bakery, not just the five.
    expect(find.text(Strings.guestSummary(8, 440)), findsOneWidget);
  });

  testWidgets('choosing a bakery and booking starts the account steps', (
    tester,
  ) async {
    final repo = FakeQueueRepository.seeded();
    final stores = await repo.getStores();
    await pump(tester, repo);

    await tester.tap(find.text(stores.first.name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.guestBook));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
    expect(find.text(Strings.stepOf(1, 3)), findsOneWidget);
    expect(find.textContaining(stores.first.name), findsWidgets);
  });

  testWidgets('create account and sign in are both one tap away', (
    tester,
  ) async {
    await pump(tester, FakeQueueRepository.seeded());

    await tester.scrollUntilVisible(
      find.text(Strings.guestHaveAccount),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.guestHaveAccount));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    // Pushed from the guest screen, so there is a way back.
    expect(find.byTooltip(Strings.back), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(Strings.guestCreateAccount),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.guestCreateAccount));
    await tester.pumpAndSettle();
    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('a failed load says so and can be retried', (tester) async {
    await pump(tester, _FailingStores());

    expect(find.byKey(const Key('guest-error')), findsOneWidget);
    expect(find.text(Strings.guestRetry), findsOneWidget);
  });
}
