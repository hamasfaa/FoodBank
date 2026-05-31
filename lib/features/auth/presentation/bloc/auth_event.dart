import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String role;

  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [fullName, email, phoneNumber, password, role];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class CompleteProfileSubmitted extends AuthEvent {
  final String fullName;
  final String phoneNumber;
  final String role;

  const CompleteProfileSubmitted({
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });

  @override
  List<Object?> get props => [fullName, phoneNumber, role];
}

class RoleSelected extends AuthEvent {
  final String role;
  const RoleSelected(this.role);

  @override
  List<Object?> get props => [role];
}

class PasswordVisibilityToggled extends AuthEvent {
  const PasswordVisibilityToggled();
}

class ConfirmPasswordVisibilityToggled extends AuthEvent {
  const ConfirmPasswordVisibilityToggled();
}
