import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';

class CheckoutResultModel extends CheckoutResultEntity {
  const CheckoutResultModel({
    super.paymentUrl,
    super.orderId,
    required super.paymentMethod,
    super.isSuccess,
    super.message,
  });

  factory CheckoutResultModel.fromJson(
    Map<String, dynamic> json,
    String paymentMethod,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CheckoutResultModel(
      paymentUrl: data['paymentUrl']?.toString(),
      orderId: data['orderId']?.toString(),
      paymentMethod: paymentMethod,
      isSuccess: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}
