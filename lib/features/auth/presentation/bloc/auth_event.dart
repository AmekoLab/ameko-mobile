import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app start to check if user is already authenticated.
class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Fired when user submits login form.
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Fired when user submits the registration form.
class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

/// Fired when user requests a password reset.
class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Fired when user submits OTP code.
class VerifyOtpRequested extends AuthEvent {
  final String otp;

  const VerifyOtpRequested({required this.otp});

  @override
  List<Object?> get props => [otp];
}

/// Fired when user submits reset password form.
class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, code, newPassword, confirmPassword];
}

/// Fired when user logs out.
class LoggedOut extends AuthEvent {
  const LoggedOut();
}

/// Fired to refresh user data from API.
class ProfileFetchRequested extends AuthEvent {
  const ProfileFetchRequested();
}
