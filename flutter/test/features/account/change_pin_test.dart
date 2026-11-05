import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/theme/app_theme.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:raghif/features/account/account_screen.dart';
import 'package:raghif/features/account/change_pin_sheet.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  const owner = UserModel(
    id: 'owner-1',
    phone: '0599222222',
    nationalId: '900333444',
    name: 'صاحب المخبز',
    role: UserRole.owner,
    verificationStatus: VerificationStatus.verified,
  );
  const buyer = UserModel(
    id: 'buyer-1',
    phone: '0599111111',
    nationalId: '900111222',
    name: 'أحمد ناصر',
    verificationStatus: VerificationStatus.verified,
  );

  Future<(AuthBloc, FakeAuthRepository)> pumpAccount(
    WidgetTester tester,
    UserModel user,
  ) async {
    final repo = FakeAuthRepository(users: [user], sessionUserId: user.id);
    final bloc = AuthBloc(authRepository: repo)
      ..add(const CheckAuthSessionEvent());
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AccountScreen(authRepository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(bloc.close);
    return (bloc, repo);
  }

  Future<void> open(WidgetTester tester) async {
    final button = find.byKey(const Key('change-pin'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String current = '4829',
    String next = '7351',
    String? confirm,
  }) async {
    await tester.enterText(find.byKey(const Key('pin-current')), current);
    await tester.enterText(find.byKey(const Key('pin-new')), next);
    await tester.enterText(
      find.byKey(const Key('pin-confirm')),
      confirm ?? next,
    );
  }

  Future<void> submit(WidgetTester tester) async {
    final save = find.text('حفظ الرمز الجديد');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('owners and buyers can both change their own PIN', (
    tester,
  ) async {
    await pumpAccount(tester, owner);
    expect(find.byKey(const Key('change-pin')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await pumpAccount(tester, buyer);
    // Support hands out a one-time PIN, so every account needs this button.
    expect(find.byKey(const Key('change-pin')), findsOneWidget);
  });

  testWidgets(
    'a good change goes to the server, closes the sheet and says so',
    (tester) async {
      final (_, repo) = await pumpAccount(tester, owner);
      await open(tester);
      await fill(tester);
      await submit(tester);

      expect(repo.lastPinChange, (currentPin: '4829', newPin: '7351'));
      expect(find.byType(ChangePinSheet), findsNothing);
      expect(find.text('تم تغيير الرمز السري'), findsOneWidget);
    },
  );

  testWidgets('typos are caught before any request is made', (tester) async {
    final (_, repo) = await pumpAccount(tester, owner);
    await open(tester);

    await fill(tester, confirm: '1111'); // new != confirm
    await submit(tester);
    expect(find.text('الرمزان غير متطابقين'), findsOneWidget);

    await fill(tester, current: '12'); // current too short
    await submit(tester);
    expect(find.text('أدخل الرمز الحالي (4 أرقام)'), findsOneWidget);

    expect(repo.lastPinChange, isNull);
    expect(find.byType(ChangePinSheet), findsOneWidget);
  });

  for (final entry in {
    ChangePinResult.wrongPin: 'الرمز الحالي غير صحيح',
    ChangePinResult.locked: 'تم إيقاف تغيير الرمز مؤقتًا',
    ChangePinResult.weakPin: 'الرمز الجديد سهل التخمين',
    ChangePinResult.samePin: 'الرمز الجديد يجب أن يختلف عن الحالي',
  }.entries) {
    testWidgets('the server saying ${entry.key.name} keeps the sheet open', (
      tester,
    ) async {
      final (_, repo) = await pumpAccount(tester, owner);
      repo.changePinResult = entry.key;
      await open(tester);
      await fill(tester);
      await submit(tester);

      expect(find.byType(ChangePinSheet), findsOneWidget);
      expect(
        find.textContaining(entry.value),
        findsOneWidget,
        reason: 'the message for ${entry.key.name}',
      );
      expect(find.text('تم تغيير الرمز السري'), findsNothing);
    });
  }

  testWidgets('no connection says so and keeps what was typed', (tester) async {
    final repo = FakeAuthRepository(
      users: const [owner],
      sessionUserId: owner.id,
    );
    final bloc = AuthBloc(authRepository: repo)
      ..add(const CheckAuthSessionEvent());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AccountScreen(authRepository: _OfflinePin(repo)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await open(tester);
    await fill(tester);
    await submit(tester);

    expect(find.textContaining('تعذر الاتصال'), findsOneWidget);
    expect(find.byType(ChangePinSheet), findsOneWidget);
    final current = tester.widget<TextFormField>(
      find.byKey(const Key('pin-current')),
    );
    expect(current.controller!.text, '4829');
  });

  test('every status word the server can send maps to a result', () {
    expect(ChangePinResult.fromServer('ok'), ChangePinResult.ok);
    expect(ChangePinResult.fromServer('wrong_pin'), ChangePinResult.wrongPin);
    expect(ChangePinResult.fromServer('locked'), ChangePinResult.locked);
    expect(ChangePinResult.fromServer('weak_pin'), ChangePinResult.weakPin);
    expect(
      ChangePinResult.fromServer('invalid_pin'),
      ChangePinResult.invalidPin,
    );
    expect(ChangePinResult.fromServer('same_pin'), ChangePinResult.samePin);
    expect(
      ChangePinResult.fromServer('not_allowed'),
      ChangePinResult.notAllowed,
    );
    // Never mistaken for success.
    expect(ChangePinResult.fromServer('surprise'), ChangePinResult.notAllowed);
    expect(ChangePinResult.fromServer(null), ChangePinResult.notAllowed);
  });
}

/// Delegates everything to a fake but fails the PIN change like a dead network.
class _OfflinePin extends FakeAuthRepository {
  _OfflinePin(FakeAuthRepository inner)
    : super(users: inner.users, sessionUserId: inner.sessionUserId);

  @override
  Future<ChangePinResult> changePin({
    required String currentPin,
    required String newPin,
  }) async => throw Exception('SocketException: Failed host lookup');
}
