import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Prototype-grade PIN hashing (spec.md: "pin_hash is a plain hash, not
/// bcrypt"). Salts with the phone number so two users with the same PIN
/// don't share a hash; not a substitute for a real password hash (bcrypt/
/// argon2) in a production build.
String hashPin(String phone, String pin) {
  return sha256.convert(utf8.encode('$phone:$pin')).toString();
}
