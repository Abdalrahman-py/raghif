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
    nationalId: '900111222',
    name: 'أحمد ناصر',
  );

  const demoBuyer = UserModel(
    id: 'user-demo-buyer',
    phone: '0599111111',
    nationalId: demoBuyerNationalId,
    name: 'أحمد ناصر',
  );

  Future<AuthBloc> pumpLogin(
    WidgetTester tester, {
    List<UserModel>? users,
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
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  Finder nationalIdField() => fieldByLabel(Strings.personalIdLabel);
  Finder otpField() => fieldByLabel(Strings.otpLabel);
  Finder pinField() => fieldByLabel(Strings.pinLabel);

  /// Unmounts the screen so its resend cooldown timer is cancelled — a live
  /// periodic timer at the end of a test is a failure, not a warning.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// Types the buyer's ID and taps continue: the PIN question.
  Future<void> reachPinStep(WidgetTester tester) async {
    await tester.enterText(nationalIdField(), buyer.nationalId);
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on one question: the national ID', (tester) async {
    await pumpLogin(tester);

    expect(find.text(Strings.loginIdTitle), findsOneWidget);
    expect(nationalIdField(), findsOneWidget);
    expect(find.text(Strings.continueButton), findsOneWidget);
    // Nothing that asks a second question or offers a second way in.
    expect(pinField(), findsNothing);
    expect(otpField(), findsNothing);
    expect(find.text(Strings.forgotPin), findsNothing);
  });

  testWidgets('an empty National ID is reported on the field', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.nationalIdRequired), findsOneWidget);
    expect(find.text(Strings.registerError), findsNothing);
    expect(pinField(), findsNothing);
  });

  testWidgets('a short National ID is refused with its own message', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(nationalIdField(), '90011');
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.nationalIdLengthError), findsOneWidget);
    expect(pinField(), findsNothing);
  });

  testWidgets('typing clears the error the field just showed', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.nationalIdRequired), findsOneWidget);

    await tester.enterText(nationalIdField(), '9001112');
    await tester.pumpAndSettle();
    expect(find.text(Strings.nationalIdRequired), findsNothing);
  });

  testWidgets('a nine-digit ID moves to the PIN question, no request sent', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester);

    await reachPinStep(tester);

    expect(find.text(Strings.loginPinTitle), findsOneWidget);
    expect(find.text(Strings.loginForId(buyer.nationalId)), findsOneWidget);
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
    expect((bloc.state as Authenticated).user.nationalId, buyer.nationalId);
  });

  testWidgets('back returns to the ID with what was typed', (tester) async {
    await pumpLogin(tester);
    await reachPinStep(tester);

    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();

    expect(find.text(Strings.loginIdTitle), findsOneWidget);
    expect(
      tester.widget<TextField>(nationalIdField()).controller!.text,
      buyer.nationalId,
    );
  });

  testWidgets('an ID with no account is told so, with registration beside it', (
    tester,
  ) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(users: const []),
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

    await tester.enterText(nationalIdField(), '999999999');
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
    await tester.enterText(pinField(), '0000');
    await tester.pumpAndSettle();

    expect(find.text(Strings.nationalIdNotFound), findsOneWidget);
    expect(find.text(Strings.createAccountLink), findsOneWidget);
  });

  testWidgets('forgot PIN sends the code and shows it, resend on cooldown', (
    tester,
  ) async {
    await pumpLogin(tester);
    await reachPinStep(tester);

    await tester.tap(find.text(Strings.forgotPin));
    // pumpAndSettle would spin against the 1s resend countdown.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(Strings.loginOtpTitle), findsOneWidget);
    expect(otpField(), findsOneWidget);
    expect(find.text(Strings.demoOtpBanner('1234')), findsOneWidget);
    expect(find.text(Strings.demoOtpTapToFill), findsOneWidget);
    expect(find.text(Strings.resendOtpIn(30)), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('tapping the shown code fills it and signs the user in', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester);
    await reachPinStep(tester);
    await tester.tap(find.text(Strings.forgotPin));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text(Strings.demoOtpTapToFill));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(bloc.state, isA<Authenticated>());
    expect((bloc.state as Authenticated).user.nationalId, buyer.nationalId);

    await unmount(tester);
  });

  testWidgets('a demo account signs in with one tap, out of the way', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester, users: const [demoBuyer]);

    // Present but quiet: one small link, not a card on the first screen.
    expect(find.text(Strings.demoBuyerLabel), findsNothing);
    await tester.tap(find.text(Strings.demoAccountsTitle));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        '${Strings.demoBuyerLabel} — $demoBuyerNationalId / $demoBuyerPin',
      ),
    );
    await tester.pumpAndSettle();

    expect(bloc.state, isA<Authenticated>());
    expect((bloc.state as Authenticated).user.nationalId, demoBuyerNationalId);
  });

  testWidgets('a PIN attempt with no connection says so, not "not registered"', (
    tester,
  ) async {
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

    await tester.enterText(nationalIdField(), buyer.nationalId);
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
    await tester.enterText(pinField(), '1234');
    await tester.pumpAndSettle();

    expect(find.text(Strings.loginOffline), findsOneWidget);
    expect(find.text(Strings.nationalIdNotFound), findsNothing);
    // Nothing to register for: the connection is the problem, and the PIN
    // field is still there to try again.
    expect(find.text(Strings.createAccountLink), findsNothing);
    expect(pinField(), findsOneWidget);
  });

  testWidgets('creating an account is one tap from the first screen', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.createAccountLink));
    await tester.pumpAndSettle();

    expect(find.text(Strings.registerButton), findsWidgets);
  });
}
