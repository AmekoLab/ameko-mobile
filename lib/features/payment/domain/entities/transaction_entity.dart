import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String transactionCode;
  final double amount;
  final double grossAmount;
  final double feeAmount;
  final double netAmount;
  final String flowDirection; // "In", "Out", "Held"
  final String currency;
  final String type;
  final String status;
  final String? description;
  final double balanceAfterTransaction;
  final String? shopName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.transactionCode,
    required this.amount,
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.flowDirection,
    required this.currency,
    required this.type,
    required this.status,
    this.description,
    required this.balanceAfterTransaction,
    this.shopName,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    required this.createdAt,
  });

  bool get isCredit => flowDirection == 'In';
  bool get isHeld => flowDirection == 'Held';

  @override
  List<Object?> get props => [id, transactionCode, flowDirection, amount, createdAt, status];
}

class TransactionDetailEntity extends TransactionEntity {
  final double balanceBeforeTransaction;
  final double heldBalanceBeforeTransaction;
  final double heldBalanceAfterTransaction;
  final String? relatedOrderId;
  final String? orderGroupId;

  const TransactionDetailEntity({
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
    required this.balanceBeforeTransaction,
    required this.heldBalanceBeforeTransaction,
    required this.heldBalanceAfterTransaction,
    this.relatedOrderId,
    this.orderGroupId,
  });
}

class PaginatedTransactionsEntity extends Equatable {
  final List<TransactionEntity> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const PaginatedTransactionsEntity({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  @override
  List<Object?> get props => [items, totalCount, currentPage, pageSize];
}

class HeldTransactionEntity extends Equatable {
  final String transactionId;
  final double amount;
  final DateTime date;
  final String orderId;
  final String orderStatus;
  final String reason;

  const HeldTransactionEntity({
    required this.transactionId,
    required this.amount,
    required this.date,
    required this.orderId,
    required this.orderStatus,
    required this.reason,
  });

  @override
  List<Object?> get props => [transactionId, orderId, amount];
}
