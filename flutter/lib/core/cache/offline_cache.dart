import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/purchase_model.dart';
import '../../domain/models/store_list_entry.dart';
import '../../domain/models/store_model.dart';

/// The last things the buyer saw, kept on the phone for when the network is
/// not there: the bakery list, and the receipt (QR) of a booking, which is
/// needed at the bakery counter where signal is poor.
///
/// This is a fallback for reading, never a source of truth: it is only shown
/// when the server cannot be reached, and every write still goes to the
/// server. Every method swallows storage failures; no cache must never mean
/// no app.
class OfflineCache {
  OfflineCache([Future<SharedPreferences>? prefs])
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  static const _maxReceipts = 10;

  // ----------------------------------------------------------- store list

  Future<void> saveStoreList(
    String userId,
    List<StoreListEntry> entries,
  ) async {
    try {
      final p = await _prefs;
      await p.setString(
        'cache.stores.$userId',
        jsonEncode([for (final e in entries) entryToJson(e)]),
      );
    } catch (_) {}
  }

  Future<List<StoreListEntry>> loadStoreList(String userId) async {
    try {
      final raw = (await _prefs).getString('cache.stores.$userId');
      if (raw == null) return const [];
      return [
        for (final j in jsonDecode(raw) as List)
          entryFromJson(Map<String, dynamic>.from(j as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------- owner

  /// The bakery an owner manages, so the dashboard opens without a signal.
  Future<void> saveOwnerStore(String ownerId, StoreModel store) async {
    try {
      await (await _prefs).setString(
        'cache.ownerStore.$ownerId',
        jsonEncode(storeToJson(store)),
      );
    } catch (_) {}
  }

  Future<StoreModel?> loadOwnerStore(String ownerId) async {
    try {
      final raw = (await _prefs).getString('cache.ownerStore.$ownerId');
      if (raw == null) return null;
      return storeFromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// The last queue seen for one bakery on one day. Only the latest day per
  /// bakery is kept.
  Future<void> saveQueue(
    String storeId,
    String date,
    List<PurchaseModel> queue,
  ) async {
    try {
      await (await _prefs).setString(
        'cache.queue.$storeId',
        jsonEncode({
          'date': date,
          'queue': [for (final p in queue) purchaseToJson(p)],
        }),
      );
    } catch (_) {}
  }

  Future<List<PurchaseModel>?> loadQueue(String storeId, String date) async {
    try {
      final raw = (await _prefs).getString('cache.queue.$storeId');
      if (raw == null) return null;
      final j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (j['date'] != date) return null;
      return [
        for (final p in j['queue'] as List)
          purchaseFromJson(Map<String, dynamic>.from(p as Map)),
      ];
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------- receipts

  Future<void> savePurchase(PurchaseModel purchase) async {
    try {
      final p = await _prefs;
      await p.setString(
        'cache.purchase.${purchase.id}',
        jsonEncode(purchaseToJson(purchase)),
      );
      final ids = p.getStringList('cache.purchase.ids') ?? <String>[];
      ids
        ..remove(purchase.id)
        ..add(purchase.id);
      while (ids.length > _maxReceipts) {
        await p.remove('cache.purchase.${ids.removeAt(0)}');
      }
      await p.setStringList('cache.purchase.ids', ids);
    } catch (_) {}
  }

  Future<PurchaseModel?> loadPurchase(String id) async {
    try {
      final raw = (await _prefs).getString('cache.purchase.$id');
      if (raw == null) return null;
      return purchaseFromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  /// Forget everything (sign-out: the next person on this phone must not see
  /// the previous one's bookings).
  Future<void> clear() async {
    try {
      final p = await _prefs;
      for (final key in p.getKeys().where((k) => k.startsWith('cache.'))) {
        await p.remove(key);
      }
    } catch (_) {}
  }

  // -------------------------------------------------------- (de)serialising

  static Map<String, dynamic> storeToJson(StoreModel s) => {
    'id': s.id,
    'name': s.name,
    'isOpen': s.isOpen,
    'dailyBagLimit': s.dailyBagLimit,
    'bagsRemaining': s.bagsRemaining,
    'ownerId': s.ownerId,
    'batchSize': s.batchSize,
    'openTime': s.openTime,
    'closeTime': s.closeTime,
    'area': s.area,
    'governorate': s.governorate,
    'status': s.status,
    'bagPrice': s.bagPrice,
  };

  static StoreModel storeFromJson(Map<String, dynamic> j) => StoreModel(
    id: j['id'] as String,
    name: j['name'] as String,
    isOpen: j['isOpen'] as bool,
    dailyBagLimit: (j['dailyBagLimit'] as num).toInt(),
    bagsRemaining: (j['bagsRemaining'] as num).toInt(),
    ownerId: j['ownerId'] as String?,
    batchSize: (j['batchSize'] as num?)?.toInt() ?? 20,
    openTime: j['openTime'] as String?,
    closeTime: j['closeTime'] as String?,
    area: (j['area'] as String?) ?? '',
    governorate: j['governorate'] as String?,
    status: (j['status'] as String?) ?? StoreStatus.active,
    bagPrice: (j['bagPrice'] as num?)?.toDouble() ?? StoreModel.defaultBagPrice,
  );

  static Map<String, dynamic> entryToJson(StoreListEntry e) => {
    'store': storeToJson(e.store),
    'pinned': e.pinned,
    'todayStatus': e.todayStatus?.name,
    'todayPurchaseId': e.todayPurchaseId,
    'lastPurchaseDate': e.lastPurchaseDate,
  };

  static StoreListEntry entryFromJson(Map<String, dynamic> j) {
    final status = j['todayStatus'] as String?;
    return StoreListEntry(
      store: storeFromJson(Map<String, dynamic>.from(j['store'] as Map)),
      pinned: (j['pinned'] as bool?) ?? false,
      todayStatus: status == null
          ? null
          : PurchaseStatus.values.firstWhere((v) => v.name == status),
      todayPurchaseId: j['todayPurchaseId'] as String?,
      lastPurchaseDate: j['lastPurchaseDate'] as String?,
    );
  }

  static Map<String, dynamic> purchaseToJson(PurchaseModel p) => {
    'id': p.id,
    'storeId': p.storeId,
    'userId': p.userId,
    'purchaseDate': p.purchaseDate,
    'batchNumber': p.batchNumber,
    'status': p.status.name,
    'createdAtMillis': p.createdAtMillis,
    'userName': p.userName,
    'userPhone': p.userPhone,
    'storeName': p.storeName,
    'postponementCount': p.postponementCount,
    'paymentMethod': p.paymentMethod,
    'originalPurchaseDate': p.originalPurchaseDate,
  };

  static PurchaseModel purchaseFromJson(Map<String, dynamic> j) =>
      PurchaseModel(
        id: j['id'] as String,
        storeId: j['storeId'] as String,
        userId: j['userId'] as String,
        purchaseDate: j['purchaseDate'] as String,
        batchNumber: (j['batchNumber'] as num).toInt(),
        status: PurchaseStatus.values.firstWhere((v) => v.name == j['status']),
        createdAtMillis: (j['createdAtMillis'] as num).toInt(),
        userName: j['userName'] as String?,
        userPhone: j['userPhone'] as String?,
        storeName: j['storeName'] as String?,
        postponementCount: (j['postponementCount'] as num?)?.toInt() ?? 0,
        paymentMethod: j['paymentMethod'] as String?,
        originalPurchaseDate: j['originalPurchaseDate'] as String?,
      );
}
