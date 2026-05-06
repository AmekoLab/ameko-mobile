import 'package:ameko_app/features/order/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.orderId,
    required super.orderGroupId,
    required super.shopId,
    required super.shopName,
    super.shopAvatar,
    required super.orderStatus,
    required super.paymentStatus,
    required super.subTotal,
    required super.shippingFee,
    required super.discountAmount,
    required super.totalAmount,
    required super.receiverName,
    required super.receiverPhone,
    required super.shippingAddress,
    super.note,
    required super.hasCancelRequest,
    required super.createdAt,
    required super.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      orderGroupId: json['orderGroupId'] ?? '',
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      shopAvatar: json['shopAvatar'],
      orderStatus: json['orderStatus'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      receiverName: json['receiverName'] ?? '',
      receiverPhone: json['receiverPhone'] ?? '',
      shippingAddress: json['shippingAddress'] ?? '',
      note: json['note'],
      hasCancelRequest: json['hasCancelRequest'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      orderItems: (json['orderItems'] as List? ?? [])
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderGroupId': orderGroupId,
      'shopId': shopId,
      'shopName': shopName,
      'shopAvatar': shopAvatar,
      'orderStatus': orderStatus,
      'paymentStatus': paymentStatus,
      'subTotal': subTotal,
      'shippingFee': shippingFee,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'note': note,
      'hasCancelRequest': hasCancelRequest,
      'createdAt': createdAt.toIso8601String(),
      'orderItems': orderItems.map((e) => (e as OrderItemModel).toJson()).toList(),
    };
  }
}

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
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
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      orderItemId: json['orderItemId'] ?? '',
      productId: json['productId'] ?? '',
      assembledProductId: json['assembledProductId'],
      productName: json['productName'] ?? '',
      productImage: json['productImage'],
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      isCustom: json['isCustom'] ?? false,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderItemId': orderItemId,
      'productId': productId,
      'assembledProductId': assembledProductId,
      'productName': productName,
      'productImage': productImage,
      'shopId': shopId,
      'shopName': shopName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'isCustom': isCustom,
      'note': note,
    };
  }
}

class OrderListResponse {
  final bool success;
  final String message;
  final List<OrderModel> data;

  OrderListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    final dataField = json['data'];
    List listData = [];
    if (dataField is List) {
      listData = dataField;
    } else if (dataField is Map && dataField['items'] is List) {
      listData = dataField['items'];
    }

    return OrderListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: listData.map((e) => OrderModel.fromJson(e)).toList(),
    );
  }
}
