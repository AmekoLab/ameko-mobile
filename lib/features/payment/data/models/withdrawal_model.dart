import 'package:ameko_app/features/payment/domain/entities/withdrawal_entity.dart';

class WithdrawalModel extends WithdrawalEntity {
  const WithdrawalModel({
    required super.id,
    required super.amount,
    required super.bankName,
    required super.bankAccountNumber,
    required super.bankAccountName,
    required super.status,
    required super.createdAt,
    super.note,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bankName: json['bankName']?.toString() ?? '',
      bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
      bankAccountName: json['bankAccountName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountName': bankAccountName,
    };
  }
}
