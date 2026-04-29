import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();
  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

/// VNPAY checkout ready — WebView should open paymentUrl
class CheckoutVnpayReady extends CheckoutState {
  final String paymentUrl;
  const CheckoutVnpayReady(this.paymentUrl);

  @override
  List<Object?> get props => [paymentUrl];
}

/// Payment (Wallet or VNPAY confirmed) completed successfully
class CheckoutSuccess extends CheckoutState {
  final CheckoutResultEntity result;
  const CheckoutSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class CheckoutFailure extends CheckoutState {
  final String message;
  const CheckoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}
