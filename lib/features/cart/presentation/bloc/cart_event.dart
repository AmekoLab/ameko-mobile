import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class FetchCart extends CartEvent {}

class AddItemToCart extends CartEvent {
  final String productId;
  final int quantity;
  final bool isCustom;

  const AddItemToCart({
    required this.productId,
    this.quantity = 1,
    this.isCustom = false,
  });

  @override
  List<Object?> get props => [productId, quantity, isCustom];
}
