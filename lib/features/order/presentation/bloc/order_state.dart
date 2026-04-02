import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_event.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderLoaded extends OrderState {
  final List<OrderEntity> orders;
  final bool isShopOrders;
  final int currentStatus;
  final PriceSort sortByPrice;

  const OrderLoaded({
    required this.orders,
    this.isShopOrders = false,
    this.currentStatus = 0,
    this.sortByPrice = PriceSort.none,
  });

  @override
  List<Object?> get props => [orders, isShopOrders, currentStatus, sortByPrice];
}

class OrderFailure extends OrderState {
  final String message;

  const OrderFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
