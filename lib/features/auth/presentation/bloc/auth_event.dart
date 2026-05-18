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

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

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

/// Fired when user submits the registration form.
class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  const RegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  @override
  List<Object?> get props => [username, email, password, firstName, lastName];
}

class SendOtpRequested extends AuthEvent {
  final String email;
  const SendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String code;

  const VerifyOtpRequested({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

class UpdateProfileRequested extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final int? gender;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? image;
  final String? storeAddress;
  final String? storeDescription;
  final String? banner;

  const UpdateProfileRequested({
    this.firstName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.image,
    this.storeAddress,
    this.storeDescription,
    this.banner,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        gender,
        dateOfBirth,
        phoneNumber,
        image,
        storeAddress,
        storeDescription,
        banner,
      ];
}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmNewPassword;

  const ChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword, confirmNewPassword];
}

class LoggedOut extends AuthEvent {
  const LoggedOut();
}

class ProfileFetchRequested extends AuthEvent {
  const ProfileFetchRequested();
}
