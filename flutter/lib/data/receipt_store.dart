import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/purchase_model.dart';

/// The signed-in buyer's receipts, kept on the phone so the pickup QR still
/// opens with no signal at the bakery.
///
/// A buyer can hold a today booking and a postponed tomorrow booking at the
/// same time, so receipts are kept per purchase id, newest last. Everything
/// else comes from Supabase on demand. This is written only from a server
/// answer and read only when the server cannot be reached.
class ReceiptStore {
  static const _key = 'receipt.all';

  /// Where a single receipt lived before receipts were kept per id.
  static const _legacyKey = 'receipt.latest';

  /// Today plus tomorrow, with room for a stale entry or two.
  static const _max = 4;

  Future<void> _pending = Future.value();

  /// Writes run one after another, so two saves never drop each other.
  Future<void> _serial(Future<void> Function() write) {
    final next = _pending.catchError((Object _) {}).then((_) => write());
    _pending = next;
    return next;
  }

  Future<void> save(PurchaseModel p) => _serial(() async {
    final all = await loadAll();
    final previous = all.where((r) => r.id == p.id).firstOrNull;
    // An older in-flight read must not overwrite a moved receipt.
    if (previous != null && previous.postponementCount > p.postponementCount) {
      return;
    }
    all
      ..removeWhere((r) => r.id == p.id)
      ..add(p);
    while (all.length > _max) {
      all.removeAt(0);
    }
    await _write(all);
  });

  /// Forgets the receipts [drop] selects.
  Future<void> removeWhere(bool Function(PurchaseModel) drop) =>
      _serial(() async => _write((await loadAll())..removeWhere(drop)));

  /// The most recently saved receipt (startup without signal needs one).
  Future<PurchaseModel?> load() async => (await loadAll()).lastOrNull;

  Future<PurchaseModel?> loadById(String id) async =>
      (await loadAll()).where((r) => r.id == id).firstOrNull;

  Future<List<PurchaseModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    try {
      if (raw != null) {
        return [
          for (final j in jsonDecode(raw) as List)
            _fromJson(Map<String, dynamic>.from(j as Map)),
        ];
      }
      final legacy = prefs.getString(_legacyKey);
      if (legacy == null) return [];
      return [_fromJson(jsonDecode(legacy) as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() => _serial(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_legacyKey);
  });

  Future<void> _write(List<PurchaseModel> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final p in all) _toJson(p)]));
    await prefs.remove(_legacyKey);
  }

  static Map<String, dynamic> _toJson(PurchaseModel p) => {
    'id': p.id,
    'storeId': p.storeId,
    'userId': p.userId,
    'purchaseDate': p.purchaseDate,
    'batchNumber': p.batchNumber,
    'status': p.status.name,
    'createdAt': p.createdAtMillis,
    'userName': p.userName,
    'userPhone': p.userPhone,
    'storeName': p.storeName,
    'postponementCount': p.postponementCount,
    'paymentMethod': p.paymentMethod,
    'originalPurchaseDate': p.originalPurchaseDate,
  };

  static PurchaseModel _fromJson(Map<String, dynamic> j) => PurchaseModel(
    id: j['id'] as String,
    storeId: j['storeId'] as String,
    userId: j['userId'] as String,
    purchaseDate: j['purchaseDate'] as String,
    batchNumber: j['batchNumber'] as int,
    status: PurchaseStatus.values.byName(j['status'] as String),
    createdAtMillis: j['createdAt'] as int,
    userName: j['userName'] as String?,
    userPhone: j['userPhone'] as String?,
    storeName: j['storeName'] as String?,
    postponementCount: (j['postponementCount'] as int?) ?? 0,
    paymentMethod: j['paymentMethod'] as String?,
    originalPurchaseDate: j['originalPurchaseDate'] as String?,
  );
}
