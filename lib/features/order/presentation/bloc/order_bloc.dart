import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';
import 'package:ameko_app/features/order/domain/repositories/order_repository.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_event.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc({required OrderRepository repository})
      : _repository = repository,
        super(const OrderInitial()) {
    on<MyOrdersFetched>(_onMyOrdersFetched);
    on<ShopOrdersFetched>(_onShopOrdersFetched);
    on<OrderSortChanged>(_onSortChanged);
  }

  Future<void> _onMyOrdersFetched(
    MyOrdersFetched event,
    Emitter<OrderState> emit,
  ) async {
    final currentSort = state is OrderLoaded ? (state as OrderLoaded).sortByPrice : PriceSort.none;
    emit(const OrderLoading());
    
    // Fetch all for client-side filtering or handle server-side if supported
    final result = await _repository.getMyOrders(status: event.status);
    
    result.fold(
      (failure) => emit(OrderFailure(message: failure.message)),
      (orders) {
        // FILTER: If status is specified, filter by orderStatus string from API
        List<OrderEntity> filteredOrders = orders;
        if (event.status != null) {
          final statusString = _getStatusString(event.status!);
          if (statusString != null) {
            filteredOrders = orders.where((o) => 
               o.orderStatus.toLowerCase() == statusString.toLowerCase()
            ).toList();
          }
        }

        final sortedOrders = _sortOrders(filteredOrders, currentSort);
        emit(OrderLoaded(
          orders: sortedOrders,
          isShopOrders: false,
          currentStatus: event.status ?? -1,
          sortByPrice: currentSort,
        ));
      },
    );
  }

  String? _getStatusString(int status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'InCart';
      case 2: return 'Processing';
      case 3: return 'Shipped';
      case 4: return 'Completed';
      case 5: return 'Cancelled';
      case 6: return 'Returning';
      case 7: return 'Returned';
      case 8: return 'Refunded';
      default: return null;
    }
  }

  Future<void> _onShopOrdersFetched(
    ShopOrdersFetched event,
    Emitter<OrderState> emit,
  ) async {
    final currentSort = state is OrderLoaded ? (state as OrderLoaded).sortByPrice : PriceSort.none;
    emit(const OrderLoading());
    final result = await _repository.getShopOrders(
      status: event.status,
      page: event.page,
      size: event.size,
    );
    result.fold(
      (failure) => emit(OrderFailure(message: failure.message)),
      (orders) {
        final sortedOrders = _sortOrders(orders, currentSort);
        emit(OrderLoaded(
          orders: sortedOrders,
          isShopOrders: true,
          currentStatus: event.status,
          sortByPrice: currentSort,
        ));
      },
    );
  }

  void _onSortChanged(
    OrderSortChanged event,
    Emitter<OrderState> emit,
  ) {
    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final sortedOrders = _sortOrders(List.from(currentState.orders), event.sort);
      emit(OrderLoaded(
        orders: sortedOrders,
        isShopOrders: currentState.isShopOrders,
        currentStatus: currentState.currentStatus,
        sortByPrice: event.sort,
      ));
    }
  }

  List<OrderEntity> _sortOrders(List<OrderEntity> orders, PriceSort sort) {
    final List<OrderEntity> sortedList = List.from(orders);
    switch (sort) {
      case PriceSort.lowToHigh:
        sortedList.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case PriceSort.highToLow:
        sortedList.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case PriceSort.none:
        // Keep original (usually latest)
        break;
    }
    return sortedList;
  }
}
