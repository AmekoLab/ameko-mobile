import 'package:equatable/equatable.dart';

class CheckoutResultEntity extends Equatable {
  final String? paymentUrl;
  final String? orderId;
  final String paymentMethod;
  final bool isSuccess;
  final String? message;

  const CheckoutResultEntity({
    this.paymentUrl,
    this.orderId,
    required this.paymentMethod,
    this.isSuccess = false,
    this.message,
  });

  @override
  List<Object?> get props => [paymentUrl, orderId, paymentMethod, isSuccess];
}
