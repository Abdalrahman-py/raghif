import '../../domain/models/user_model.dart' show UserRole;
export '../../domain/models/user_model.dart' show UserRole;
export '../../core/auth/demo_accounts.dart';

/// Presentation-layer view of a logged-in user, decoupled from the domain
/// `UserModel` so screens under features/queue/ don't need to know about
/// the auth layer. Adapted from `AuthBloc`'s `Authenticated` state in
/// main.dart.
class DemoUser {
  const DemoUser({
    required this.phone,
    required this.pin,
    required this.role,
    required this.name,
    this.jawwalPayNumber,
  });

  final String phone;
  final String pin;
  final UserRole role;
  final String name;
  final String? jawwalPayNumber;
}
