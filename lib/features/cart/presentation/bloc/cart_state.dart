import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/cart/domain/entities/cart_entity.dart';

enum CartStatus { initial, loading, success, failure, addingItem, addedSuccessfully }

class CartState extends Equatable {
  final CartEntity? cart;
  final CartStatus status;
  final String? error;
  final String? message;

  const CartState({
    this.cart,
    this.status = CartStatus.initial,
    this.error,
    this.message,
  });

  CartState copyWith({
    CartEntity? cart,
    CartStatus? status,
    String? error,
    String? message,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      status: status ?? this.status,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [cart, status, error, message];
}
