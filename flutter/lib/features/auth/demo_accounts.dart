/// Presentation-layer view of a logged-in user, decoupled from the drift
/// `User` row so screens under features/queue/ don't need a database
/// dependency. AuthRepository-backed logins are adapted into this by
/// LoginScreen; see core/auth/auth_repository.dart for the real lookup.
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
