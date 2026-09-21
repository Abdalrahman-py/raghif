import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('session persists a user id across store instances', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await SessionStore().loadUserId(), isNull);

    await SessionStore().saveUserId('user-7');
    expect(await SessionStore().loadUserId(), 'user-7');

    await SessionStore().clear();
    expect(await SessionStore().loadUserId(), isNull);
  });
}
