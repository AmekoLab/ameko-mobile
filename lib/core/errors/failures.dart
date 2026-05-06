import 'package:equatable/equatable.dart';

// Failures are domain-layer representations of errors shown to the UI.

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Có lỗi xảy ra khi kết nối mạng'});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Có lỗi xảy ra từ máy chủ'});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
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
    super.message = 'Không có kết nối internet. Vui lòng kiểm tra lại.',
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Kết nối quá hạn. Vui lòng thử lại.',
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Có lỗi xảy ra. Vui lòng thử lại sau.',
  });
}
