import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_state.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final PaymentRepository _repository;

  CheckoutBloc({required PaymentRepository repository})
      : _repository = repository,
        super(const CheckoutState()) {
    on<CheckoutWithVnpay>(_onCheckoutWithVnpay);
    on<CheckoutWithWallet>(_onCheckoutWithWallet);
    on<ConfirmVnpayPayment>(_onConfirmVnpay);
    on<FetchApplicableVouchers>(_onFetchApplicableVouchers);
    on<SelectVoucher>(_onSelectVoucher);
    on<CalculatePreview>(_onCalculatePreview);
    on<ResetCheckout>((_, emit) => emit(const CheckoutState()));
  }

  Future<void> _onCheckoutWithVnpay(
    CheckoutWithVnpay event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    final result = await _repository.checkoutWithVnpay(
      selectedOrderItemIds: event.selectedOrderItemIds,
      shippingAddress: event.shippingAddress,
      receiverName: event.receiverName,
      receiverPhone: event.receiverPhone,
      shippingNote: event.shippingNote,
      appliedSystemVoucherCode: state.appliedSystemVoucherCode,
      appliedShopVoucherCodes: state.appliedShopVoucherCodes,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: CheckoutStatus.failure,
        message: failure.message,
      )),
      (checkoutResult) {
        if (checkoutResult.paymentUrl != null &&
            checkoutResult.paymentUrl!.isNotEmpty) {
          emit(state.copyWith(
            status: CheckoutStatus.vnpayReady,
            paymentUrl: checkoutResult.paymentUrl,
          ));
        } else {
          emit(state.copyWith(
            status: CheckoutStatus.failure,
            message: 'Không lấy được link thanh toán VNPAY',
          ));
        }
      },
    );
  }

  Future<void> _onCheckoutWithWallet(
    CheckoutWithWallet event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    final result = await _repository.checkoutWithWallet(
      selectedOrderItemIds: event.selectedOrderItemIds,
      shippingAddress: event.shippingAddress,
      receiverName: event.receiverName,
      receiverPhone: event.receiverPhone,
      walletPin: event.walletPin,
      shippingNote: event.shippingNote,
      appliedSystemVoucherCode: state.appliedSystemVoucherCode,
      appliedShopVoucherCodes: state.appliedShopVoucherCodes,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: CheckoutStatus.failure,
        message: failure.message,
      )),
      (checkoutResult) => emit(state.copyWith(
        status: CheckoutStatus.success,
        result: checkoutResult,
      )),
    );
  }

  Future<void> _onConfirmVnpay(
    ConfirmVnpayPayment event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    final result = await _repository.confirmVnpay(event.queryParams);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CheckoutStatus.failure,
        message: failure.message,
      )),
      (success) {
        if (success) {
          emit(state.copyWith(
            status: CheckoutStatus.success,
            result: CheckoutResultEntity(
              paymentMethod: 'VnPay',
              isSuccess: true,
              message: 'Thanh toán VNPAY thành công',
            ),
          ));
        } else {
          emit(state.copyWith(
            status: CheckoutStatus.failure,
            message: 'Xác nhận thanh toán thất bại',
          ));
        }
      },
    );
  }

  Future<void> _onFetchApplicableVouchers(
    FetchApplicableVouchers event,
    Emitter<CheckoutState> emit,
  ) async {
    final result = await _repository.getApplicableVouchers();
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)), // Just pass message, don't change status to failure if we don't want to break the UI
      (vouchers) => emit(state.copyWith(applicableVouchers: vouchers)),
    );
  }

  void _onSelectVoucher(
    SelectVoucher event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      appliedSystemVoucherCode: event.systemVoucherCode,
      clearSystemVoucher: event.systemVoucherCode == null,
      appliedShopVoucherCodes: event.shopVoucherCodes,
    ));
    add(CalculatePreview(event.selectedOrderItemIds));
  }

  Future<void> _onCalculatePreview(
    CalculatePreview event,
    Emitter<CheckoutState> emit,
  ) async {
    // Optionally emit a preview loading state if needed, but usually we just want to update silently
    final result = await _repository.calculatePreview(
      selectedOrderItemIds: event.selectedOrderItemIds,
      appliedSystemVoucherCode: state.appliedSystemVoucherCode,
      appliedShopVoucherCodes: state.appliedShopVoucherCodes,
    );

    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)), // Just show toast
      (preview) {
        // If there are errors, we could automatically clear the voucher, but it's better to keep it and show the error.
        emit(state.copyWith(
          discountAmount: preview.totalDiscountAmount,
          calculatedTotalAmount: preview.finalTotalAmount,
          totalCartSubTotal: preview.totalCartSubTotal,
          shippingFee: preview.shippingFee,
          systemVoucherError: preview.systemVoucherError,
          shopVoucherError: preview.shopVoucherError,
          shopPreviews: preview.shopPreviews,
        ));
      },
    );
  }
}
