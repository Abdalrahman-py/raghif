import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';
import 'package:raghif/features/auth/registration_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionStore extends Mock implements SessionStore {}

void main() {
  late AuthBloc bloc;

  setUp(() {
    bloc = AuthBloc(
      authRepository: MockAuthRepository(),
      sessionStore: MockSessionStore(),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(home: RegistrationScreen()),
      ),
    );
  }

  TextField phoneField(WidgetTester tester) => tester.widget<TextField>(
        find.widgetWithText(TextField, Strings.phoneLabel),
      );

  TextField jawwalField(WidgetTester tester) => tester.widget<TextField>(
        find.widgetWithText(TextField, Strings.jawwalPayNumberLabel),
      );

  testWidgets('Jawwal Pay number mirrors the phone number as it is typed',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, Strings.phoneLabel),
      '0599111111',
    );
    await tester.pump();

    expect(jawwalField(tester).controller!.text, '0599111111');
    expect(phoneField(tester).controller!.text, '0599111111');
  });

  testWidgets('updates the default when the phone number changes',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, Strings.phoneLabel),
      '0599111111',
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, Strings.phoneLabel),
      '0599222222',
    );
    await tester.pump();

    expect(jawwalField(tester).controller!.text, '0599222222');
  });

  testWidgets('a manually entered wallet number is not overwritten',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, Strings.phoneLabel),
      '0599111111',
    );
    await tester.pump();
    // User's wallet number differs from their SIM number.
    await tester.enterText(
      find.widgetWithText(TextField, Strings.jawwalPayNumberLabel),
      '0599888888',
    );
    await tester.pump();
    // Later phone edits must leave the manual wallet number alone.
    await tester.enterText(
      find.widgetWithText(TextField, Strings.phoneLabel),
      '0599333333',
    );
    await tester.pump();

    expect(jawwalField(tester).controller!.text, '0599888888');
  });

  testWidgets('clearing the wallet field restores the phone default',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, Strings.phoneLabel),
      '0599111111',
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, Strings.jawwalPayNumberLabel),
      '0599888888',
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, Strings.jawwalPayNumberLabel),
      '',
    );
    await tester.pump();

    expect(jawwalField(tester).controller!.text, '0599111111');
  });
}
