import 'package:dio/dio.dart';
import 'package:ameko_app/features/cart/domain/entities/cart_entity.dart';
import 'package:ameko_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:ameko_app/features/cart/data/models/cart_model.dart';
import 'package:ameko_app/core/utils/app_logger.dart';

class CartRepositoryImpl implements CartRepository {
  final Dio _dio;

  CartRepositoryImpl(this._dio);

  @override
  Future<CartEntity> getCart() async {
    try {
      final response = await _dio.get('/api/v1/orders/cart');
      final data = response.data['data'];
      
      if (data == null) {
        return const CartEntity(
          orderId: '',
          shopId: '',
          shopName: '',
          subTotal: 0,
          shippingFee: 0,
          discountAmount: 0,
          totalAmount: 0,
          items: [],
        );
      }
      
      return CartModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Error fetching cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> addToCart({
    required String productId,
    required int quantity,
    bool isCustom = false,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/orders/cart',
        data: {
          'productId': productId,
          'quantity': quantity,
          'isCustom': isCustom,
        },
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to add item to cart');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to add item to cart';
      throw Exception(message);
    } catch (e) {
      appLogger.e('Error adding to cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    try {
      final response = await _dio.put(
        '/api/v1/orders/cart/$itemId',
        data: {'quantity': quantity},
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update item quantity');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to update item quantity';
      throw Exception(message);
    } catch (e) {
      appLogger.e('Error updating cart quantity: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(List<String> itemIds) async {
    try {
      for (final id in itemIds) {
        await _dio.delete('/api/v1/orders/cart/$id');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to remove item(s) from cart';
      throw Exception(message);
    } catch (e) {
      appLogger.e('Error removing from cart: $e');
      rethrow;
    }
  }
}
