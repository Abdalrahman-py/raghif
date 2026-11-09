import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/demo_accounts.dart';
import 'package:raghif/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/finders.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// A registered buyer, so the PIN and code paths have somewhere to land.
  const buyer = UserModel(
    id: 'user-buyer',
    phone: '0599111111',
    name: 'أحمد ناصر',
  );

  const demoBuyer = UserModel(
    id: 'user-demo-buyer',
    phone: '0599111111',
    name: 'أحمد ناصر',
  );

  Future<AuthBloc> pumpLogin(
    WidgetTester tester, {
    List<UserModel>? users,
    bool showDemoAccounts = false,
  }) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(users: users ?? const [buyer]),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: LoginScreen(showDemoAccounts: showDemoAccounts),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  Finder phoneField() => fieldByLabel(Strings.phoneLabel);
  Finder pinField() => fieldByLabel(Strings.pinLabel);

  /// Unmounts the screen so its resend cooldown timer is cancelled — a live
  /// periodic timer at the end of a test is a failure, not a warning.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// Types the buyer's ID and taps continue: the PIN question.
  Future<void> reachPinStep(WidgetTester tester) async {
    await tester.enterText(phoneField(), buyer.phone);
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on one question: the national ID', (tester) async {
    await pumpLogin(tester);

    expect(find.text(Strings.loginIdTitle), findsOneWidget);
    expect(phoneField(), findsOneWidget);
    expect(find.text(Strings.continueButton), findsOneWidget);
    // Nothing that asks a second question or offers a second way in.
    expect(pinField(), findsNothing);
    expect(find.text(Strings.forgotPin), findsNothing);
  });

  testWidgets('an empty National ID is reported on the field', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.phoneRequired), findsOneWidget);
    expect(find.text(Strings.registerError), findsNothing);
    expect(pinField(), findsNothing);
  });

  testWidgets('a short phone number is refused with its own message', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(phoneField(), '05991');
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.phoneInvalid), findsOneWidget);
    expect(pinField(), findsNothing);
  });

  testWidgets('typing clears the error the field just showed', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.phoneRequired), findsOneWidget);

    await tester.enterText(phoneField(), '059911');
    await tester.pumpAndSettle();
    expect(find.text(Strings.phoneRequired), findsNothing);
  });

  testWidgets('a ten-digit number moves to the PIN question, no request sent', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester);

    await reachPinStep(tester);

    expect(find.text(Strings.loginPinTitle), findsOneWidget);
    expect(find.text(Strings.loginForId(buyer.phone)), findsOneWidget);
    expect(pinField(), findsOneWidget);
    expect(find.text(Strings.forgotPin), findsOneWidget);
    expect(bloc.state, isNot(isA<AuthLoading>()));
  });

  testWidgets('the fourth PIN digit signs the user in', (tester) async {
    final bloc = await pumpLogin(tester);
    await reachPinStep(tester);

    await tester.enterText(pinField(), '1234');
    await tester.pumpAndSettle();

    expect(bloc.state, isA<Authenticated>());
    expect((bloc.state as Authenticated).user.phone, buyer.phone);
  });

  testWidgets(
    'after a wrong PIN the field is empty and ready: type again and sign in',
    (tester) async {
      final repo = FakeAuthRepository(users: const [buyer])
        ..requiredPin = '5555';
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reachPinStep(tester);

      await tester.enterText(pinField(), '0000');
      await tester.pumpAndSettle();

      // Refused: the message shows, the wrong digits are gone, and the field
      // can be typed into straight away (it was disabled and unfocused before).
      expect(find.text(Strings.loginError), findsOneWidget);
      final field = tester.widget<TextField>(pinField());
      expect(field.controller!.text, isEmpty);
      expect(field.readOnly, isFalse);
      expect(field.focusNode!.hasFocus, isTrue);

      await tester.enterText(pinField(), '5555');
      await tester.pumpAndSettle();
      expect(bloc.state, isA<Authenticated>());
    },
  );

  testWidgets('back returns to the ID with what was typed', (tester) async {
    await pumpLogin(tester);
    await reachPinStep(tester);

    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();

    expect(find.text(Strings.loginIdTitle), findsOneWidget);
    expect(
      tester.widget<TextField>(phoneField()).controller!.text,
      buyer.phone,
    );
  });

  testWidgets('an ID with no account is told so, with registration beside it', (
    tester,
  ) async {
    final bloc = AuthBloc(authRepository: FakeAuthRepository(users: const []));
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(phoneField(), '0500000000');
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
    await tester.enterText(pinField(), '0000');
    await tester.pumpAndSettle();

    expect(find.text(Strings.phoneNotFound), findsOneWidget);
    expect(find.text(Strings.createAccountLink), findsOneWidget);
  });

  testWidgets('forgot PIN points to support and never shows a code', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester);
    await reachPinStep(tester);

    await tester.tap(find.text(Strings.forgotPin));
    await tester.pumpAndSettle();

    expect(find.text(Strings.forgotPinTitle), findsOneWidget);
    expect(find.text(Strings.forgotPinBody), findsOneWidget);
    // No second sign-in route: still signed out, no code anywhere.
    expect(bloc.state, isNot(isA<Authenticated>()));
    expect(find.textContaining('4821'), findsNothing);

    await tester.tap(find.text(Strings.ok));
    await tester.pumpAndSettle();
    expect(find.text(Strings.forgotPinTitle), findsNothing);

    await unmount(tester);
  });

  testWidgets('release builds do not offer the demo accounts', (tester) async {
    await pumpLogin(tester);

    expect(find.text(Strings.demoAccountsTitle), findsNothing);
    expect(kShowDemoAccounts, isFalse);
  });

  testWidgets('a demo account signs in with one tap, out of the way', (
    tester,
  ) async {
    final bloc = await pumpLogin(
      tester,
      users: const [demoBuyer],
      showDemoAccounts: true,
    );

    // Present but quiet: one small link, not a card on the first screen.
    expect(find.text(Strings.demoBuyerLabel), findsNothing);
    await tester.tap(find.text(Strings.demoAccountsTitle));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('${Strings.demoBuyerLabel} — $demoBuyerPhone / $demoBuyerPin'),
    );
    await tester.pumpAndSettle();

    expect(bloc.state, isA<Authenticated>());
    expect((bloc.state as Authenticated).user.phone, demoBuyerPhone);
  });

  testWidgets(
    'a PIN attempt with no connection says so, not "not registered"',
    (tester) async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(
          users: const [buyer],
          failWith: Exception('SocketException: Failed host lookup'),
        ),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(phoneField(), buyer.phone);
      await tester.tap(find.text(Strings.continueButton));
      await tester.pumpAndSettle();
      await tester.enterText(pinField(), '1234');
      await tester.pumpAndSettle();

      expect(find.text(Strings.loginOffline), findsOneWidget);
      expect(find.text(Strings.phoneNotFound), findsNothing);
      // Nothing to register for: the connection is the problem, and the PIN
      // field is still there to try again.
      expect(find.text(Strings.createAccountLink), findsNothing);
      expect(pinField(), findsOneWidget);
    },
  );

  testWidgets('creating an account is one tap from the first screen', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.createAccountLink));
    await tester.pumpAndSettle();

    // The account is created one question at a time.
    expect(find.text(Strings.stepOf(1, 3)), findsOneWidget);
  });
}
