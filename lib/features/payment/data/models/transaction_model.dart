import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.transactionCode,
    required super.amount,
    required super.grossAmount,
    required super.feeAmount,
    required super.netAmount,
    required super.flowDirection,
    required super.currency,
    required super.type,
    required super.status,
    super.description,
    required super.balanceAfterTransaction,
    super.shopName,
    super.bankName,
    super.bankAccountNumber,
    super.bankAccountName,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      transactionCode: json['transactionCode']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      grossAmount: _parseDouble(json['grossAmount']),
      feeAmount: _parseDouble(json['feeAmount']),
      netAmount: _parseDouble(json['netAmount']),
      flowDirection: json['flowDirection']?.toString() ?? 'Out',
      currency: json['currency']?.toString() ?? 'VND',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      balanceAfterTransaction: _parseDouble(json['balanceAfterTransaction']),
      shopName: json['shopName']?.toString(),
      bankName: json['bankName']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      bankAccountName: json['bankAccountName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class TransactionDetailModel extends TransactionDetailEntity {
  const TransactionDetailModel({
    required super.id,
    required super.transactionCode,
    required super.amount,
    required super.grossAmount,
    required super.feeAmount,
    required super.netAmount,
    required super.flowDirection,
    required super.currency,
    required super.type,
    required super.status,
    super.description,
    required super.balanceAfterTransaction,
    super.shopName,
    super.bankName,
    super.bankAccountNumber,
    super.bankAccountName,
    required super.createdAt,
    required super.balanceBeforeTransaction,
    required super.heldBalanceBeforeTransaction,
    required super.heldBalanceAfterTransaction,
    super.relatedOrderId,
    super.orderGroupId,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionDetailModel(
      id: json['id']?.toString() ?? '',
      transactionCode: json['transactionCode']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      grossAmount: _parseDouble(json['grossAmount']),
      feeAmount: _parseDouble(json['feeAmount']),
      netAmount: _parseDouble(json['netAmount']),
      flowDirection: json['flowDirection']?.toString() ?? 'Out',
      currency: json['currency']?.toString() ?? 'VND',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      balanceAfterTransaction: _parseDouble(json['balanceAfterTransaction']),
      shopName: json['shopName']?.toString(),
      bankName: json['bankName']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      bankAccountName: json['bankAccountName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      balanceBeforeTransaction: _parseDouble(json['balanceBeforeTransaction']),
      heldBalanceBeforeTransaction: _parseDouble(json['heldBalanceBeforeTransaction']),
      heldBalanceAfterTransaction: _parseDouble(json['heldBalanceAfterTransaction']),
      relatedOrderId: json['relatedOrderId']?.toString(),
      orderGroupId: json['orderGroupId']?.toString(),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class HeldTransactionModel extends HeldTransactionEntity {
  const HeldTransactionModel({
    required super.transactionId,
    required super.amount,
    required super.date,
    required super.orderId,
    required super.orderStatus,
    required super.reason,
  });

  factory HeldTransactionModel.fromJson(Map<String, dynamic> json) {
    return HeldTransactionModel(
      transactionId: json['transactionId']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      orderId: json['orderId']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
