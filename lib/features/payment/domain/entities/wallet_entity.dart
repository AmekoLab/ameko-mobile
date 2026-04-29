import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String id;
  final double balance;
  final String currency;

  const WalletEntity({
    required this.id,
    required this.balance,
    this.currency = 'VND',
  });

  @override
  List<Object?> get props => [id, balance, currency];
}
