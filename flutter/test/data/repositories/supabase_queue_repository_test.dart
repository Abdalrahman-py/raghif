import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/data/receipt_store.dart';
import 'package:raghif/data/repositories/supabase_queue_repository.dart';
import 'package:raghif/domain/models/purchase_model.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapRpcError', () {
    test('the sold-out message becomes StoreSoldOutException', () {
      final error = SupabaseQueueRepository.mapRpcError(
        const PostgrestException(
          message: SupabaseQueueRepository.soldOutMessage,
        ),
      );

      expect(error, isA<StoreSoldOutException>());
    });

    test('any other server error is a failed write, never a raw driver error',
        () {
      for (final message in [
        'already reserved a bag today',
        'not the store owner',
        'batch not notified yet',
        'permission denied for table profiles',
      ]) {
        final error = SupabaseQueueRepository.mapRpcError(
          PostgrestException(message: message),
        );

        expect(error, isA<BackendUnavailableException>(), reason: message);
      }
    });

    test('"closed" inside another message is not mistaken for sold out', () {
      final error = SupabaseQueueRepository.mapRpcError(
        const PostgrestException(message: 'connection closed unexpectedly'),
      );

      expect(error, isA<BackendUnavailableException>());
    });
  });

  // A real SupabaseClient against a local HTTP server standing in for
  // PostgREST: every GET answers with [serverRows], or fails while [down].
  // The failure is a 400 because the client retries 5xx and socket errors
  // with backoff (~7s); the repository falls back on any failure alike.
  group('reads come from the server; the receipt is the offline fallback', () {
    late HttpServer server;
    late SupabaseClient client;
    late SupabaseQueueRepository repo;
    var serverRows = <Map<String, dynamic>>[];
    var down = false;

    Map<String, dynamic> row({String date = '2026-10-03'}) => {
          'id': 'p1',
          'store_id': 's1',
          'user_id': 'u1',
          'purchase_date': date,
          'batch_number': 2,
          'status': 'notified',
          'created_at': '2026-10-03T10:00:00Z',
          'profiles': {
            'name': 'أحمد',
            'phone': '0599111111',
            'national_id': '900111222',
          },
          'stores': {'name': 'مخبز الرمال'},
        };

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      down = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) {
        if (down) {
          req.response
            ..statusCode = HttpStatus.badRequest
            ..close();
          return;
        }
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(serverRows))
          ..close();
      });
      client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon');
      repo = SupabaseQueueRepository(client: client);
    });

    tearDown(() async {
      await server.close(force: true);
      await client.dispose();
    });

    test("today's order comes from the server, names included, and is saved",
        () async {
      serverRows = [row()];

      final order = await repo.getBlockingPurchase('u1', '2026-10-03');

      expect(order?.batchNumber, 2);
      expect(order?.status, PurchaseStatus.notified);
      expect(order?.userName, 'أحمد');
      expect(order?.userNationalId, '900111222');
      expect(order?.storeName, 'مخبز الرمال');
      expect(await ReceiptStore().load(), order);
    });

    test('no signal: the saved receipt stands in, for that buyer and day only',
        () async {
      serverRows = [row()];
      final online = await repo.getBlockingPurchase('u1', '2026-10-03');
      down = true;

      expect(await repo.getBlockingPurchase('u1', '2026-10-03'), online);
      expect(await repo.getPurchaseById('p1'), online);
      expect(
        () => repo.getBlockingPurchase('u1', '2026-10-04'),
        throwsA(isA<BackendUnavailableException>()),
      );
      expect(
        () => repo.getBlockingPurchase('someone-else', '2026-10-03'),
        throwsA(isA<BackendUnavailableException>()),
      );
    });

    test('an order gone from the server is gone from the phone too', () async {
      serverRows = [row()];
      await repo.getBlockingPurchase('u1', '2026-10-03');

      serverRows = [];
      expect(await repo.getBlockingPurchase('u1', '2026-10-03'), isNull);
      expect(await ReceiptStore().load(), isNull);
    });

    test('other reads have no fallback: no server, no data', () async {
      down = true;

      expect(repo.getStores(), throwsA(isA<BackendUnavailableException>()));
      expect(
        repo.getQueueForStore('s1', '2026-10-03'),
        throwsA(isA<BackendUnavailableException>()),
      );
    });
  });
}
