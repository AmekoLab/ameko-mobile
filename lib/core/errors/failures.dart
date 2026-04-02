import 'package:equatable/equatable.dart';

// Failures are domain-layer representations of errors shown to the UI.

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expired. Please login again.',
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NoInternetFailure extends Failure {
  const NoInternetFailure({
    super.message = 'No internet connection. Please check your network.',
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Connection timed out. Please try again.',
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
  });
}
