import 'package:equatable/equatable.dart';

enum UserRole { buyer, owner }

enum VerificationStatus { pending, verified }

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.phone,
    required this.nationalId,
    required this.name,
    this.role = UserRole.buyer,
    this.jawwalPayNumber,
    this.verificationStatus = VerificationStatus.pending,
  });

  /// Supabase auth user / `profiles.id` UUID.
  final String id;
  final String phone;
  final String nationalId;
  final String name;
  final UserRole role;
  final String? jawwalPayNumber;
  final VerificationStatus verificationStatus;

  bool get isOwner => role == UserRole.owner;
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  UserModel copyWith({
    String? id,
    String? phone,
    String? nationalId,
    String? name,
    UserRole? role,
    String? jawwalPayNumber,
    VerificationStatus? verificationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      name: name ?? this.name,
      role: role ?? this.role,
      jawwalPayNumber: jawwalPayNumber ?? this.jawwalPayNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        nationalId,
        name,
        role,
        jawwalPayNumber,
        verificationStatus,
      ];
}
