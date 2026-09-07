import 'dart:convert';

/// Current wire version of the receipt QR payload.
///
/// Bump [qrPayloadVersion] whenever the JSON shape changes in a way an older
/// app cannot parse. The version key is written from day one so a future
/// decoder can tell formats apart instead of guessing; codes issued before
/// the version key existed (no `v` at all) still decode as legacy v1 — see
/// [QrPayload.tryDecode].
const int qrPayloadVersion = 1;

/// Farid's comment — PRODUCTION VERSION (keep this note; it is the roadmap
/// for whoever wires the backend, and it is deliberate, not boilerplate):
///
/// 1. REPLACE this JSON payload with an opaque, signed receipt token issued
///    by the backend. Do NOT ship signatures in this file: a key baked into
///    the app is not verifiable, and without a server a token cannot be
///    revoked anyway — fake security theater. Signature/issuer logic belongs
///    server-side, so `QrPayload` as a client-mintable type should DIE.
/// 2. DROP PII from the QR: `user_name` and `national_id` in a scannable
///    code leak the moment a receipt photo is shared. In production the code
///    should be a random reference (or signed claims the server resolves);
///    name/national ID are returned by the server AT redemption time, never
///    embedded in the code.
/// 3. REDEMPTION moves server-side: scan → POST token → atomic
///    `mark collected`. That kills the prototype's same-device limitation
///    (`notFoundHere` disappears — the owner's phone never needs to have
///    seen the purchase) and makes replay/cross-store checks authoritative.
/// 4. VALIDITY: expiry window on the token, one-time use (second scan =
///    already collected, from server truth), store binding checked on the
///    server, not from the code's own claims.
/// 5. When this lands: keep the version key mechanism, delete the
///    client-side `encode()`/`QrImageView` minting in confirmation_screen,
///    and fetch the code from the server instead.
/// ─────────────────────────────────────────────────────────────────────────
/// Encapsulates the receipt data encoded into the QR code displayed on
/// [ConfirmationScreen] and scanned on [OwnerQueueScreen].
///
/// v1 fields beyond the original four (purchase/user/store/date):
/// `v` (format version), `national_id` and `store_id` — both optional and
/// only serialized when present, so codes minted before this change still
/// decode. `store_id` lets the scanner detect a wrong-store code even when
/// the purchase is NOT in the owner's local database (prototype: no sync);
/// `national_id` binds the code to a person for pickup identity checks.
class QrPayload {
  const QrPayload({
    required this.purchaseId,
    required this.userName,
    required this.storeName,
    required this.purchaseDate,
    this.nationalId,
    this.storeId,
  });

  final String purchaseId;
  final String userName;
  final String storeName;
  final String purchaseDate;

  /// Buyer national ID (absent on codes minted pre-v1, or for users without
  /// one). Display-only in the prototype — identity VERIFICATION is a
  /// production/backend concern (see Farid's comment above).
  final String? nationalId;

  /// Store the receipt was issued for. Lets redemption report a
  /// wrong-store code from the code alone, with no local purchase needed.
  final int? storeId;

  Map<String, dynamic> toJson() => {
        'v': qrPayloadVersion,
        'purchase_id': purchaseId,
        'user_name': userName,
        'store_name': storeName,
        'purchase_date': purchaseDate,
        if (nationalId != null) 'national_id': nationalId,
        if (storeId != null) 'store_id': storeId,
      };

  String encode() => jsonEncode(toJson());

  factory QrPayload.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    if (v != null && v != qrPayloadVersion) {
      throw FormatException('Unsupported QR payload version: $v');
    }
    final storeIdRaw = json['store_id'];
    return QrPayload(
      purchaseId: json['purchase_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      purchaseDate: json['purchase_date'] as String? ?? '',
      nationalId: json['national_id'] as String?,
      storeId: storeIdRaw is num ? storeIdRaw.toInt() : null,
    );
  }

  factory QrPayload.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid QR payload format');
    }
    return QrPayload.fromJson(decoded);
  }

  static QrPayload? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (!decoded.containsKey('purchase_id') ||
          !decoded.containsKey('user_name') ||
          !decoded.containsKey('store_name') ||
          !decoded.containsKey('purchase_date')) {
        return null;
      }
      return QrPayload.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrPayload &&
          runtimeType == other.runtimeType &&
          purchaseId == other.purchaseId &&
          userName == other.userName &&
          storeName == other.storeName &&
          purchaseDate == other.purchaseDate &&
          nationalId == other.nationalId &&
          storeId == other.storeId;

  @override
  int get hashCode => Object.hash(
        purchaseId,
        userName,
        storeName,
        purchaseDate,
        nationalId,
        storeId,
      );

  @override
  String toString() =>
      'QrPayload(purchaseId: $purchaseId, userName: $userName, '
      'storeName: $storeName, purchaseDate: $purchaseDate, '
      'nationalId: $nationalId, storeId: $storeId)';
}
