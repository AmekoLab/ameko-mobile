import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/payment/data/models/checkout_result_model.dart';
import 'package:ameko_app/features/payment/data/models/wallet_model.dart';
import 'package:ameko_app/features/payment/data/models/wallet_transaction_model.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/voucher_entity.dart';
import 'package:ameko_app/features/payment/data/models/voucher_model.dart';
import 'package:ameko_app/features/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final Dio _dio;

  PaymentRepositoryImpl(this._dio);

  // ─── Checkout ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CheckoutResultEntity>> checkoutWithVnpay({
    required List<String> selectedOrderItemIds,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    String? shippingNote,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
  }) async {
    try {
      // Step 1: Create Order
      // Use standard placeholders for Step 1 to avoid validation issues
      final checkoutResponse = await _dio.post('/api/v1/orders/checkout', data: {
        'selectedOrderItemIds': selectedOrderItemIds,
        'paymentMethod': 2, // VnPay
        'shippingAddress': shippingAddress,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'note': shippingNote ?? '',
        'appliedSystemVoucherCode': appliedSystemVoucherCode,
        'appliedShopVoucherCodes': appliedShopVoucherCodes ?? {},
        'items': [], // Backend expects this list
        'successUrl': 'https://ameko.vn/payment-success', // Placeholder
        'cancelUrl': 'https://ameko.vn/payment-cancel',
      });

      final responseData = checkoutResponse.data;
      final orderData = responseData['data'] ?? responseData;
      final orderGroupId = orderData['orderGroupId']?.toString();

      if (orderGroupId == null) {
        return Left(ServerFailure(message: 'Không tìm thấy OrderGroupId trong phản hồi từ server'));
      }

      // Step 2: Create VNPAY Session for Mobile
      final sessionResponse = await _dio.post(
        '/api/v1/Payment/create-vnpay-session-mobile',
        data: {
          'orderGroupId': orderGroupId,
          'successUrl': 'ameko://payment/callback?paid=1',
          'cancelUrl': 'ameko://payment/callback?paid=0',
        },
      );

      final result = CheckoutResultModel.fromJson(sessionResponse.data, 'VnPay');
      
      if (result.paymentUrl != null && result.paymentUrl!.isNotEmpty) {
        return Right(result);
      }
      return Left(ServerFailure(message: result.message ?? 'Không lấy được link thanh toán VNPAY'));
    } on DioException catch (e) {
      // Print the response body for debugging if possible
      appLogger.e('Dio Error Response: ${e.response?.data}');
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('checkoutWithVnpay error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CheckoutResultEntity>> checkoutWithWallet({
    required List<String> selectedOrderItemIds,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    required String walletPin,
    String? shippingNote,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
  }) async {
    try {
      final response = await _dio.post('/api/v1/orders/checkout', data: {
        'selectedOrderItemIds': selectedOrderItemIds,
        'paymentMethod': 1,
        'shippingAddress': shippingAddress,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'note': shippingNote,
        'walletPin': walletPin,
        'appliedSystemVoucherCode': appliedSystemVoucherCode,
        'appliedShopVoucherCodes': appliedShopVoucherCodes ?? {},
      });
      final result = CheckoutResultModel.fromJson(response.data, 'Wallet');
      if (result.isSuccess) {
        return Right(result);
      }
      return Left(ServerFailure(
          message: result.message ?? 'Thanh toán bằng ví thất bại'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('checkoutWithWallet error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── VNPAY Confirm ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> confirmVnpay(
      Map<String, String> queryParams) async {
    try {
      final response = await _dio.post(
        '/api/v1/payment/vnpay-confirm',
        data: queryParams,
      );
      final success = response.data['success'] == true;
      return Right(success);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('confirmVnpay error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, WalletEntity>> getWallet() async {
    try {
      final response = await _dio.get('/api/v1/wallets');
      return Right(WalletModel.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getWallet error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>>
      getTransactions() async {
    try {
      final response = await _dio.get('/api/v1/wallets/transactions');
      final data = response.data['data'];
      if (data is List) {
        final list = data
            .map((e) => WalletTransactionModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return const Right([]);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getTransactions error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkPinStatus() async {
    try {
      final response = await _dio.get('/api/v1/wallets/pin/status');
      final data = response.data['data'] ?? response.data;
      final hasPin = data['hasPin'] == true;
      return Right(hasPin);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('checkPinStatus error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setupPin(String pin) async {
    try {
      final response = await _dio.post(
        '/api/v1/wallets/pin/setup',
        data: {'pin': pin},
      );
      return Right(response.data['success'] == true);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('setupPin error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deposit(double amount) async {
    try {
      final response = await _dio.post(
        '/api/v1/wallets/deposit',
        data: {'amount': amount},
      );
      final data = response.data['data'] ?? response.data;
      final url = data['paymentUrl']?.toString() ?? '';
      if (url.isEmpty) {
        return Left(ServerFailure(
            message: response.data['message'] ?? 'Không lấy được link nạp tiền'));
      }
      return Right(url);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('deposit error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Vouchers ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ApplicableVoucherResponseEntity>> getApplicableVouchers() async {
    try {
      final response = await _dio.get('/api/v1/voucher/applicable');
      final data = response.data['data'] ?? response.data;
      final result = ApplicableVoucherResponseModel.fromJson(data);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getApplicableVouchers error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CalculatePreviewResponseEntity>> calculatePreview({
    required List<String> selectedOrderItemIds,
    String? appliedSystemVoucherCode,
    Map<String, String>? appliedShopVoucherCodes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/orders/calculate-preview',
        data: {
          'selectedOrderItemIds': selectedOrderItemIds,
          'appliedSystemVoucherCode': appliedSystemVoucherCode,
          'appliedShopVoucherCodes': appliedShopVoucherCodes ?? {},
        },
      );
      final data = response.data['data'] ?? response.data;
      final result = CalculatePreviewResponseModel.fromJson(data);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('calculatePreview error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Error Handling ───────────────────────────────────────────────────────

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NoInternetFailure();
    }
    final response = e.response;
    if (response != null) {
      if (response.statusCode == 401) return const UnauthorizedFailure();
      final data = response.data;
      if (data is Map) {
        final msg = data['message'] ?? data['msg'] ?? data['error'];
        if (msg != null) return ServerFailure(message: msg.toString());
      }
    }
    return UnknownFailure(message: e.message ?? 'Unknown error');
  }
}
