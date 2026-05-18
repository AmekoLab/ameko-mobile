import 'package:equatable/equatable.dart';

class WithdrawalEntity extends Equatable {
  final String id;
  final double amount;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final String status; // Pending, Completed, Rejected
  final DateTime createdAt;
  final String? note;

  const WithdrawalEntity({
    required this.id,
    required this.amount,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.status,
    required this.createdAt,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        amount,
        bankName,
        bankAccountNumber,
        bankAccountName,
        status,
        createdAt,
        note,
      ];
}
