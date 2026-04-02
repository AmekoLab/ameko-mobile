import 'package:dartz/dartz.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getMyOrders({int? status});
  
  Future<Either<Failure, List<OrderEntity>>> getShopOrders({
    required int status,
    int page = 1,
    int size = 10,
  });
}
