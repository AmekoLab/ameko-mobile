// Core exceptions representing application-level errors

class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Session expired. Please login again.',
    super.code = '401',
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.code = '403',
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = '404',
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error. Please try again later.',
    super.code = '500',
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Connection timed out. Please check your internet.',
    super.code = 'TIMEOUT',
  });
}

class NoInternetException extends AppException {
  const NoInternetException({
    super.message = 'No internet connection.',
    super.code = 'NO_INTERNET',
  });
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code = 'VALIDATION'});
}

class StorageException extends AppException {
  const StorageException({required super.message, super.code = 'STORAGE'});
}
