import 'package:dartz/dartz.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';

abstract class PaymentRepository {
  /// Checkout with VNPAY — returns a paymentUrl to open in WebView
  Future<Either<Failure, CheckoutResultEntity>> checkoutWithVnpay({
    required List<String> selectedOrderItemIds,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    String? shippingNote,
  });

  /// Checkout with Wallet — requires 6-digit PIN; returns success or failure
  Future<Either<Failure, CheckoutResultEntity>> checkoutWithWallet({
    required List<String> selectedOrderItemIds,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    required String walletPin,
    String? shippingNote,
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

  /// Request a VNPAY deposit link for topping up the wallet
  Future<Either<Failure, String>> deposit(double amount);
}
