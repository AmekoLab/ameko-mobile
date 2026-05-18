import 'package:dartz/dartz.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/voucher_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/withdrawal_entity.dart';

abstract class PaymentRepository {
  /// Checkout with VNPAY — returns a paymentUrl to open in WebView
  Future<Either<Failure, CheckoutResultEntity>> checkoutWithVnpay({
    required List<String> selectedOrderItemIds,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    String? shippingNote,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
  });

  /// Checkout with Wallet — requires 6-digit PIN; returns success or failure
  Future<Either<Failure, CheckoutResultEntity>> checkoutWithWallet({
    required List<String> selectedOrderItemIds,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    required String walletPin,
    String? shippingNote,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
  });

  /// Called after WebView redirect; sends all vnp_* query params for server-side verification
  Future<Either<Failure, bool>> confirmVnpay(Map<String, String> queryParams);

  /// Get current wallet info (balance, currency)
  Future<Either<Failure, WalletEntity>> getWallet();

  /// Get wallet transaction history
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions();

  /// Check whether the user has set up a wallet PIN
  Future<Either<Failure, bool>> checkPinStatus();

  /// Set up a new wallet PIN (first time)
  Future<Either<Failure, bool>> setupPin(String pin);

  /// Change existing wallet PIN
  Future<Either<Failure, bool>> changePin({
    required String oldPin,
    required String newPin,
    required String confirmNewPin,
  });

  /// Request OTP to reset PIN via email
  Future<Either<Failure, bool>> requestPinReset();

  /// Reset PIN using OTP received by email
  Future<Either<Failure, bool>> resetPinWithOtp({
    required String otp,
    required String newPin,
  });

  /// Withdraw from wallet to linked bank account
  Future<Either<Failure, bool>> requestWithdrawal({
    required double amount,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  });

  /// Get current user's withdrawal history
  Future<Either<Failure, List<WithdrawalEntity>>> getMyWithdrawals({
    int pageIndex = 1,
    int pageSize = 20,
  });

  /// Get held (frozen) transactions
  Future<Either<Failure, List<HeldTransactionEntity>>> getHeldTransactions();

  /// Get paginated transaction list with filters
  Future<Either<Failure, PaginatedTransactionsEntity>> getPaginatedTransactions({
    int? type,
    int? status,
    String? fromDate,
    String? toDate,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    bool isAscending = false,
  });

  /// Get full detail for a single transaction
  Future<Either<Failure, TransactionDetailEntity>> getTransactionDetail(String transactionId);

  /// Request a VNPAY deposit link for topping up the wallet
  Future<Either<Failure, String>> deposit(double amount);

  /// Get applicable vouchers for the current cart/checkout
  Future<Either<Failure, ApplicableVoucherResponseEntity>> getApplicableVouchers();

  /// Calculate preview prices with vouchers
  Future<Either<Failure, CalculatePreviewResponseEntity>> calculatePreview({
    required List<String> selectedOrderItemIds,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
  });
}
