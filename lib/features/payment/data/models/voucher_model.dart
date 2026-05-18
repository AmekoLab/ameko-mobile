import 'package:ameko_app/features/payment/domain/entities/voucher_entity.dart';

class VoucherModel {
  final String id;
  final String code;
  final String? name;
  final String? description;
  final int discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderValue;
  final DateTime? startDate;
  final DateTime? endDate;

  VoucherModel({
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

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'],
      description: json['description'],
      discountType: json['discountType'] != null ? int.tryParse(json['discountType'].toString()) ?? 0 : 0,
      discountValue: json['discountValue'] != null ? double.tryParse(json['discountValue'].toString()) ?? 0.0 : 0.0,
      maxDiscountAmount: json['maxDiscountAmount'] != null ? double.tryParse(json['maxDiscountAmount'].toString()) : null,
      minOrderValue: json['minOrderValue'] != null ? double.tryParse(json['minOrderValue'].toString()) : null,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
    );
  }

  VoucherEntity toEntity() {
    return VoucherEntity(
      id: id,
      code: code,
      name: name,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      maxDiscountAmount: maxDiscountAmount,
      minOrderValue: minOrderValue,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

class ShopVoucherGroupModel {
  final String shopId;
  final String shopName;
  final List<VoucherModel> vouchers;

  ShopVoucherGroupModel({
    required this.shopId,
    required this.shopName,
    required this.vouchers,
  });

  factory ShopVoucherGroupModel.fromJson(Map<String, dynamic> json) {
    return ShopVoucherGroupModel(
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
      vouchers: (json['vouchers'] as List?)?.map((e) => VoucherModel.fromJson(e)).toList() ?? [],
    );
  }

  ShopVoucherGroupEntity toEntity() {
    return ShopVoucherGroupEntity(
      shopId: shopId,
      shopName: shopName,
      vouchers: vouchers.map((v) => v.toEntity()).toList(),
    );
  }
}

class ApplicableVoucherResponseModel {
  final List<VoucherModel> systemVouchers;
  final List<ShopVoucherGroupModel> shopVoucherGroups;

  ApplicableVoucherResponseModel({
    required this.systemVouchers,
    required this.shopVoucherGroups,
  });

  factory ApplicableVoucherResponseModel.fromJson(Map<String, dynamic> json) {
    return ApplicableVoucherResponseModel(
      systemVouchers: (json['systemVouchers'] as List?)?.map((e) => VoucherModel.fromJson(e)).toList() ?? [],
      shopVoucherGroups: (json['shopVoucherGroups'] as List?)?.map((e) => ShopVoucherGroupModel.fromJson(e)).toList() ?? [],
    );
  }

  ApplicableVoucherResponseEntity toEntity() {
    return ApplicableVoucherResponseEntity(
      systemVouchers: systemVouchers.map((v) => v.toEntity()).toList(),
      shopVoucherGroups: shopVoucherGroups.map((g) => g.toEntity()).toList(),
    );
  }
}

class ShopPreviewModel {
  final String shopId;
  final String shopName;
  final double subTotal;
  final double shopDiscountAmount;
  final double shippingFee;

  ShopPreviewModel({
    required this.shopId,
    required this.shopName,
    required this.subTotal,
    required this.shopDiscountAmount,
    required this.shippingFee,
  });

  factory ShopPreviewModel.fromJson(Map<String, dynamic> json) {
    return ShopPreviewModel(
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      subTotal: json['subTotal'] != null ? double.tryParse(json['subTotal'].toString()) ?? 0.0 : 0.0,
      shopDiscountAmount: json['shopDiscountAmount'] != null ? double.tryParse(json['shopDiscountAmount'].toString()) ?? 0.0 : 0.0,
      shippingFee: json['shippingFee'] != null ? double.tryParse(json['shippingFee'].toString()) ?? 0.0 : 0.0,
    );
  }

  ShopPreviewEntity toEntity() {
    return ShopPreviewEntity(
      shopId: shopId,
      shopName: shopName,
      subTotal: subTotal,
      shopDiscountAmount: shopDiscountAmount,
      shippingFee: shippingFee,
    );
  }
}

class CalculatePreviewResponseModel {
  final double totalCartSubTotal;
  final double totalDiscountAmount;
  final double finalTotalAmount;
  final double shippingFee;
  final String? systemVoucherError;
  final String? shopVoucherError;
  final List<ShopPreviewModel> shopPreviews;

  CalculatePreviewResponseModel({
    required this.totalCartSubTotal,
    required this.totalDiscountAmount,
    required this.finalTotalAmount,
    required this.shippingFee,
    this.systemVoucherError,
    this.shopVoucherError,
    required this.shopPreviews,
  });

  factory CalculatePreviewResponseModel.fromJson(Map<String, dynamic> json) {
    return CalculatePreviewResponseModel(
      totalCartSubTotal: json['totalCartSubTotal'] != null ? double.tryParse(json['totalCartSubTotal'].toString()) ?? 0.0 : 0.0,
      totalDiscountAmount: json['totalDiscountAmount'] != null ? double.tryParse(json['totalDiscountAmount'].toString()) ?? 0.0 : 0.0,
      finalTotalAmount: json['finalTotalAmount'] != null ? double.tryParse(json['finalTotalAmount'].toString()) ?? 0.0 : 0.0,
      shippingFee: json['shippingFee'] != null ? double.tryParse(json['shippingFee'].toString()) ?? 0.0 : 0.0,
      systemVoucherError: json['systemVoucherError']?.toString(),
      shopVoucherError: json['shopVoucherError']?.toString(),
      shopPreviews: (json['shopPreviews'] as List?)?.map((e) => ShopPreviewModel.fromJson(e)).toList() ?? [],
    );
  }

  CalculatePreviewResponseEntity toEntity() {
    return CalculatePreviewResponseEntity(
      totalCartSubTotal: totalCartSubTotal,
      totalDiscountAmount: totalDiscountAmount,
      finalTotalAmount: finalTotalAmount,
      shippingFee: shippingFee,
      systemVoucherError: systemVoucherError,
      shopVoucherError: shopVoucherError,
      shopPreviews: shopPreviews.map((e) => e.toEntity()).toList(),
    );
  }
}
