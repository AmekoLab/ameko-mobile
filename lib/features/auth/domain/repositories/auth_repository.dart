import 'package:dartz/dartz.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, String>> forgotPassword({required String email});

  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Either<Failure, void>> verifyOtp({required String otp});

  Future<Either<Failure, String>> logout();

  Future<Either<Failure, UserEntity>> getProfile({
    required String id,
    required String token,
  });
}
