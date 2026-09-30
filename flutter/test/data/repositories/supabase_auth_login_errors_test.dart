import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/repositories/supabase_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

/// The gateway saying no is an answer; a dead connection is not. Telling them
/// apart is what keeps "not registered" and "wrong PIN" from being shown to
/// someone whose phone simply has no signal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockFunctionsClient functions;
  late SupabaseAuthRepository repo;

  void gatewayReplies(Object error) => when(
        () => functions.invoke('auth-gateway', body: any(named: 'body')),
      ).thenThrow(error);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    final client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = SupabaseAuthRepository(
      client: client,
      db: db,
      sessionStore: SessionStore(),
    );
  });

  tearDown(() async => db.close());

  test('a 401 from the gateway is a wrong PIN: null', () async {
    gatewayReplies(const FunctionException(status: 401));

    expect(
      await repo.loginWithPin(nationalId: '900111222', pin: '0000'),
      isNull,
    );
  });

  test('a 401 on the code is a wrong code: null', () async {
    gatewayReplies(const FunctionException(status: 401));

    expect(
      await repo.loginWithOtp(nationalId: '900111222', code: '0000'),
      isNull,
    );
  });

  test('a 404 asking for a code is an unknown ID: null', () async {
    gatewayReplies(const FunctionException(status: 404));

    expect(await repo.requestOtp('900999999'), isNull);
  });

  test('no connection is not a wrong PIN: it throws', () async {
    gatewayReplies(const SocketException('Failed host lookup'));

    await expectLater(
      repo.loginWithPin(nationalId: '900111222', pin: '1234'),
      throwsA(isA<SocketException>()),
    );
  });

  test('no connection is not an unknown ID either', () async {
    gatewayReplies(const SocketException('Failed host lookup'));

    await expectLater(
      repo.requestOtp('900111222'),
      throwsA(isA<SocketException>()),
    );
  });

  test('a server error is not a wrong PIN: it throws', () async {
    gatewayReplies(const FunctionException(status: 500));

    await expectLater(
      repo.loginWithPin(nationalId: '900111222', pin: '1234'),
      throwsA(isA<FunctionException>()),
    );
  });
}
