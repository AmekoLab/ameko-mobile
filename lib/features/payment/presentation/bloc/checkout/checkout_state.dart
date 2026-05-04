import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/voucher_entity.dart';

enum CheckoutStatus { initial, loading, vnpayReady, success, failure }

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final String? paymentUrl;
  final CheckoutResultEntity? result;
  final String? message;

  // Voucher and preview fields
  final String? appliedSystemVoucherCode;
  final Map<String, String> appliedShopVoucherCodes; // Key: ShopId, Value: VoucherCode
  final double discountAmount;
  final double calculatedTotalAmount;
  final double totalCartSubTotal;
  final double shippingFee;
  final String? systemVoucherError;
  final String? shopVoucherError;

  // Applicable vouchers
  final ApplicableVoucherResponseEntity? applicableVouchers;
  final List<ShopPreviewEntity> shopPreviews;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.paymentUrl,
    this.result,
    this.message,
    this.appliedSystemVoucherCode,
    this.appliedShopVoucherCodes = const {},
    this.discountAmount = 0.0,
    this.calculatedTotalAmount = 0.0,
    this.totalCartSubTotal = 0.0,
    this.shippingFee = 0.0,
    this.systemVoucherError,
    this.shopVoucherError,
    this.applicableVouchers,
    this.shopPreviews = const [],
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? paymentUrl,
    CheckoutResultEntity? result,
    String? message,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
    double? discountAmount,
    double? calculatedTotalAmount,
    double? totalCartSubTotal,
    double? shippingFee,
    String? systemVoucherError,
    String? shopVoucherError,
    ApplicableVoucherResponseEntity? applicableVouchers,
    List<ShopPreviewEntity>? shopPreviews,
    bool clearSystemVoucher = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      result: result ?? this.result,
      message: message ?? this.message,
      appliedSystemVoucherCode: clearSystemVoucher ? null : (appliedSystemVoucherCode ?? this.appliedSystemVoucherCode),
      appliedShopVoucherCodes: appliedShopVoucherCodes ?? this.appliedShopVoucherCodes,
      discountAmount: discountAmount ?? this.discountAmount,
      calculatedTotalAmount: calculatedTotalAmount ?? this.calculatedTotalAmount,
      totalCartSubTotal: totalCartSubTotal ?? this.totalCartSubTotal,
      shippingFee: shippingFee ?? this.shippingFee,
      systemVoucherError: systemVoucherError,
      shopVoucherError: shopVoucherError,
      applicableVouchers: applicableVouchers ?? this.applicableVouchers,
      shopPreviews: shopPreviews ?? this.shopPreviews,
    );
  }

  // Clear errors and specific vouchers using a dedicated method
  CheckoutState clearSystemVoucher() {
    return CheckoutState(
      status: status,
      paymentUrl: paymentUrl,
      result: result,
      message: message,
      appliedSystemVoucherCode: null,
      appliedShopVoucherCodes: appliedShopVoucherCodes,
      discountAmount: discountAmount,
      calculatedTotalAmount: calculatedTotalAmount,
      totalCartSubTotal: totalCartSubTotal,
      shippingFee: shippingFee,
      systemVoucherError: null,
      shopVoucherError: shopVoucherError,
      applicableVouchers: applicableVouchers,
      shopPreviews: shopPreviews,
    );
  }

  @override
  List<Object?> get props => [
        status,
        paymentUrl,
        result,
        message,
        appliedSystemVoucherCode,
        appliedShopVoucherCodes,
        discountAmount,
        calculatedTotalAmount,
        totalCartSubTotal,
        shippingFee,
        systemVoucherError,
        shopVoucherError,
        applicableVouchers,
        shopPreviews,
      ];
}
