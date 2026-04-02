import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class MyOrdersFetched extends OrderEvent {
  final int? status;
  const MyOrdersFetched({this.status});

  @override
  List<Object?> get props => [status];
}

class ShopOrdersFetched extends OrderEvent {
  final int status;
  final int page;
  final int size;

  const ShopOrdersFetched({
    required this.status,
    this.page = 1,
    this.size = 10,
  });

  @override
  List<Object?> get props => [status, page, size];
}

enum PriceSort { none, lowToHigh, highToLow }

class OrderSortChanged extends OrderEvent {
  final PriceSort sort;

  const OrderSortChanged(this.sort);

  @override
  List<Object?> get props => [sort];
}
