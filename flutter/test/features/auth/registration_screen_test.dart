import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/registration_screen.dart';
import '../../support/finders.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late AuthBloc bloc;

  const created = UserModel(
    id: 'u1',
    phone: '0599111111',
    nationalId: '900111222',
    name: 'أحمد ناصر',
  );

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.validateRegistration(
        phone: any(named: 'phone'),
        pin: any(named: 'pin'),
        nationalId: any(named: 'nationalId'),
        name: any(named: 'name'),
        jawwalPayNumber: any(named: 'jawwalPayNumber'),
      ),
    ).thenReturn(null);
    when(() => repo.phoneExists(any())).thenAnswer((_) async => false);
    when(() => repo.nationalIdExists(any())).thenAnswer((_) async => false);
    when(
      () => repo.register(
        phone: any(named: 'phone'),
        pin: any(named: 'pin'),
        nationalId: any(named: 'nationalId'),
        name: any(named: 'name'),
        jawwalPayNumber: any(named: 'jawwalPayNumber'),
      ),
    ).thenAnswer((_) async => created);
  });

  tearDown(() async {
    await bloc.close();
  });

  Future<void> pumpScreen(WidgetTester tester, {String? storeName}) async {
    // Built inside the test body so its awaited calls run on the test clock.
    bloc = AuthBloc(authRepository: repo);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(home: RegistrationScreen(storeName: storeName)),
      ),
    );
  }

  Future<void> next(WidgetTester tester, {String? label}) async {
    final button = find.text(label ?? Strings.stepsNext);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    // The bloc's checks are a chain of awaited calls; give each a turn.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String label, String value) async {
    await tester.enterText(fieldByLabel(label), value);
    await tester.pump();
  }

  /// Name, ID and phone, leaving the PIN step on screen.
  Future<void> reachPin(WidgetTester tester) async {
    await fill(tester, Strings.nameLabel, 'أحمد ناصر');
    await next(tester);
    await fill(tester, Strings.personalIdLabel, '900111222');
    await next(tester);
    await fill(tester, Strings.phoneLabel, '0599111111');
    await next(tester);
  }

  Future<void> reachWallet(WidgetTester tester) async {
    await reachPin(tester);
    await fill(tester, Strings.pinLabel, '5921');
    await fill(tester, Strings.confirmPinLabel, '5921');
    await next(tester);
  }

  void verifyRegistered({required String? wallet}) {
    verify(
      () => repo.register(
        phone: '0599111111',
        pin: '5921',
        nationalId: '900111222',
        name: 'أحمد ناصر',
        jawwalPayNumber: wallet,
      ),
    ).called(1);
  }

  testWidgets('asks one thing at a time, starting with the name', (
    tester,
  ) async {
    await pumpScreen(tester, storeName: 'مخبز الأمل');

    expect(find.text(Strings.stepOf(1, 5)), findsOneWidget);
    expect(find.text(Strings.stepNameTitle), findsOneWidget);
    expect(fieldByLabel(Strings.nameLabel), findsOneWidget);
    expect(fieldByLabel(Strings.personalIdLabel), findsNothing);
    expect(fieldByLabel(Strings.phoneLabel), findsNothing);
    expect(find.text(Strings.registrationFor('مخبز الأمل')), findsOneWidget);
  });

  testWidgets('a blank step names what is missing and does not advance', (
    tester,
  ) async {
    await pumpScreen(tester);

    await next(tester);

    expect(find.text(Strings.nameRequired), findsOneWidget);
    expect(find.text(Strings.stepOf(1, 5)), findsOneWidget);
  });

  testWidgets('each step validates its own field', (tester) async {
    await pumpScreen(tester);
    await fill(tester, Strings.nameLabel, 'أحمد ناصر');
    await next(tester);

    await fill(tester, Strings.personalIdLabel, '123');
    await next(tester);
    expect(find.text(Strings.nationalIdLengthError), findsOneWidget);
    expect(find.text(Strings.stepOf(2, 5)), findsOneWidget);

    await fill(tester, Strings.personalIdLabel, '900111222');
    await next(tester);
    await fill(tester, Strings.phoneLabel, '12345');
    await next(tester);
    expect(find.text(Strings.phoneInvalid), findsOneWidget);
    expect(find.text(Strings.stepOf(3, 5)), findsOneWidget);
  });

  testWidgets('repeated or sequential PINs are refused, mismatches too', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachPin(tester);

    await fill(tester, Strings.pinLabel, '1234');
    await fill(tester, Strings.confirmPinLabel, '1234');
    await next(tester);
    expect(find.text(Strings.pinTooWeak), findsOneWidget);

    await fill(tester, Strings.pinLabel, '7777');
    await fill(tester, Strings.confirmPinLabel, '7777');
    await next(tester);
    expect(find.text(Strings.pinTooWeak), findsOneWidget);

    await fill(tester, Strings.pinLabel, '5921');
    await fill(tester, Strings.confirmPinLabel, '4321');
    await next(tester);
    expect(find.text(Strings.pinMismatch), findsOneWidget);
    expect(find.text(Strings.stepOf(4, 5)), findsOneWidget);
    verifyNever(
      () => repo.register(
        phone: any(named: 'phone'),
        pin: any(named: 'pin'),
        nationalId: any(named: 'nationalId'),
        name: any(named: 'name'),
        jawwalPayNumber: any(named: 'jawwalPayNumber'),
      ),
    );
  });

  testWidgets('the wallet step starts as the phone and the last step submits', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachWallet(tester);

    expect(find.text(Strings.stepOf(5, 5)), findsOneWidget);
    final wallet = tester.widget<TextField>(
      fieldByLabel(Strings.jawwalPayNumberLabel),
    );
    expect(wallet.controller!.text, '0599111111');

    await next(tester, label: Strings.registerButton);

    verifyRegistered(wallet: '0599111111');
    expect(bloc.state, isA<Authenticated>());
  });

  testWidgets('the wallet number can be left empty to add later', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachWallet(tester);

    await fill(tester, Strings.jawwalPayNumberLabel, '');
    await next(tester, label: Strings.registerButton);

    verifyRegistered(wallet: null);
  });

  testWidgets('an already-registered phone sends the person back to it', (
    tester,
  ) async {
    when(() => repo.phoneExists(any())).thenAnswer((_) async => true);
    await pumpScreen(tester);
    await reachWallet(tester);
    await next(tester, label: Strings.registerButton);

    expect(find.text(Strings.stepOf(3, 5)), findsOneWidget);
    expect(fieldByLabel(Strings.phoneLabel), findsOneWidget);
    expect(find.text(Strings.phoneAlreadyRegistered), findsOneWidget);
  });

  testWidgets('an already-registered ID sends the person back to it', (
    tester,
  ) async {
    when(() => repo.nationalIdExists(any())).thenAnswer((_) async => true);
    await pumpScreen(tester);
    await reachWallet(tester);
    await next(tester, label: Strings.registerButton);

    expect(find.text(Strings.stepOf(2, 5)), findsOneWidget);
    expect(find.text(Strings.nationalIdAlreadyRegistered), findsOneWidget);
  });

  testWidgets('back returns to the previous step with the value kept', (
    tester,
  ) async {
    await pumpScreen(tester);
    await fill(tester, Strings.nameLabel, 'أحمد ناصر');
    await next(tester);
    expect(find.text(Strings.stepOf(2, 5)), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();

    expect(find.text(Strings.stepOf(1, 5)), findsOneWidget);
    final name = tester.widget<TextField>(fieldByLabel(Strings.nameLabel));
    expect(name.controller!.text, 'أحمد ناصر');
  });
}
