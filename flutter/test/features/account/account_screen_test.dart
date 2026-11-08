import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/features/account/account_screen.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';

import '../../support/fake_auth_repository.dart';

class _FailingProfileRepository extends FakeAuthRepository {
  _FailingProfileRepository(UserModel user)
    : super(users: [user], sessionUserId: user.id);

  @override
  Future<UserModel> updateProfile({required String name}) async =>
      throw Exception('offline');
}

class _PendingProfileRepository extends FakeAuthRepository {
  _PendingProfileRepository(UserModel user)
    : super(users: [user], sessionUserId: user.id);

  final pending = Completer<UserModel>();

  @override
  Future<UserModel> updateProfile({required String name}) => pending.future;
}

void main() {
  const user = UserModel(
    id: 'account-a',
    phone: '0599111111',
    name: 'أحمد ناصر',
  );
  testWidgets(
    'drag cannot dismiss pending save or lose edits after delayed failure',
    (tester) async {
      final repository = _PendingProfileRepository(user);
      final bloc = AuthBloc(authRepository: repository);
      addTearDown(bloc.close);
      bloc.add(const CheckAuthSessionEvent());
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تعديل البيانات'));
      await tester.tap(find.text('تعديل البيانات'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile-name')),
        'اسم محفوظ للمحاولة',
      );
      await tester.ensureVisible(find.text('حفظ التغييرات'));
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pump();
      expect((bloc.state as Authenticated).profileSaving, isTrue);
      final sheetTop = tester.getTopLeft(find.byType(BottomSheet));
      await tester.dragFrom(
        sheetTop + const Offset(100, 3),
        const Offset(0, 700),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      repository.pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('اسم محفوظ للمحاولة'), findsOneWidget);
      expect(
        find.text('تعذر حفظ البيانات. تحقق من الاتصال وحاول مجدداً.'),
        findsOneWidget,
      );
      expect(bloc.state, isA<Authenticated>());
    },
  );
  testWidgets('saving valid edits updates account and closes editor', (
    tester,
  ) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(users: [user], sessionUserId: user.id),
    );
    addTearDown(bloc.close);
    bloc.add(const CheckAuthSessionEvent());
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: ThemeData(
            bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
          ),
          home: const AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تعديل البيانات'));
    await tester.tap(find.text('تعديل البيانات'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-name')), 'اسم جديد');
    // The phone is support-only: the field is there but cannot be edited.
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('profile-phone')))
          .enabled,
      isFalse,
    );
    expect(find.byKey(const Key('phone-support-note')), findsOneWidget);
    await tester.ensureVisible(find.text('حفظ التغييرات'));
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('اسم جديد'), findsOneWidget);
    expect(find.text('0599111111'), findsWidgets);
  });
  testWidgets(
    'account displays signed-in data and validates edits without changing identity',
    (tester) async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(
          users: [user],
          sessionUserId: user.id,
        ),
      );
      addTearDown(bloc.close);
      bloc.add(const CheckAuthSessionEvent());
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('أحمد ناصر'), findsOneWidget);
      expect(find.text('0599111111'), findsOneWidget);
      await tester.ensureVisible(find.text('تعديل البيانات'));
      await tester.tap(find.text('تعديل البيانات'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.enterText(find.byKey(const Key('profile-name')), '');
      await tester.ensureVisible(find.text('حفظ التغييرات'));
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل الاسم'), findsOneWidget);
      expect((bloc.state as Authenticated).user, user);
    },
  );

  testWidgets('failed save keeps edit sheet and entered values for retry', (
    tester,
  ) async {
    final bloc = AuthBloc(authRepository: _FailingProfileRepository(user));
    addTearDown(bloc.close);
    bloc.add(const CheckAuthSessionEvent());
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تعديل البيانات'));
    await tester.tap(find.text('تعديل البيانات'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-name')), 'اسم جديد');
    await tester.ensureVisible(find.text('حفظ التغييرات'));
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pumpAndSettle();
    expect(find.text('اسم جديد'), findsOneWidget);
    expect(
      find.text('تعذر حفظ البيانات. تحقق من الاتصال وحاول مجدداً.'),
      findsOneWidget,
    );
    expect(bloc.state, isA<Authenticated>());
  });

  testWidgets(
    'privacy, terms and delete-account live in the three-dots menu, not the page',
    (tester) async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(
          users: const [user],
          sessionUserId: 'account-a',
        ),
      );
      addTearDown(bloc.close);
      bloc.add(const CheckAuthSessionEvent());
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.privacyTitle), findsNothing);
      expect(find.text(Strings.termsTitle), findsNothing);
      expect(find.text(Strings.deleteAccountTitle), findsNothing);

      await tester.tap(find.byKey(const Key('account-menu')));
      await tester.pumpAndSettle();
      expect(find.text(Strings.privacyTitle), findsOneWidget);
      expect(find.text(Strings.termsTitle), findsOneWidget);
      expect(find.text(Strings.deleteAccountTitle), findsOneWidget);

      await tester.tap(find.text(Strings.deleteAccountTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(Strings.contactSupportWhatsapp),
        ),
        findsOneWidget,
      );
    },
  );
}
