import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/sync/queue_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A real SupabaseClient against a local HTTP server that answers
/// `GET /rest/v1/purchases` with whatever [serverRows] holds.
void main() {
  late HttpServer server;
  late AppDatabase db;
  late QueueSyncService sync;
  var serverRows = <Map<String, dynamic>>[];

  Map<String, dynamic> row(String id) => {
    'id': id,
    'store_id': 's1',
    'user_id': 'u1',
    'purchase_date': '2026-10-03',
    'batch_number': 1,
    'status': 'waiting',
    'created_at': '2026-10-03T10:00:00Z',
  };

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(serverRows))
        ..close();
    });
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.stores)
        .insert(StoresCompanion.insert(id: 's1', name: 'مخبز'));
    await db
        .into(db.users)
        .insert(UsersCompanion.insert(id: 'u1', name: const Value('أحمد')));
    sync = QueueSyncService(
      client: SupabaseClient('http://localhost:${server.port}', 'anon'),
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
    await server.close(force: true);
  });

  test('a purchase deleted on the server leaves the cache too', () async {
    serverRows = [row('p1'), row('p2')..['purchase_date'] = '2026-10-02'];
    await sync.pullPurchases();
    expect((await db.select(db.purchases).get()).map((p) => p.id), [
      'p1',
      'p2',
    ]);

    serverRows = [row('p2')..['purchase_date'] = '2026-10-02'];
    await sync.pullPurchases();
    final left = await db.select(db.purchases).get();
    expect(left.map((p) => p.id), ['p2']);
    expect(left.single.status, PurchaseStatus.waiting);
  });
}
