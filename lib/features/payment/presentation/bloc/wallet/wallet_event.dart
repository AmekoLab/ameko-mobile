import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class FetchWallet extends WalletEvent {}

class FetchTransactions extends WalletEvent {
  final int pageNumber;
  final int pageSize;
  const FetchTransactions({this.pageNumber = 1, this.pageSize = 20});
  @override
  List<Object?> get props => [pageNumber, pageSize];
}

class LoadMoreTransactions extends WalletEvent {}

class CheckPinStatus extends WalletEvent {}

class SetupPin extends WalletEvent {
  final String pin;
  const SetupPin(this.pin);
  @override
  List<Object?> get props => [pin];
}

class ChangePinEvent extends WalletEvent {
  final String oldPin;
  final String newPin;
  final String confirmNewPin;
  const ChangePinEvent({
    required this.oldPin,
    required this.newPin,
    required this.confirmNewPin,
  });
  @override
  List<Object?> get props => [oldPin];
}

class RequestPinResetEvent extends WalletEvent {}

class ResetPinWithOtpEvent extends WalletEvent {
  final String otp;
  final String newPin;
  const ResetPinWithOtpEvent({required this.otp, required this.newPin});
  @override
  List<Object?> get props => [otp];
}

class RequestWithdrawalEvent extends WalletEvent {
  final double amount;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  
  const RequestWithdrawalEvent({
    required this.amount,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
  });

  @override
  List<Object?> get props => [amount, bankName, bankAccountNumber, bankAccountName];
}

class FetchWithdrawals extends WalletEvent {
  final int pageIndex;
  final int pageSize;
  const FetchWithdrawals({this.pageIndex = 1, this.pageSize = 20});
  @override
  List<Object?> get props => [pageIndex, pageSize];
}

class FetchHeldTransactions extends WalletEvent {}

class FetchTransactionDetail extends WalletEvent {
  final String transactionId;
  const FetchTransactionDetail(this.transactionId);
  @override
  List<Object?> get props => [transactionId];
}

class RequestDeposit extends WalletEvent {
  final double amount;
  const RequestDeposit(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ResetWalletStatus extends WalletEvent {}
