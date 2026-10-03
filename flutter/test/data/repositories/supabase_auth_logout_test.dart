import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/core/notifications/fcm_service.dart';
import 'package:raghif/data/repositories/supabase_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFcmService extends Mock implements FcmService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockFcmService fcm;
  late SupabaseAuthRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    fcm = MockFcmService();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.signOut()).thenAnswer((_) async {});
    repo = SupabaseAuthRepository(
      client: client,
      db: db,
      sessionStore: SessionStore(),
      fcmService: fcm,
    );
  });

  tearDown(() async => db.close());

  test('logout detaches the FCM token before the session goes away', () async {
    when(() => fcm.unregisterCurrentDeviceToken()).thenAnswer((_) async {});

    await repo.logout();

    // Order is the whole point: device_tokens RLS is `auth.uid() = user_id`,
    // so a delete issued after signOut() matches nothing and the handset
    // keeps receiving the previous user's batch pushes.
    verifyInOrder([
      () => fcm.unregisterCurrentDeviceToken(),
      () => auth.signOut(),
    ]);
  });

  test('logout still completes when token cleanup fails (offline)', () async {
    when(() => fcm.unregisterCurrentDeviceToken())
        .thenThrow(Exception('no connection'));

    await expectLater(repo.logout(), completes);

    verify(() => auth.signOut()).called(1);
    expect(await SessionStore().loadUserId(), isNull);
  });

  test('logout still completes when the server cannot be reached', () async {
    // signOut() talks to the server; with the backend down it throws. That
    // must not trap the user in a session they asked to leave.
    SharedPreferences.setMockInitialValues({'session.userId': 'user-7'});
    when(() => fcm.unregisterCurrentDeviceToken()).thenAnswer((_) async {});
    when(() => auth.signOut()).thenThrow(AuthException('failed to fetch'));

    await expectLater(repo.logout(), completes);

    expect(await SessionStore().loadUserId(), isNull);
  });

  test('logout empties the cache so the next account sees none of it',
      () async {
    when(() => fcm.unregisterCurrentDeviceToken()).thenAnswer((_) async {});
    await db.into(db.stores).insert(StoresCompanion.insert(id: 's1', name: 'مخبز'));
    await db.into(db.users).insert(UsersCompanion.insert(id: 'u1'));
    await db.into(db.purchases).insert(PurchasesCompanion.insert(
          id: 'p1',
          storeId: 's1',
          userId: 'u1',
          purchaseDate: '2026-10-03',
          status: PurchaseStatus.waiting,
          createdAt: 0,
        ));

    await repo.logout();

    for (final table in db.allTables) {
      expect(await db.select(table).get(), isEmpty, reason: table.actualTableName);
    }
  });
}
