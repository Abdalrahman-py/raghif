import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/data/repositories/supabase_queue_repository.dart';
import 'package:raghif/domain/repositories/queue_repository.dart';
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
}
