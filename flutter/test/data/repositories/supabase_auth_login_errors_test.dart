import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/data/repositories/supabase_auth_repository.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

/// The gateway saying no is an answer; a dead connection is not. Telling them
/// apart is what keeps "not registered" and "wrong PIN" from being shown to
/// someone whose phone simply has no signal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFunctionsClient functions;
  late SupabaseAuthRepository repo;

  void gatewayReplies(Object error) => when(
    () => functions.invoke('auth-gateway', body: any(named: 'body')),
  ).thenThrow(error);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = SupabaseAuthRepository(client: client);
  });

  test('a 401 from the gateway is a wrong PIN: null', () async {
    gatewayReplies(const FunctionException(status: 401));

    expect(await repo.login(phone: '0599111111', pin: '0000'), isNull);
  });

  test('no connection is not a wrong PIN: it throws', () async {
    gatewayReplies(const SocketException('Failed host lookup'));

    await expectLater(
      repo.login(phone: '0599111111', pin: '1234'),
      throwsA(isA<SocketException>()),
    );
  });

  test('a 403 with a block reason is an AccountBlockedException', () async {
    for (final reason in ['account_disabled', 'store_archived']) {
      gatewayReplies(
        FunctionException(status: 403, details: {'error': reason}),
      );
      await expectLater(
        repo.login(phone: '0599111111', pin: '1234'),
        throwsA(
          isA<AccountBlockedException>().having(
            (e) => e.reason,
            'reason',
            reason,
          ),
        ),
      );
    }
  });

  test('a 429 is a sign-in lock, not a wrong PIN or a failure', () async {
    gatewayReplies(
      const FunctionException(
        status: 429,
        details: {'error': 'login_locked', 'retryAfter': 900},
      ),
    );
    await expectLater(
      repo.login(phone: '0599111111', pin: '1234'),
      throwsA(
        isA<AccountBlockedException>().having(
          (e) => e.reason,
          'reason',
          'login_locked',
        ),
      ),
    );
  });

  test('any other 403 stays an error', () async {
    gatewayReplies(
      const FunctionException(
        status: 403,
        details: {'error': 'seeding is disabled'},
      ),
    );
    await expectLater(
      repo.login(phone: '0599111111', pin: '1234'),
      throwsA(isA<FunctionException>()),
    );
  });

  test('a server error is not a wrong PIN: it throws', () async {
    gatewayReplies(const FunctionException(status: 500));

    await expectLater(
      repo.login(phone: '0599111111', pin: '1234'),
      throwsA(isA<FunctionException>()),
    );
  });
}
