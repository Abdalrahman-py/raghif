import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/session_store.dart';
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

  /// A registered buyer, so the OTP path has somewhere to land.
  const buyer = UserModel(
    id: 'user-buyer',
    phone: '0599111111',
    nationalId: '900111222',
    name: 'أحمد ناصر',
  );

  Future<AuthBloc> pumpLogin(
    WidgetTester tester, {
    List<UserModel>? users,
  }) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(users: users ?? const [buyer]),
      sessionStore: SessionStore(),
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

  Finder nationalIdField() =>
      fieldByLabel(Strings.personalIdLabel);
  Finder otpField() => fieldByLabel(Strings.otpLabel);
  Finder pinField() => fieldByLabel(Strings.pinLabel);

  /// Unmounts the screen so its resend cooldown timer is cancelled — a live
  /// periodic timer at the end of a test is a failure, not a warning.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('offers the PIN route without typing anything first', (
    tester,
  ) async {
    await pumpLogin(tester);

    // The old screen hid this link until a National ID was typed, which meant
    // returning users couldn't see the way they normally log in.
    expect(find.text(Strings.loginWithPinInstead), findsOneWidget);
    expect(find.text(Strings.requestOtpButton), findsOneWidget);
    expect(find.text(Strings.demoAccountsTitle), findsOneWidget);
  });

  testWidgets('an empty National ID is reported on the field', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.requestOtpButton));
    await tester.pumpAndSettle();

    // On the field, and naming the actual problem — not "يرجى تعبئة جميع
    // الحقول" printed under the button.
    expect(find.text(Strings.nationalIdRequired), findsOneWidget);
    expect(find.text(Strings.registerError), findsNothing);
    // Still step one: no event was dispatched.
    expect(otpField(), findsNothing);
  });

  testWidgets('a nine-digit National ID moves to the code step', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(nationalIdField(), buyer.nationalId);
    await tester.tap(find.text(Strings.requestOtpButton));
    // pumpAndSettle would spin against the 1s resend countdown.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(otpField(), findsOneWidget);
    expect(find.text(Strings.otpHelper), findsOneWidget);
    // The code the pilot would have texted, and the wait before resending.
    expect(find.text(Strings.demoOtpBanner('1234')), findsOneWidget);
    expect(find.text(Strings.demoOtpTapToFill), findsOneWidget);
    expect(
      find.text(Strings.resendOtpIn(30)),
      findsOneWidget,
      reason: 'resend starts on cooldown instead of being free to hammer',
    );

    await unmount(tester);
  });

  testWidgets('tapping the shown code fills it and signs the user in', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester);

    await tester.enterText(nationalIdField(), buyer.nationalId);
    await tester.tap(find.text(Strings.requestOtpButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text(Strings.demoOtpTapToFill));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(bloc.state, isA<Authenticated>());
    expect((bloc.state as Authenticated).user.nationalId, buyer.nationalId);

    await unmount(tester);
  });

  testWidgets('an unregistered National ID is pointed at registration', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(nationalIdField(), '999999999');
    await tester.tap(find.text(Strings.requestOtpButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.nationalIdNotFound), findsOneWidget);
    expect(otpField(), findsNothing);
  });

  testWidgets('a demo row fills the PIN form', (tester) async {
    await pumpLogin(tester);

    // The demo block sits at the bottom of the scroll view; on the default
    // 800x600 test surface it is off-screen, and an off-screen tap silently
    // hits nothing.
    final ownerRow = find.text(
      '${Strings.demoOwnerLabel} — $demoOwnerNationalId / $demoOwnerPin',
    );
    await tester.ensureVisible(ownerRow);
    await tester.pumpAndSettle();
    await tester.tap(ownerRow);
    await tester.pumpAndSettle();

    // Switched to PIN mode with both fields populated.
    expect(find.text(Strings.loginButton), findsOneWidget);
    expect(find.text(Strings.loginWithOtpInstead), findsOneWidget);
    expect(
      tester.widget<TextField>(nationalIdField()).controller!.text,
      demoOwnerNationalId,
    );
    expect(tester.widget<TextField>(pinField()).controller!.text, demoOwnerPin);
  });

  testWidgets('typing clears the error the field just showed', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text(Strings.requestOtpButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.nationalIdRequired), findsOneWidget);

    await tester.enterText(nationalIdField(), '9001112');
    await tester.pumpAndSettle();
    expect(find.text(Strings.nationalIdRequired), findsNothing);
  });

  testWidgets('a short National ID is refused with its own message', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(nationalIdField(), '90011');
    await tester.tap(find.text(Strings.requestOtpButton));
    await tester.pumpAndSettle();

    expect(find.text(Strings.nationalIdLengthError), findsOneWidget);
    expect(otpField(), findsNothing);
  });
}
