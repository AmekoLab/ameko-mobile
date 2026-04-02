import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ameko_app/core/network/dio_client.dart';
import 'package:ameko_app/core/services/chat_service.dart';
import 'package:ameko_app/core/services/connectivity_service.dart';
import 'package:ameko_app/core/services/storage_service.dart';
import 'package:ameko_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ameko_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/order/data/repositories/order_repository_impl.dart';
import 'package:ameko_app/features/order/domain/repositories/order_repository.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_bloc.dart';
import 'package:ameko_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:ameko_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_detail_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── External ─────────────────────────────────────────────────────────────
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerSingleton<Connectivity>(Connectivity());

  // ─── Core Services ────────────────────────────────────────────────────────
  final storageService = StorageService(sl<FlutterSecureStorage>());
  await storageService.init();
  sl.registerSingleton<StorageService>(storageService);

  sl.registerSingleton<ConnectivityService>(
    ConnectivityService(sl<Connectivity>()),
  );

  sl.registerSingleton<ChatService>(ChatService());

  // ─── Network ──────────────────────────────────────────────────────────────
  final dio = Dio(
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
  );
  dio.interceptors.add(DioInterceptor(storageService));
  
  // Bypass SSL for Dev (handle Self-signed certificates)
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return client;
  };
  
  sl.registerSingleton<Dio>(dio);

  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(storageService, dio),
  );

  sl.registerSingleton<OrderRepository>(
    OrderRepositoryImpl(dio),
  );

  sl.registerSingleton<ChatRepository>(
    ChatRepositoryImpl(dio),
  );

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      repository: sl<AuthRepository>(),
      storage: sl<StorageService>(),
    ),
  );

  sl.registerFactory<OrderBloc>(
    () => OrderBloc(
      repository: sl<OrderRepository>(),
    ),
  );

  sl.registerFactory<ChatListBloc>(
    () => ChatListBloc(repository: sl<ChatRepository>()),
  );

  sl.registerFactory<ChatDetailBloc>(
    () => ChatDetailBloc(repository: sl<ChatRepository>()),
  );
}
