import 'package:dartz/dartz.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<Either<Failure, void>> sendActivationCode(String email);

  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String code,
  });

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Either<Failure, String>> logout();

  Future<Either<Failure, UserEntity>> getProfile({
    required String id,
  });

  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    int? gender,
    String? dateOfBirth,
    String? phoneNumber,
    String? image,
    String? storeAddress,
    String? storeDescription,
    String? banner,
  });

  Future<Either<Failure, void>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
}
