import 'package:raghif/features/queue/queue_controller.dart';

import 'fake_queue_repository.dart';

/// Ids of the seeded world in [FakeQueueRepository.seeded]. Named so tests
/// read as intent ("the owner's store") instead of as opaque strings.
const seededOwnerId = 'user-owner';
const seededBuyerId = 'user-buyer';
const seededStoreId = 'store-rimal';
const seededClosedStoreId = 'store-nusseirat';

/// Controller wired to an in-memory backend double.
///
/// Replaces the old `AppDatabase(NativeDatabase.memory()) +
/// QueueRepositoryImpl + ensureSeeded()` preamble: there is no local
/// repository to build any more, and nothing seeds on-device.
({FakeQueueRepository repo, QueueController controller}) buildQueueHarness({
  String actingAs = seededBuyerId,
}) {
  final repo = FakeQueueRepository.seeded()..currentUserId = actingAs;
  return (repo: repo, controller: QueueController(repo));
}
