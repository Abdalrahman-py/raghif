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

  const created = UserModel(id: 'u1', phone: '0599111111', name: 'أحمد ناصر');

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.validateRegistration(
        phone: any(named: 'phone'),
        pin: any(named: 'pin'),
        name: any(named: 'name'),
      ),
    ).thenReturn(null);
    when(() => repo.phoneExists(any())).thenAnswer((_) async => false);
    when(
      () => repo.register(
        phone: any(named: 'phone'),
        pin: any(named: 'pin'),
        name: any(named: 'name'),
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

  /// Name and phone, leaving the PIN step on screen.
  Future<void> reachPin(WidgetTester tester) async {
    await fill(tester, Strings.nameLabel, 'أحمد ناصر');
    await next(tester);
    await fill(tester, Strings.phoneLabel, '0599111111');
    await next(tester);
  }

  /// Everything typed, the last step (PIN) on screen, ready to submit.
  Future<void> reachSubmit(WidgetTester tester) async {
    await reachPin(tester);
    await fill(tester, Strings.pinLabel, '5921');
    await fill(tester, Strings.confirmPinLabel, '5921');
  }

  testWidgets('asks one thing at a time, starting with the name', (
    tester,
  ) async {
    await pumpScreen(tester, storeName: 'مخبز الأمل');

    expect(find.text(Strings.stepOf(1, 3)), findsOneWidget);
    expect(find.text(Strings.stepNameTitle), findsOneWidget);
    expect(fieldByLabel(Strings.nameLabel), findsOneWidget);
    expect(fieldByLabel(Strings.phoneLabel), findsNothing);
    expect(find.text(Strings.registrationFor('مخبز الأمل')), findsOneWidget);
  });

  testWidgets('a blank step names what is missing and does not advance', (
    tester,
  ) async {
    await pumpScreen(tester);

    await next(tester);

    expect(find.text(Strings.nameRequired), findsOneWidget);
    expect(find.text(Strings.stepOf(1, 3)), findsOneWidget);
  });

  testWidgets('the phone must be a Jawwal Pay number', (tester) async {
    await pumpScreen(tester);
    await fill(tester, Strings.nameLabel, 'أحمد ناصر');
    await next(tester);

    for (final bad in ['12345', '0591234567'.replaceRange(2, 3, '8')]) {
      await fill(tester, Strings.phoneLabel, bad);
      await next(tester);
      expect(find.text(Strings.phoneInvalid), findsOneWidget);
      expect(find.text(Strings.stepOf(2, 3)), findsOneWidget);
    }
  });

  testWidgets('repeated or sequential PINs are refused, mismatches too', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachPin(tester);

    await fill(tester, Strings.pinLabel, '1234');
    await fill(tester, Strings.confirmPinLabel, '1234');
    await next(tester, label: Strings.registerButton);
    expect(find.text(Strings.pinTooWeak), findsOneWidget);

    await fill(tester, Strings.pinLabel, '7777');
    await fill(tester, Strings.confirmPinLabel, '7777');
    await next(tester, label: Strings.registerButton);
    expect(find.text(Strings.pinTooWeak), findsOneWidget);

    await fill(tester, Strings.pinLabel, '5921');
    await fill(tester, Strings.confirmPinLabel, '4321');
    await next(tester, label: Strings.registerButton);
    expect(find.text(Strings.pinMismatch), findsOneWidget);
    expect(find.text(Strings.stepOf(3, 3)), findsOneWidget);
    verifyNever(
      () => repo.register(
        phone: any(named: 'phone'),
        pin: any(named: 'pin'),
        name: any(named: 'name'),
      ),
    );
  });

  testWidgets('the last step submits name, phone and PIN', (tester) async {
    await pumpScreen(tester);
    await reachSubmit(tester);

    expect(find.text(Strings.stepOf(3, 3)), findsOneWidget);
    await next(tester, label: Strings.registerButton);

    verify(
      () => repo.register(phone: '0599111111', pin: '5921', name: 'أحمد ناصر'),
    ).called(1);
    expect(bloc.state, isA<Authenticated>());
  });

  testWidgets('an already-registered phone sends the person back to it', (
    tester,
  ) async {
    when(() => repo.phoneExists(any())).thenAnswer((_) async => true);
    await pumpScreen(tester);
    await reachSubmit(tester);
    await next(tester, label: Strings.registerButton);

    expect(find.text(Strings.stepOf(2, 3)), findsOneWidget);
    expect(fieldByLabel(Strings.phoneLabel), findsOneWidget);
    expect(find.text(Strings.phoneAlreadyRegistered), findsOneWidget);
  });

  testWidgets('back returns to the previous step with the value kept', (
    tester,
  ) async {
    await pumpScreen(tester);
    await fill(tester, Strings.nameLabel, 'أحمد ناصر');
    await next(tester);
    expect(find.text(Strings.stepOf(2, 3)), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();

    expect(find.text(Strings.stepOf(1, 3)), findsOneWidget);
    final name = tester.widget<TextField>(fieldByLabel(Strings.nameLabel));
    expect(name.controller!.text, 'أحمد ناصر');
  });
}
