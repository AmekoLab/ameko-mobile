import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class FetchWallet extends WalletEvent {}

class FetchTransactions extends WalletEvent {}

class CheckPinStatus extends WalletEvent {}

class SetupPin extends WalletEvent {
  final String pin;
  const SetupPin(this.pin);
  @override
  List<Object?> get props => [pin];
}

class RequestDeposit extends WalletEvent {
  final double amount;
  const RequestDeposit(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ResetWalletStatus extends WalletEvent {}
