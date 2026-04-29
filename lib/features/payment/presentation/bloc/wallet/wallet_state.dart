import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;

  const WalletLoaded({
    required this.wallet,
    this.transactions = const [],
  });

  WalletLoaded copyWith({
    WalletEntity? wallet,
    List<WalletTransactionEntity>? transactions,
  }) {
    return WalletLoaded(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  List<Object?> get props => [wallet, transactions];
}

class PinStatusChecked extends WalletState {
  final bool hasPin;
  const PinStatusChecked(this.hasPin);

  @override
  List<Object?> get props => [hasPin];
}

class PinSetupSuccess extends WalletState {
  const PinSetupSuccess();
}

/// Deposit link ready — open WebView
class DepositReady extends WalletState {
  final String paymentUrl;
  const DepositReady(this.paymentUrl);

  @override
  List<Object?> get props => [paymentUrl];
}

class WalletFailure extends WalletState {
  final String message;
  const WalletFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletActionSuccess extends WalletState {
  final String message;
  const WalletActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
