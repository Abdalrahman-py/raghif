import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghif/core/auth/demo_accounts.dart';
import 'package:raghif/core/database/app_database.dart';
import 'package:raghif/data/repositories/queue_repository_impl.dart';
import 'package:raghif/features/queue/queue_logic.dart';

void main() {
  late AppDatabase db;
  late QueueRepositoryImpl repo;
  late int buyerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = QueueRepositoryImpl(db);
    await repo.ensureSeeded();
    final buyer = await (db.select(db.users)
          ..where((u) => u.nationalId.equals(demoBuyerNationalId)))
        .getSingle();
    buyerId = buyer.id;
  });

  tearDown(() async {
    await db.close();
  });

  test('starts with an empty audit trail', () async {
    final store = (await repo.getStores()).first;

    expect(await repo.getScansForStore(store.id), isEmpty);
  });

  test('records a checked-in scan with who, what and when', () async {
    final store = (await repo.getStores()).first;
    final purchase = await repo.reserveBag(
      userId: buyerId,
      storeId: store.id,
      date: todayDateString(),
    );

    await repo.recordScan(
      storeId: store.id,
      outcome: 'checkedIn',
      purchaseId: purchase.id,
      scannedName: 'أحمد ناصر',
      scannedNationalId: demoBuyerNationalId,
    );

    final scans = await repo.getScansForStore(store.id);
    expect(scans, hasLength(1));
    final scan = scans.single;
    expect(scan.storeId, store.id);
    expect(scan.purchaseId, purchase.id);
    expect(scan.outcome, 'checkedIn');
    expect(scan.scannedName, 'أحمد ناصر');
    expect(scan.scannedNationalId, demoBuyerNationalId);
    expect(scan.isCheckedIn, isTrue);
    expect(scan.scannedAtMillis, greaterThan(0));
  });

  test('records a failed scan without a purchase link', () async {
    final store = (await repo.getStores()).first;

    await repo.recordScan(
      storeId: store.id,
      outcome: 'notFoundHere',
      scannedName: 'مجهول',
    );

    final scan = (await repo.getScansForStore(store.id)).single;
    expect(scan.purchaseId, null);
    expect(scan.outcome, 'notFoundHere');
    expect(scan.isCheckedIn, isFalse);
  });

  test('an unparseable code is logged as invalidCode', () async {
    final store = (await repo.getStores()).first;

    await repo.recordScan(storeId: store.id, outcome: 'invalidCode');

    final scan = (await repo.getScansForStore(store.id)).single;
    expect(scan.outcome, 'invalidCode');
    expect(scan.purchaseId, null);
    expect(scan.scannedName, null);
  });

  test('history is newest first and limited', () async {
    final store = (await repo.getStores()).first;

    await repo.recordScan(storeId: store.id, outcome: 'wrongStore');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.recordScan(storeId: store.id, outcome: 'checkedIn');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.recordScan(storeId: store.id, outcome: 'alreadyCollected');

    final scans = await repo.getScansForStore(store.id);
    expect(
      scans.map((s) => s.outcome).toList(),
      ['alreadyCollected', 'checkedIn', 'wrongStore'],
    );

    final limited = await repo.getScansForStore(store.id, limit: 2);
    expect(limited, hasLength(2));
    expect(limited.first.outcome, 'alreadyCollected');
  });

  test('scans are scoped to their store', () async {
    final stores = await repo.getStores();

    await repo.recordScan(storeId: stores[0].id, outcome: 'checkedIn');
    await repo.recordScan(storeId: stores[1].id, outcome: 'wrongStore');

    expect(await repo.getScansForStore(stores[0].id), hasLength(1));
    expect(
      (await repo.getScansForStore(stores[0].id)).single.outcome,
      'checkedIn',
    );
  });
}
