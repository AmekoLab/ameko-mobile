import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Converts low-level exceptions into domain [Failure] objects.
class ErrorMapper {
  ErrorMapper._();

  static Failure fromException(Object error) {
    if (error is DioException) {
      return fromDioException(error);
    } else if (error is AppException) {
      return fromAppException(error);
    }
    return const UnknownFailure();
  }

  static Failure fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractMessage(error.response?.data);

        if (statusCode == 401) {
          return UnauthorizedFailure(message: message ?? 'Unauthorized');
        }
        if (statusCode == 403) {
          return ServerFailure(
            message: message ?? 'You do not have permission.',
          );
        }
        if (statusCode == 404) {
          return ServerFailure(message: message ?? 'Resource not found.');
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            message: message ?? 'Server error. Please try again later.',
          );
        }
        return ServerFailure(
          message: message ?? 'Something went wrong.',
        );

      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request was cancelled.');

      case DioExceptionType.connectionError:
        return const NoInternetFailure();

      default:
        return const NetworkFailure(message: 'Network error occurred.');
    }
  }

  static Failure fromAppException(AppException error) {
    if (error is UnauthorizedException) {
      return UnauthorizedFailure(message: error.message);
    }
    if (error is TimeoutException) {
      return TimeoutFailure(message: error.message);
    }
    if (error is NoInternetException) {
      return NoInternetFailure(message: error.message);
    }
    if (error is ValidationException) {
      return ValidationFailure(message: error.message);
    }
    if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    }
    if (error is ServerException) {
      return ServerFailure(message: error.message);
    }
    return UnknownFailure(message: error.message);
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['title']?.toString();
    }
    if (data is String) return data;
    return null;
  }
}
