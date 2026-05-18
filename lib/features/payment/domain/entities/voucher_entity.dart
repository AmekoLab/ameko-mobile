import 'package:equatable/equatable.dart';

class VoucherEntity extends Equatable {
  final String id;
  final String code;
  final String? name;
  final String? description;
  final int discountType; // 0: Percentage, 1: FixedAmount
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderValue;
  final DateTime? startDate;
  final DateTime? endDate;

  const VoucherEntity({
    required this.id,
    required this.code,
    this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minOrderValue,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        discountType,
        discountValue,
        maxDiscountAmount,
        minOrderValue,
        startDate,
        endDate,
      ];
}

class ShopVoucherGroupEntity extends Equatable {
  final String shopId;
  final String shopName;
  final List<VoucherEntity> vouchers;

  const ShopVoucherGroupEntity({
    required this.shopId,
    required this.shopName,
    required this.vouchers,
  });

  @override
  List<Object?> get props => [shopId, shopName, vouchers];
}

class ApplicableVoucherResponseEntity extends Equatable {
  final List<VoucherEntity> systemVouchers;
  final List<ShopVoucherGroupEntity> shopVoucherGroups;

  const ApplicableVoucherResponseEntity({
    required this.systemVouchers,
    required this.shopVoucherGroups,
  });

  @override
  List<Object?> get props => [systemVouchers, shopVoucherGroups];
}

class ShopPreviewEntity extends Equatable {
  final String shopId;
  final String shopName;
  final double subTotal;
  final double shopDiscountAmount;
  final double shippingFee;

  const ShopPreviewEntity({
    required this.shopId,
    required this.shopName,
    required this.subTotal,
    required this.shopDiscountAmount,
    required this.shippingFee,
  });

  @override
  List<Object?> get props => [shopId, shopName, subTotal, shopDiscountAmount, shippingFee];
}

class CalculatePreviewResponseEntity extends Equatable {
  final double totalCartSubTotal;
  final double totalDiscountAmount;
  final double finalTotalAmount;
  final double shippingFee;
  final String? systemVoucherError;
  final String? shopVoucherError;
  final List<ShopPreviewEntity> shopPreviews;

  const CalculatePreviewResponseEntity({
    required this.totalCartSubTotal,
    required this.totalDiscountAmount,
    required this.finalTotalAmount,
    required this.shippingFee,
    this.systemVoucherError,
    this.shopVoucherError,
    required this.shopPreviews,
  });

  @override
  List<Object?> get props => [
        totalCartSubTotal,
        totalDiscountAmount,
        finalTotalAmount,
        shippingFee,
        systemVoucherError,
        shopVoucherError,
        shopPreviews,
      ];
}
