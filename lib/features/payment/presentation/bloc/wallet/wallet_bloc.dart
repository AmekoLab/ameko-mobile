import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final PaymentRepository _repository;

  WalletBloc({required PaymentRepository repository})
      : _repository = repository,
        super(const WalletInitial()) {
    on<FetchWallet>(_onFetchWallet);
    on<FetchTransactions>(_onFetchTransactions);
    on<CheckPinStatus>(_onCheckPinStatus);
    on<SetupPin>(_onSetupPin);
    on<RequestDeposit>(_onRequestDeposit);
    on<ResetWalletStatus>((_, emit) => emit(const WalletInitial()));
  }

  Future<void> _onFetchWallet(
    FetchWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.getWallet();
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (wallet) => emit(WalletLoaded(wallet: wallet)),
    );
  }

  Future<void> _onFetchTransactions(
    FetchTransactions event,
    Emitter<WalletState> emit,
  ) async {
    // Keep current wallet info while loading transactions
    final currentWallet = state is WalletLoaded
        ? (state as WalletLoaded).wallet
        : null;

    if (currentWallet == null) {
      emit(const WalletLoading());
    }

    final walletResult = currentWallet != null
        ? null
        : await _repository.getWallet();

    final wallet = currentWallet ??
        walletResult?.fold((f) => null, (w) => w);

    if (wallet == null) {
      emit(const WalletFailure('Không thể tải thông tin ví'));
      return;
    }

    final txResult = await _repository.getTransactions();
    txResult.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (txList) => emit(WalletLoaded(wallet: wallet, transactions: txList)),
    );
  }

  Future<void> _onCheckPinStatus(
    CheckPinStatus event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.checkPinStatus();
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (hasPin) => emit(PinStatusChecked(hasPin)),
    );
  }

  Future<void> _onSetupPin(
    SetupPin event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.setupPin(event.pin);
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (success) => emit(const PinSetupSuccess()),
    );
  }

  Future<void> _onRequestDeposit(
    RequestDeposit event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.deposit(event.amount);
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (url) => emit(DepositReady(url)),
    );
  }
}
