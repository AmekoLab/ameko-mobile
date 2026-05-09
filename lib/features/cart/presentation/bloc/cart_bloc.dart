import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_event.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository repository;

  CartBloc({required this.repository}) : super(const CartState()) {
    on<FetchCart>(_onFetchCart);
    on<AddItemToCart>(_onAddItemToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveCartItems>(_onRemoveCartItems);
  }

  Future<void> _onFetchCart(FetchCart event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await repository.getCart();
      emit(state.copyWith(status: CartStatus.success, cart: cart));
    } catch (e) {
      emit(state.copyWith(status: CartStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onAddItemToCart(AddItemToCart event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.addingItem));
    try {
      await repository.addToCart(
        productId: event.productId,
        quantity: event.quantity,
        isCustom: event.isCustom,
      );
      emit(state.copyWith(
        status: CartStatus.addedSuccessfully,
        message: 'Đã thêm sản phẩm vào giỏ hàng',
      ));
      // Re-fetch cart after adding
      add(FetchCart());
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<CartState> emit) async {
    // We don't necessarily need a loading state for every tiny update, 
    // but the UI can show a spinner if needed.
    try {
      await repository.updateCartItemQuantity(event.itemId, event.quantity);
      // Re-fetch cart after updating
      add(FetchCart());
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRemoveCartItems(RemoveCartItems event, Emitter<CartState> emit) async {
    try {
      await repository.removeFromCart(event.itemIds);
      add(FetchCart());
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
