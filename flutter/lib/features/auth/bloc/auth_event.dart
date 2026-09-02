import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthSessionEvent extends AuthEvent {
  const CheckAuthSessionEvent();
}

class LoginRequestedEvent extends AuthEvent {
  const LoginRequestedEvent({
    required this.phone,
    required this.pin,
  });

  final String phone;
  final String pin;

  @override
  List<Object?> get props => [phone, pin];
}

class RegisterRequestedEvent extends AuthEvent {
  const RegisterRequestedEvent({
    required this.phone,
    required this.pin,
    required this.nationalId,
    required this.name,
    this.jawwalPayNumber,
  });

  final String phone;
  final String pin;
  final String nationalId;
  final String name;
  final String? jawwalPayNumber;

  @override
  List<Object?> get props => [phone, pin, nationalId, name, jawwalPayNumber];
}

class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}

/// Mock verification approval — see WaitingForVerificationScreen. Real
/// ID/face-match is out of scope for this prototype.
class VerificationApprovedEvent extends AuthEvent {
  const VerificationApprovedEvent();
}
