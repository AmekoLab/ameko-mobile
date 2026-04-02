import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
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

  const OrderItemEntity({
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
  });

  @override
  List<Object?> get props => [
        orderItemId,
        productId,
        assembledProductId,
        productName,
        productImage,
        shopId,
        shopName,
        quantity,
        unitPrice,
        totalPrice,
        isCustom,
        note,
      ];
}

class OrderEntity extends Equatable {
  final String orderId;
  final String orderGroupId;
  final String shopId;
  final String shopName;
  final String? shopAvatar;
  final String orderStatus;
  final String paymentStatus;
  final double subTotal;
  final double shippingFee;
  final double discountAmount;
  final double totalAmount;
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final String? note;
  final bool hasCancelRequest;
  final DateTime createdAt;
  final List<OrderItemEntity> orderItems;

  const OrderEntity({
    required this.orderId,
    required this.orderGroupId,
    required this.shopId,
    required this.shopName,
    this.shopAvatar,
    required this.orderStatus,
    required this.paymentStatus,
    required this.subTotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    this.note,
    required this.hasCancelRequest,
    required this.createdAt,
    required this.orderItems,
  });

  @override
  List<Object?> get props => [
        orderId,
        orderGroupId,
        shopId,
        orderStatus,
        paymentStatus,
        totalAmount,
        createdAt,
      ];
}
