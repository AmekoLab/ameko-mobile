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
          final profileResult = await getProfile(id: data.id, token: data.token);
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
  Future<Either<Failure, UserEntity>> getProfile({
    required String id,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/Users/profile/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final profileResponse = ProfileResponseModel.fromJson(response.data);

      if (profileResponse.success && profileResponse.data != null) {
        final profileUser = profileResponse.data!;
        
        // Merge with existing cached data to preserve fields like 'role' or 'token'
        final cachedUserJson = _storage.getUser();
        final cachedUser = cachedUserJson != null ? UserEntity.fromJson(cachedUserJson) : null;

        final mergedUser = UserModel(
          id: profileUser.id.isNotEmpty ? profileUser.id : id,
          username: profileUser.username.isNotEmpty ? profileUser.username : (cachedUser?.username ?? ''),
          email: profileUser.email.isNotEmpty ? profileUser.email : (cachedUser?.email ?? ''),
          fullName: profileUser.fullName ?? cachedUser?.fullName,
          role: (profileUser.role != null && profileUser.role!.isNotEmpty) 
              ? profileUser.role 
              : cachedUser?.role,
          token: profileUser.token ?? token, // Keep current token if profile doesn't return one
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
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Implement real registration if needed, otherwise keep mock-like but with Dio
    return Left(ServerFailure(message: 'Registration not implemented yet.'));
  }

  @override
  Future<Either<Failure, String>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/api/v1/Users/forgot-password',
        data: {'email': email},
      );
      
      final data = response.data;
      if (data is Map && data.containsKey('message')) {
        return Right(data['message'].toString());
      }
      return const Right('Reset instructions sent to your email.');
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
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
      
      final data = response.data;
      if (data is Map && data.containsKey('message')) {
        return Right(data['message'].toString());
      }
      return const Right('Password reset successful.');
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({required String otp}) async {
    return const Left(ServerFailure(message: 'OTP verification not implemented.'));
  }

  @override
  Future<Either<Failure, String>> logout() async {
    String message = 'Đã đăng xuất khỏi thiết bị.';
    try {
      final user = _storage.getUser();
      final refreshToken = await _storage.getRefreshToken();
      final userId = user?['id'];

      if (userId != null && refreshToken != null) {
        appLogger.d('Logging out user: $userId');
        final response = await _dio.post(
          '/api/v1/Users/logout/$userId',
          data: {'refreshToken': refreshToken},
        );
        
        final data = response.data;
        if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        }
      }
    } catch (e) {
      appLogger.e('Error during API logout', error: e);
      // Even if API fails, we still consider it a local logout
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
    }
    
    return UnknownFailure(message: e.message ?? 'Unknown error');
  }
}
