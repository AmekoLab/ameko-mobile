import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/notification/data/models/notification_model.dart';
import 'package:ameko_app/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final Dio _dio;

  NotificationRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getNotifications({String? cursor, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/Notifications',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'pageSize': pageSize,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right({
        'items': (data['items'] as List).map((e) => NotificationModel.fromJson(e)).toList(),
        'nextCursor': data['nextCursor'],
        'hasMore': data['hasMore'] ?? (data['nextCursor'] != null),
      });
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final response = await _dio.get('/api/v1/Notifications/unread-count');
      final unreadCount = response.data['unreadCount'] as int? ?? 0;
      return Right(unreadCount);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      await _dio.post('/api/v1/Notifications/$id/read');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _dio.post('/api/v1/Notifications/read-all');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
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
        final msg = data['message'] ?? data['msg'] ?? data['error'];
        if (msg != null) return ServerFailure(message: msg.toString());
      }
      return const ServerFailure();
    }
    return const UnknownFailure();
  }
}
