import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ameko_app/core/services/storage_service.dart';
import 'package:ameko_app/core/utils/app_logger.dart';

/// Configured Dio HTTP client with interceptors and timeout settings.
class DioClient {
  final Dio _dio;

  DioClient(StorageService storageService)
      : _dio = Dio(
          BaseOptions(
            baseUrl: dotenv.env['BASE_URL'] ?? 'https://localhost:5001/',
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(DioInterceptor(storageService));
  }

  Dio get dio => _dio;
}

/// Interceptor: attaches auth token, logs requests, handles errors globally.
class DioInterceptor extends Interceptor {
  final StorageService _storageService;
  static const int _maxRetries = 2;

  DioInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    appLogger.d(
      '→ ${options.method} ${options.uri}\n'
      'Headers: ${options.headers}\n'
      'Body: ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.d(
      '← ${response.statusCode} ${response.requestOptions.uri}\n'
      'Body: ${response.data}',
    );
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      appLogger.w('Unauthorized access (401) - session may be expired');
    }

    appLogger.e(
      '✗ ${err.response?.statusCode} ${err.requestOptions.uri}',
      error: err,
    );

    // Retry on network failure
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] as int? ?? 0;

    if (_shouldRetry(err) && retryCount < _maxRetries) {
      options.extra['retryCount'] = retryCount + 1;
      appLogger.w('Retrying request (${retryCount + 1}/$_maxRetries)');
      try {
        final retryDio = Dio(BaseOptions(
          baseUrl: options.baseUrl,
          connectTimeout: options.connectTimeout,
          sendTimeout: options.sendTimeout,
          receiveTimeout: options.receiveTimeout,
          headers: options.headers,
        ));
        final response = await retryDio.fetch(options);
        handler.resolve(response);
        return;
      } catch (_) {
        // Fall through to error handler
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }
}
