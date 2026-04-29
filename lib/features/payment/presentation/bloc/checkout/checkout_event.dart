import 'package:equatable/equatable.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();
  @override
  List<Object?> get props => [];
}

class CheckoutWithVnpay extends CheckoutEvent {
  final List<String> selectedOrderItemIds;
  final String shippingAddress;
  final String receiverName;
  final String receiverPhone;
  final String? shippingNote;

  const CheckoutWithVnpay({
    required this.selectedOrderItemIds,
    required this.shippingAddress,
    required this.receiverName,
    required this.receiverPhone,
    this.shippingNote,
  });

  @override
  List<Object?> get props => [
        selectedOrderItemIds,
        shippingAddress,
        receiverName,
        receiverPhone,
        shippingNote,
      ];
}

class CheckoutWithWallet extends CheckoutEvent {
  final List<String> selectedOrderItemIds;
  final String shippingAddress;
  final String receiverName;
  final String receiverPhone;
  final String? shippingNote;
  final String walletPin;

  const CheckoutWithWallet({
    required this.selectedOrderItemIds,
    required this.shippingAddress,
    required this.receiverName,
    required this.receiverPhone,
    required this.walletPin,
    this.shippingNote,
  });

  @override
  List<Object?> get props => [
        selectedOrderItemIds,
        shippingAddress,
        receiverName,
        receiverPhone,
        walletPin,
        shippingNote,
      ];
}

class ConfirmVnpayPayment extends CheckoutEvent {
  final Map<String, String> queryParams;
  const ConfirmVnpayPayment(this.queryParams);

  @override
  List<Object?> get props => [queryParams];
}

class ResetCheckout extends CheckoutEvent {}
