import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/notifications/fcm_service.dart';
import 'package:raghif/data/receipt_store.dart';
import 'package:raghif/data/repositories/supabase_auth_repository.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show User;

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFcmService extends Mock implements FcmService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockFcmService fcm;
  late SupabaseAuthRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    fcm = MockFcmService();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.signOut()).thenAnswer((_) async {});
    repo = SupabaseAuthRepository(
      client: client,
      fcmService: fcm,
    );
  });

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
  });

  test('logout still completes when the server cannot be reached', () async {
    // signOut() talks to the server; with the backend down it throws. That
    // must not trap the user in a session they asked to leave.
    when(() => fcm.unregisterCurrentDeviceToken()).thenAnswer((_) async {});
    when(() => auth.signOut()).thenThrow(AuthException('failed to fetch'));

    await expectLater(repo.logout(), completes);
  });

  test('logout drops the saved receipt: it names the buyer', () async {
    when(() => fcm.unregisterCurrentDeviceToken()).thenAnswer((_) async {});
    await ReceiptStore().save(
      const PurchaseModel(
        id: 'p1',
        storeId: 's1',
        userId: 'u1',
        purchaseDate: '2026-10-03',
        batchNumber: 1,
        status: PurchaseStatus.waiting,
        createdAtMillis: 0,
        userName: 'أحمد',
        userNationalId: '900111222',
      ),
    );

    await repo.logout();

    expect(await ReceiptStore().load(), isNull);
  });

  group('restoreSession with no signal', () {
    const receipt = PurchaseModel(
      id: 'p1',
      storeId: 's1',
      userId: 'u1',
      purchaseDate: '2026-10-03',
      batchNumber: 1,
      status: PurchaseStatus.waiting,
      createdAtMillis: 0,
      userName: 'أحمد',
      userPhone: '0599111111',
      userNationalId: '900111222',
    );

    setUp(() {
      when(() => auth.currentUser).thenReturn(
        sb.User(
          id: 'u1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-03T00:00:00Z',
        ),
      );
      when(() => client.from('profiles'))
          .thenThrow(const SocketException('no connection'));
    });

    test('a buyer with a saved receipt still gets in, to show it', () async {
      await ReceiptStore().save(receipt);

      final user = await repo.restoreSession();

      expect(user?.id, 'u1');
      expect(user?.name, 'أحمد');
      expect(user?.nationalId, '900111222');
      expect(user?.isVerified, isTrue);
      expect(user?.role, UserRole.buyer);
    });

    test("someone else's receipt, or none, does not let anyone in", () async {
      await expectLater(repo.restoreSession(), throwsA(isA<SocketException>()));

      await ReceiptStore().save(
        const PurchaseModel(
          id: 'p2',
          storeId: 's1',
          userId: 'someone-else',
          purchaseDate: '2026-10-03',
          batchNumber: 1,
          status: PurchaseStatus.waiting,
          createdAtMillis: 0,
        ),
      );
      await expectLater(repo.restoreSession(), throwsA(isA<SocketException>()));
    });
  });
}
