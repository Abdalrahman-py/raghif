import 'package:equatable/equatable.dart';

enum UserRole { buyer, owner }

enum VerificationStatus { pending, verified }

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.role = UserRole.buyer,
    this.verificationStatus = VerificationStatus.pending,
  });

  /// Supabase auth user / `profiles.id` UUID.
  final String id;

  /// The sign-in name, the account's unique key and the Jawwal Pay wallet
  /// number, all in one.
  final String phone;
  final String name;
  final UserRole role;
  final VerificationStatus verificationStatus;

  bool get isOwner => role == UserRole.owner;
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    UserRole? role,
    VerificationStatus? verificationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  List<Object?> get props => [id, phone, name, role, verificationStatus];
}
