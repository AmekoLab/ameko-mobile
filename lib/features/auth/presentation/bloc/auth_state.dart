import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading during auth operations.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
class AuthSuccess extends AuthState {
  final UserEntity user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Authentication or verification operation failed.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Forgot password/OTP action succeeded (not full auth).
class AuthActionSuccess extends AuthState {
  final String message;

  const AuthActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
