import 'package:ameko_app/features/cart/domain/entities/cart_entity.dart';

abstract class CartRepository {
  Future<CartEntity> getCart();
  Future<void> addToCart({
    required String productId,
    required int quantity,
    bool isCustom = false,
  });
}
