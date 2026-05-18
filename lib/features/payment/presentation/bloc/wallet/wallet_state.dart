import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/withdrawal_entity.dart';

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

/// Main loaded state — wallet + paginated transactions
class WalletLoaded extends WalletState {
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;
  final PaginatedTransactionsEntity? paginatedTransactions;
  final List<HeldTransactionEntity> heldTransactions;
  final List<WithdrawalEntity> withdrawals;
  final bool isLoadingMore;

  const WalletLoaded({
    required this.wallet,
    this.transactions = const [],
    this.paginatedTransactions,
    this.heldTransactions = const [],
    this.withdrawals = const [],
    this.isLoadingMore = false,
  });

  WalletLoaded copyWith({
    WalletEntity? wallet,
    List<WalletTransactionEntity>? transactions,
    PaginatedTransactionsEntity? paginatedTransactions,
    List<HeldTransactionEntity>? heldTransactions,
    List<WithdrawalEntity>? withdrawals,
    bool? isLoadingMore,
  }) {
    return WalletLoaded(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      paginatedTransactions: paginatedTransactions ?? this.paginatedTransactions,
      heldTransactions: heldTransactions ?? this.heldTransactions,
      withdrawals: withdrawals ?? this.withdrawals,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [wallet, transactions, paginatedTransactions, heldTransactions, withdrawals, isLoadingMore];
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

class PinChangedSuccess extends WalletState {
  const PinChangedSuccess();
}

class PinResetRequested extends WalletState {
  const PinResetRequested();
}

class PinResetSuccess extends WalletState {
  const PinResetSuccess();
}

class WithdrawalSuccess extends WalletState {
  const WithdrawalSuccess();
}

class WithdrawalsLoaded extends WalletState {
  final List<WithdrawalEntity> withdrawals;
  const WithdrawalsLoaded(this.withdrawals);

  @override
  List<Object?> get props => [withdrawals];
}

class TransactionDetailLoaded extends WalletState {
  final TransactionDetailEntity detail;
  const TransactionDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
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
