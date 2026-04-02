import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/order/data/models/order_model.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';
import 'package:ameko_app/features/order/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final Dio _dio;

  OrderRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<OrderEntity>>> getMyOrders({int? status}) async {
    try {
      final response = await _dio.get(
        '/api/v1/orders/my-orders',
        queryParameters: status != null ? {'status': status} : null,
      );
      final result = OrderListResponse.fromJson(response.data);
      if (result.success) {
        return Right(result.data);
      } else {
        return Left(ServerFailure(message: result.message));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getShopOrders({
    required int status,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/orders/shop',
        queryParameters: {
          'status': status,
          'page': page,
          'size': size,
        },
      );
      final result = OrderListResponse.fromJson(response.data);
      if (result.success) {
        return Right(result.data);
      } else {
        return Left(ServerFailure(message: result.message));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
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
