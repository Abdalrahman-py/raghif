/// Seed accounts mirroring app/.../data/AppDatabase.kt's DEMO_* constants.
/// Presentation-only for this slice — replaced by real Supabase auth in a
/// follow-up (see spec.md's backend section).
enum UserRole { buyer, owner }

class DemoUser {
  const DemoUser({
    required this.phone,
    required this.pin,
    required this.role,
    required this.name,
  });

  final String phone;
  final String pin;
  final UserRole role;
  final String name;
}

const demoBuyerPhone = '0599111111';
const demoBuyerPin = '1234';
const demoOwnerPhone = '0599222222';
const demoOwnerPin = '1234';

const demoUsers = [
  DemoUser(
    phone: demoBuyerPhone,
    pin: demoBuyerPin,
    role: UserRole.buyer,
    name: 'أحمد ناصر',
  ),
  DemoUser(
    phone: demoOwnerPhone,
    pin: demoOwnerPin,
    role: UserRole.owner,
    name: 'صاحب المخبز',
  ),
];

DemoUser? findByPhoneAndPin(String phone, String pin) {
  for (final user in demoUsers) {
    if (user.phone == phone && user.pin == pin) return user;
  }
  return null;
}

bool phoneExists(String phone) => demoUsers.any((u) => u.phone == phone);

/// Returns an error string when registration fields are invalid, null when OK.
/// Mirrors app/.../data/Registration.kt's validateRegistration.
String? validateRegistration({
  required String phone,
  required String pin,
  required String personalId,
  required String name,
}) {
  if (phone.trim().isEmpty ||
      pin.length != 4 ||
      personalId.trim().isEmpty ||
      name.trim().isEmpty) {
    return 'يرجى تعبئة جميع الحقول';
  }
  return null;
}
