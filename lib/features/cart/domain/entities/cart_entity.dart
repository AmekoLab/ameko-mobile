import 'package:equatable/equatable.dart';

class CartItemComponentEntity extends Equatable {
  final String partId;
  final String partName;
  final double partPriceSnapshot;
  final String? partImageUrl;
  final int quantity;
  final String? note;

  const CartItemComponentEntity({
    required this.partId,
    required this.partName,
    required this.partPriceSnapshot,
    this.partImageUrl,
    required this.quantity,
    this.note,
  });

  @override
  List<Object?> get props => [partId, partName, partPriceSnapshot, quantity, note];
}

class CartItemEntity extends Equatable {
  final String orderItemId;
  final String productId;
  final String? assembledProductId;
  final String productName;
  final String? productImage;
  final String shopId;
  final String shopName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isCustom;
  final String? note;
  final List<CartItemComponentEntity> components;

  const CartItemEntity({
    required this.orderItemId,
    required this.productId,
    this.assembledProductId,
    required this.productName,
    this.productImage,
    required this.shopId,
    required this.shopName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.isCustom,
    this.note,
    this.components = const [],
  });

  @override
  List<Object?> get props => [
        orderItemId,
        productId,
        productName,
        quantity,
        totalPrice,
        isCustom,
        components,
      ];
}

class CartEntity extends Equatable {
  final String orderId;
  final String shopId;
  final String shopName;
  final String? shopAvatar;
  final double subTotal;
  final double shippingFee;
  final double discountAmount;
  final double totalAmount;
  final List<CartItemEntity> items;

  const CartEntity({
    required this.orderId,
    required this.shopId,
    required this.shopName,
    this.shopAvatar,
    required this.subTotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.items,
  });

  @override
  List<Object?> get props => [orderId, totalAmount, items];
}
