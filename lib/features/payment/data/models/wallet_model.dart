import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.balance,
    super.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return WalletModel(
      id: data['id']?.toString() ?? '',
      balance: _parseDouble(data['balance']),
      currency: data['currency']?.toString() ?? 'VND',
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
