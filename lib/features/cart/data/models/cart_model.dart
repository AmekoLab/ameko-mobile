import 'package:ameko_app/features/cart/domain/entities/cart_entity.dart';

class CartItemComponentModel extends CartItemComponentEntity {
  const CartItemComponentModel({
    required super.partId,
    required super.partName,
    required super.partPriceSnapshot,
    super.partImageUrl,
    required super.quantity,
    super.note,
  });

  factory CartItemComponentModel.fromJson(Map<String, dynamic> json) {
    return CartItemComponentModel(
      partId: json['partId']?.toString() ?? '',
      partName: json['partName']?.toString() ?? '',
      partPriceSnapshot: _parseDouble(json['partPriceSnapshot']),
      partImageUrl: json['partImageUrl']?.toString(),
      quantity: _parseInt(json['quantity']),
      note: json['note']?.toString(),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }
}

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.orderItemId,
    required super.productId,
    super.assembledProductId,
    required super.productName,
    super.productImage,
    required super.shopId,
    required super.shopName,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
    required super.isCustom,
    super.note,
    super.components = const [],
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawComponents = json['orderItemComponents'] as List<dynamic>? ?? [];
    return CartItemModel(
      orderItemId: json['orderItemId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      assembledProductId: json['assembledProductId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      productImage: json['productImage']?.toString(),
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      quantity: CartItemComponentModel._parseInt(json['quantity']),
      unitPrice: CartItemComponentModel._parseDouble(json['unitPrice']),
      totalPrice: CartItemComponentModel._parseDouble(json['totalPrice']),
      isCustom: json['isCustom'] == true,
      note: json['note']?.toString(),
      components: rawComponents
          .map((e) => CartItemComponentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CartModel extends CartEntity {
  const CartModel({
    required super.orderId,
    required super.shopId,
    required super.shopName,
    super.shopAvatar,
    required super.subTotal,
    required super.shippingFee,
    required super.discountAmount,
    required super.totalAmount,
    required super.items,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['orderItems'] as List<dynamic>? ?? [];
    return CartModel(
      orderId: json['orderId']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      shopAvatar: json['shopAvatar']?.toString(),
      subTotal: CartItemComponentModel._parseDouble(json['subTotal']),
      shippingFee: CartItemComponentModel._parseDouble(json['shippingFee']),
      discountAmount: CartItemComponentModel._parseDouble(json['discountAmount']),
      totalAmount: CartItemComponentModel._parseDouble(json['totalAmount']),
      items: rawItems
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
