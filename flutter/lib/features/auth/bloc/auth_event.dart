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
  const LoginRequestedEvent({required this.phone, required this.pin});

  final String phone;
  final String pin;

  @override
  List<Object?> get props => [phone, pin];
}

class RegisterRequestedEvent extends AuthEvent {
  const RegisterRequestedEvent({
    required this.phone,
    required this.pin,
    required this.name,
  });

  final String phone;
  final String pin;
  final String name;

  @override
  List<Object?> get props => [phone, pin, name];
}

class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}

class UpdateProfileRequestedEvent extends AuthEvent {
  const UpdateProfileRequestedEvent({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

/// The buyer typed the code "sent" to their phone (Jawwal Pay) number.
class WalletVerificationRequestedEvent extends AuthEvent {
  const WalletVerificationRequestedEvent({required this.code});

  final String code;

  @override
  List<Object?> get props => [code];
}
