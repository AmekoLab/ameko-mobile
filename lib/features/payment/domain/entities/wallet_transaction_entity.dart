import 'package:equatable/equatable.dart';

class WalletTransactionEntity extends Equatable {
  final String id;
  final String type; // 'Deposit', 'Payment', 'Refund', etc.
  final double amount;
  final String? description;
  final DateTime createdAt;
  final String status;

  const WalletTransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
    required this.status,
  });

  bool get isCredit => type == 'Deposit' || type == 'Refund';

  @override
  List<Object?> get props => [id, type, amount, createdAt, status];
}
