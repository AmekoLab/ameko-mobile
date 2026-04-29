import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_state.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final PaymentRepository _repository;

  CheckoutBloc({required PaymentRepository repository})
      : _repository = repository,
        super(const CheckoutInitial()) {
    on<CheckoutWithVnpay>(_onCheckoutWithVnpay);
    on<CheckoutWithWallet>(_onCheckoutWithWallet);
    on<ConfirmVnpayPayment>(_onConfirmVnpay);
    on<ResetCheckout>((_, emit) => emit(const CheckoutInitial()));
  }

  Future<void> _onCheckoutWithVnpay(
    CheckoutWithVnpay event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());
    final result = await _repository.checkoutWithVnpay(
      selectedOrderItemIds: event.selectedOrderItemIds,
      shippingAddress: event.shippingAddress,
      receiverName: event.receiverName,
      receiverPhone: event.receiverPhone,
      shippingNote: event.shippingNote,
    );
    result.fold(
      (failure) => emit(CheckoutFailure(failure.message)),
      (checkoutResult) {
        if (checkoutResult.paymentUrl != null &&
            checkoutResult.paymentUrl!.isNotEmpty) {
          emit(CheckoutVnpayReady(checkoutResult.paymentUrl!));
        } else {
          emit(const CheckoutFailure('Không lấy được link thanh toán VNPAY'));
        }
      },
    );
  }

  Future<void> _onCheckoutWithWallet(
    CheckoutWithWallet event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());
    final result = await _repository.checkoutWithWallet(
      selectedOrderItemIds: event.selectedOrderItemIds,
      shippingAddress: event.shippingAddress,
      receiverName: event.receiverName,
      receiverPhone: event.receiverPhone,
      walletPin: event.walletPin,
      shippingNote: event.shippingNote,
    );
    result.fold(
      (failure) => emit(CheckoutFailure(failure.message)),
      (checkoutResult) => emit(CheckoutSuccess(checkoutResult)),
    );
  }

  Future<void> _onConfirmVnpay(
    ConfirmVnpayPayment event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());
    final result = await _repository.confirmVnpay(event.queryParams);
    result.fold(
      (failure) => emit(CheckoutFailure(failure.message)),
      (success) {
        if (success) {
          // Use a generic success result for VNPAY confirm
          emit(CheckoutSuccess(
            CheckoutResultEntity(
              paymentMethod: 'VnPay',
              isSuccess: true,
              message: 'Thanh toán VNPAY thành công',
            ),
          ));
        } else {
          emit(const CheckoutFailure('Xác nhận thanh toán thất bại'));
        }
      },
    );
  }
}
