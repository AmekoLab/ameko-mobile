import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/core/services/storage_service.dart';
import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/auth/domain/entities/user_entity.dart';
import 'package:ameko_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ameko_app/features/auth/data/models/user_model.dart';
import 'package:ameko_app/features/auth/data/models/auth_response_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final StorageService _storage;
  final Dio _dio;

  AuthRepositoryImpl(this._storage, this._dio);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      appLogger.d('Login attempt: email=$email');

      final response = await _dio.post(
        '/api/v1/Users/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final loginResponse = LoginResponseModel.fromJson(response.data);

      if (loginResponse.success && loginResponse.data != null) {
        final data = loginResponse.data!;

        // 1. Save tokens
        await _storage.saveToken(data.token);
        await _storage.saveRefreshToken(data.refreshToken);

        // 2. Map and save initial user data (with role)
        final initialUser = data.toUserModel();
        await _storage.saveUser(initialUser.toJson());

        // 3. Supplement with full profile (optional but recommended)
        try {
          final profileResult = await getProfile(id: data.id);
          return profileResult.fold(
            (failure) => Right(initialUser), // Fallback to login data if profile fetch fails
            (profileUser) async {
              // Merge: Use profile data but keep role from login if profile role is null
              final mergedUser = UserModel(
                id: profileUser.id,
                username: profileUser.username,
                email: profileUser.email,
                fullName: profileUser.fullName ?? initialUser.fullName,
                role: profileUser.role ?? initialUser.role,
                token: profileUser.token ?? initialUser.token,
              );
              await _storage.saveUser(mergedUser.toJson());
              return Right(mergedUser);
            },
          );
        } catch (e) {
          appLogger.w('Failed to fetch full profile, using login data', error: e);
          return Right(initialUser);
        }
      } else {
        return Left(ValidationFailure(message: loginResponse.message));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('Unexpected error during login', error: e);
      return Left(UnknownFailure(
        message: 'Ứng dụng gặp sự cố. Vui lòng thử lại sau. (Code: ${e.runtimeType})',
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/Users/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      final apiResponse = ProfileResponseModel.fromJson(response.data);
      if (apiResponse.success && apiResponse.data != null) {
        return Right(apiResponse.data!);
      } else {
        return Left(ValidationFailure(message: apiResponse.message));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendActivationCode(String email) async {
    try {
      final response = await _dio.post(
        '/api/v1/Users/send-activation-code',
        data: email, // Payload is just the string email as per guide
      );
      if (response.data['success'] == true) {
        return const Right(null);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Failed to send activation code'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/Users/verify-activation-code',
        data: {
          'email': email,
          'code': code,
        },
      );
      if (response.data['success'] == true) {
        return const Right(null);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Invalid OTP code'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/api/v1/Users/forgot-password',
        data: {'email': email},
      );
      if (response.data['success'] == true) {
        return const Right(null);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Failed to send reset link'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/Users/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      if (response.data['success'] == true) {
        return const Right(null);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Failed to reset password'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getProfile({required String id}) async {
    try {
      final response = await _dio.get(
        id.isEmpty ? '/api/v1/Users/profile' : '/api/v1/Users/profile/$id',
      );

      final profileResponse = ProfileResponseModel.fromJson(response.data);

      if (profileResponse.success && profileResponse.data != null) {
        final profileUser = profileResponse.data!;
        final cachedUserJson = _storage.getUser();
        final cachedUser = cachedUserJson != null ? UserEntity.fromJson(cachedUserJson) : null;

        final mergedUser = UserModel(
          id: profileUser.id.isNotEmpty ? profileUser.id : id,
          username: profileUser.username.isNotEmpty ? profileUser.username : (cachedUser?.username ?? ''),
          email: profileUser.email.isNotEmpty ? profileUser.email : (cachedUser?.email ?? ''),
          fullName: profileUser.fullName ?? cachedUser?.fullName,
          firstName: profileUser.firstName ?? cachedUser?.firstName,
          lastName: profileUser.lastName ?? cachedUser?.lastName,
          role: (profileUser.role != null && profileUser.role!.isNotEmpty) 
              ? profileUser.role 
              : cachedUser?.role,
          token: profileUser.token ?? cachedUser?.token,
          gender: profileUser.gender ?? cachedUser?.gender,
          dateOfBirth: profileUser.dateOfBirth ?? cachedUser?.dateOfBirth,
          phoneNumber: profileUser.phoneNumber ?? cachedUser?.phoneNumber,
          image: profileUser.image ?? cachedUser?.image,
          storeAddress: profileUser.storeAddress ?? cachedUser?.storeAddress,
          storeDescription: profileUser.storeDescription ?? cachedUser?.storeDescription,
          banner: profileUser.banner ?? cachedUser?.banner,
        );

        await _storage.saveUser(mergedUser.toJson());
        return Right(mergedUser);
      } else {
        return Left(ServerFailure(message: profileResponse.message));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
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
  }) async {
    try {
      final response = await _dio.put(
        userId.isEmpty ? '/api/v1/Users/profile' : '/api/v1/Users/profile/$userId',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (image != null) 'image': image,
          if (storeAddress != null) 'storeAddress': storeAddress,
          if (storeDescription != null) 'storeDescription': storeDescription,
          if (banner != null) 'banner': banner,
        },
      );

      final apiResponse = ProfileResponseModel.fromJson(response.data);
      if (apiResponse.success && apiResponse.data != null) {
        await _storage.saveUser(apiResponse.data!.toJson());
        return Right(apiResponse.data!);
      } else {
        return Left(ServerFailure(message: apiResponse.message));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _dio.post(
        userId.isEmpty ? '/api/v1/Users/change-password' : '/api/v1/Users/change-password/$userId',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );
      if (response.data['success'] == true) {
        return const Right(null);
      } else {
        return Left(ServerFailure(message: response.data['message'] ?? 'Failed to change password'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, String>> logout() async {
    String message = 'Đã đăng xuất khỏi thiết bị.';
    try {
      final user = _storage.getUser();
      final refreshToken = await _storage.getRefreshToken();
      final userId = user?['id'];

      if (userId != null && refreshToken != null) {
        final response = await _dio.post(
          '/api/v1/Users/logout/$userId',
          data: refreshToken, // Backend might expect string as payload
        );
        
        final data = response.data;
        if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        }
      }
    } catch (e) {
      appLogger.e('Error during API logout', error: e);
    } finally {
      await _storage.clearAll();
    }
    return Right(message);
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NoInternetFailure();
    }
    
    final response = e.response;
    if (response != null) {
      if (response.statusCode == 401) return const UnauthorizedFailure();
      
      final data = response.data;
      if (data is Map) {
        final apiMessage = data['message'] ?? data['msg'] ?? data['error'];
        if (apiMessage != null) {
          return ServerFailure(message: apiMessage.toString());
        }
      }
      return const ServerFailure();
    }
    
    return const UnknownFailure();
  }
}
