import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/database/app_database.dart' hide User;
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/data/repositories/synced_queue_repository.dart';
import 'package:raghif/data/sync/queue_sync_service.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl local;
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late SyncedQueueRepository repo;

  final today = DateTime.now().toIso8601String().substring(0, 10);

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    local = QueueRepositoryImpl(db);
    await local.ensureSeeded();

    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);

    repo = SyncedQueueRepository(
      local: local,
      client: client,
      db: db,
      sync: QueueSyncService(client: client, db: db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('no Supabase session: reserveBag behaves exactly like local-only',
      () async {
    when(() => auth.currentSession).thenReturn(null);

    final stores = await local.getStores();
    final store = stores.first;

    final purchase = await repo.reserveBag(
      userId: 1,
      storeId: store.id,
      date: today,
    );

    expect(purchase.storeId, store.id);
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test(
      'session present but store not yet linked to Supabase: still falls '
      'back to local (no remote_id to call the RPC with)', () async {
    when(() => auth.currentSession).thenAnswer(
      (_) => Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: const User(
          id: 'u1',
          appMetadata: {},
          aud: 'authenticated',
          userMetadata: {},
          createdAt: '2026-01-01T00:00:00Z',
          isAnonymous: false,
        ),
      ),
    );

    final store = (await local.getStores()).first;
    final purchase = await repo.reserveBag(
      userId: 1,
      storeId: store.id,
      date: today,
    );

    expect(purchase.storeId, store.id);
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test('RPC rejects as sold out: throws StoreSoldOutException and never '
      'touches local state', () async {
    when(() => auth.currentSession).thenAnswer(
      (_) => Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: const User(
          id: 'owner-uuid',
          appMetadata: {},
          aud: 'authenticated',
          userMetadata: {},
          createdAt: '2026-01-01T00:00:00Z',
          isAnonymous: false,
        ),
      ),
    );

    final store = (await local.getStores()).first;
    await (db.update(db.stores)..where((s) => s.id.equals(store.id))).write(
      StoresCompanion(remoteId: Value('remote-store-1')),
    );

    when(() => client.rpc('reserve_bag', params: any(named: 'params')))
        .thenThrow(
      const PostgrestException(message: 'store closed or sold out'),
    );

    expect(
      () => repo.reserveBag(userId: 1, storeId: store.id, date: today),
      throwsA(isA<StoreSoldOutException>()),
    );
  });
}
