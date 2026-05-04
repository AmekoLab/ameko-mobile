import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';
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
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<CheckPinStatus>(_onCheckPinStatus);
    on<SetupPin>(_onSetupPin);
    on<ChangePinEvent>(_onChangePin);
    on<RequestPinResetEvent>(_onRequestPinReset);
    on<ResetPinWithOtpEvent>(_onResetPinWithOtp);
    on<RequestWithdrawalEvent>(_onRequestWithdrawal);
    on<FetchWithdrawals>(_onFetchWithdrawals);
    on<FetchHeldTransactions>(_onFetchHeldTransactions);
    on<FetchTransactionDetail>(_onFetchTransactionDetail);
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
    final currentWallet = state is WalletLoaded ? (state as WalletLoaded).wallet : null;
    if (currentWallet == null) {
      emit(const WalletLoading());
    }

    final walletResult = currentWallet != null ? null : await _repository.getWallet();
    final wallet = currentWallet ?? walletResult?.fold((f) => null, (w) => w);

    if (wallet == null) {
      emit(const WalletFailure('Không thể tải thông tin ví'));
      return;
    }

    final txResult = await _repository.getPaginatedTransactions(
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
    );

    txResult.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (paginatedTx) => emit(WalletLoaded(
        wallet: wallet,
        paginatedTransactions: paginatedTx,
      )),
    );
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;
    final current = state as WalletLoaded;
    final paginated = current.paginatedTransactions;
    if (paginated == null || !paginated.hasNextPage) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _repository.getPaginatedTransactions(
      pageNumber: paginated.currentPage + 1,
    );

    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (newPage) {
        final combined = PaginatedTransactionsEntity(
          items: [...paginated.items, ...newPage.items],
          totalCount: newPage.totalCount,
          currentPage: newPage.currentPage,
          pageSize: newPage.pageSize,
          totalPages: newPage.totalPages,
          hasPreviousPage: newPage.hasPreviousPage,
          hasNextPage: newPage.hasNextPage,
        );
        emit(current.copyWith(paginatedTransactions: combined, isLoadingMore: false));
      },
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

  Future<void> _onChangePin(
    ChangePinEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.changePin(
      oldPin: event.oldPin,
      newPin: event.newPin,
      confirmNewPin: event.confirmNewPin,
    );
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (success) => emit(const PinChangedSuccess()),
    );
  }

  Future<void> _onRequestPinReset(
    RequestPinResetEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.requestPinReset();
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (success) => emit(const PinResetRequested()),
    );
  }

  Future<void> _onResetPinWithOtp(
    ResetPinWithOtpEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.resetPinWithOtp(
      otp: event.otp,
      newPin: event.newPin,
    );
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (success) => emit(const PinResetSuccess()),
    );
  }

  Future<void> _onRequestWithdrawal(
    RequestWithdrawalEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.requestWithdrawal(
      amount: event.amount,
      bankName: event.bankName,
      bankAccountNumber: event.bankAccountNumber,
      bankAccountName: event.bankAccountName,
    );
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (success) => emit(const WithdrawalSuccess()),
    );
  }

  Future<void> _onFetchWithdrawals(
    FetchWithdrawals event,
    Emitter<WalletState> emit,
  ) async {
    final current = state is WalletLoaded ? state as WalletLoaded : null;
    if (current == null) {
      emit(const WalletLoading());
    }

    final result = await _repository.getMyWithdrawals(
      pageIndex: event.pageIndex,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (withdrawals) {
        if (current != null) {
          emit(current.copyWith(withdrawals: withdrawals));
        } else {
          // If wallet info not yet loaded, we might need to fetch it first or just emit WithdrawalsLoaded
          // But for consistency with Dashboard, we prefer WalletLoaded.
          // For now, let's just emit WithdrawalsLoaded as a fallback.
          emit(WithdrawalsLoaded(withdrawals));
        }
      },
    );
  }

  Future<void> _onFetchHeldTransactions(
    FetchHeldTransactions event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;
    final current = state as WalletLoaded;
    final result = await _repository.getHeldTransactions();
    result.fold(
      (failure) => null, // silently fail — don't override main state
      (held) => emit(current.copyWith(heldTransactions: held)),
    );
  }

  Future<void> _onFetchTransactionDetail(
    FetchTransactionDetail event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _repository.getTransactionDetail(event.transactionId);
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (detail) => emit(TransactionDetailLoaded(detail)),
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
