import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/payment/data/models/checkout_result_model.dart';
import 'package:ameko_app/features/payment/data/models/wallet_model.dart';
import 'package:ameko_app/features/payment/data/models/wallet_transaction_model.dart';
import 'package:ameko_app/features/payment/data/models/transaction_model.dart';
import 'package:ameko_app/features/payment/domain/entities/checkout_result_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/voucher_entity.dart';
import 'package:ameko_app/features/payment/domain/entities/withdrawal_entity.dart';
import 'package:ameko_app/features/payment/data/models/voucher_model.dart';
import 'package:ameko_app/features/payment/data/models/withdrawal_model.dart';
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
      final response = await _dio.get('/api/v1/wallet');
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
      final response = await _dio.get('/api/v1/wallet/transactions');
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
      final response = await _dio.get('/api/v1/wallet/pin/status');
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
        '/api/v1/wallet/pin/setup',
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
  Future<Either<Failure, bool>> changePin({
    required String oldPin,
    required String newPin,
    required String confirmNewPin,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/wallet/pin/change',
        data: {
          'oldPin': oldPin,
          'newPin': newPin,
          'confirmNewPin': confirmNewPin,
        },
      );
      return Right(response.data['success'] == true);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('changePin error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestPinReset() async {
    try {
      final response = await _dio.post(
        '/api/v1/wallet/pin/forgot',
        data: {},
      );
      return Right(response.data['success'] == true);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('requestPinReset error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPinWithOtp({
    required String otp,
    required String newPin,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/wallet/pin/reset',
        data: {
          'otp': otp,
          'newPin': newPin,
        },
      );
      return Right(response.data['success'] == true);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('resetPinWithOtp error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestWithdrawal({
    required double amount,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/withdrawals',
        data: {
          'amount': amount,
          'bankName': bankName,
          'bankAccountNumber': bankAccountNumber,
          'bankAccountName': bankAccountName,
        },
      );
      final success = response.data['success'] == true;
      if (!success) {
        final msg = response.data['message']?.toString() ?? 'Rút tiền thất bại';
        return Left(ServerFailure(message: msg));
      }
      return const Right(true);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('requestWithdrawal error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WithdrawalEntity>>> getMyWithdrawals({
    int pageIndex = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/withdrawals/my',
        queryParameters: {
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
      );
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return Right(data.map((e) => WithdrawalModel.fromJson(e)).toList());
      }
      return const Right([]);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getMyWithdrawals error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HeldTransactionEntity>>> getHeldTransactions() async {
    try {
      final response = await _dio.get('/api/v1/wallet/held-transactions');
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        final list = data
            .map((e) => HeldTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return const Right([]);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getHeldTransactions error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedTransactionsEntity>> getPaginatedTransactions({
    int? type,
    int? status,
    String? fromDate,
    String? toDate,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    bool isAscending = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
        'IsAscending': isAscending.toString(),
      };
      if (type != null) queryParams['Type'] = type.toString();
      if (status != null) queryParams['Status'] = status.toString();
      if (fromDate != null) queryParams['FromDate'] = fromDate;
      if (toDate != null) queryParams['ToDate'] = toDate;
      if (sortBy != null) queryParams['SortBy'] = sortBy;

      final response = await _dio.get(
        '/api/v1/Wallet/transactions',
        queryParameters: queryParams,
      );
      final data = response.data['data'] ?? response.data;
      final items = (data['items'] as List? ?? [])
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(PaginatedTransactionsEntity(
        items: items,
        totalCount: data['totalCount'] as int? ?? 0,
        currentPage: data['currentPage'] as int? ?? 1,
        pageSize: data['pageSize'] as int? ?? pageSize,
        totalPages: data['totalPages'] as int? ?? 1,
        hasPreviousPage: data['hasPreviousPage'] as bool? ?? false,
        hasNextPage: data['hasNextPage'] as bool? ?? false,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getPaginatedTransactions error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionDetailEntity>> getTransactionDetail(
      String transactionId) async {
    try {
      final response =
          await _dio.get('/api/v1/Wallet/transactions/$transactionId');
      final data = response.data['data'] ?? response.data;
      return Right(TransactionDetailModel.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      appLogger.e('getTransactionDetail error: $e');
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deposit(double amount) async {
    try {
      final response = await _dio.post(
        '/api/v1/wallet/deposit/mobile',
        data: {
          'amount': amount,
          'successUrl': 'ameko://payment/success',
          'cancelUrl': 'ameko://payment/cancel',
        },
      );
      final data = response.data['data'] ?? response.data;
      final url = data['url']?.toString() ?? '';
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
      
      // If server provides a message, we can show it, but for any other case, use generic
      final data = response.data;
      if (data is Map) {
        final msg = data['message'] ?? data['msg'] ?? data['error'];
        if (msg != null) return ServerFailure(message: msg.toString());
      }
      return const ServerFailure();
    }
    
    return const UnknownFailure();
  }
}
