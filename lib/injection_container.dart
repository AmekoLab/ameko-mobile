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
import 'package:ameko_app/features/assembled_product/data/repositories/assembled_product_repository_impl.dart';
import 'package:ameko_app/features/assembled_product/domain/repositories/assembled_product_repository.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_bloc.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_search_bloc.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_search_event.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_search_state.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_detail_bloc.dart';
import 'package:ameko_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:ameko_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:ameko_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:ameko_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/social/data/repositories/social_repository_impl.dart';
import 'package:ameko_app/features/social/domain/repositories/social_repository.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_bloc.dart';
import 'package:ameko_app/features/social/presentation/bloc/post_detail_bloc.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/data/services/social_signalr_service.dart';
import 'package:ameko_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:ameko_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:ameko_app/features/notification/data/services/notification_signalr_service.dart';
import 'package:ameko_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ameko_app/core/bloc/locale_bloc.dart';

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
  sl.registerSingleton<SocialSignalRService>(SocialSignalRService());
  sl.registerSingleton<NotificationSignalRService>(NotificationSignalRService());

  // ─── Network ──────────────────────────────────────────────────────────────
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? 'https://api.amekolab.online/',
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

  sl.registerSingleton<PaymentRepository>(
    PaymentRepositoryImpl(dio),
  );

  sl.registerSingleton<SocialRepository>(
    SocialRepositoryImpl(dio),
  );

  sl.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(dio),
  );

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      repository: sl<AuthRepository>(),
      storage: sl<StorageService>(),
      chatService: sl<ChatService>(),
      socialService: sl<SocialSignalRService>(),
    ),
  );

  sl.registerFactory<OrderBloc>(
    () => OrderBloc(
      repository: sl<OrderRepository>(),
    ),
  );

  sl.registerFactory<ChatListBloc>(
    () => ChatListBloc(
      repository: sl<ChatRepository>(),
      chatService: sl<ChatService>(),
    ),
  );

  sl.registerFactory<ChatDetailBloc>(
    () => ChatDetailBloc(
      repository: sl<ChatRepository>(),
      chatService: sl<ChatService>(),
    ),
  );

  sl.registerSingleton<AssembledProductRepository>(
    AssembledProductRepositoryImpl(dio),
  );

  sl.registerFactory<AssembledProductListBloc>(
    () => AssembledProductListBloc(repository: sl<AssembledProductRepository>()),
  );



  sl.registerFactory<AssembledProductDetailBloc>(
    () => AssembledProductDetailBloc(repository: sl<AssembledProductRepository>()),
  );

  sl.registerFactory<AssembledProductSearchBloc>(
    () => AssembledProductSearchBloc(repository: sl<AssembledProductRepository>()),
  );

  sl.registerSingleton<CartRepository>(
    CartRepositoryImpl(dio),
  );

  sl.registerFactory<CartBloc>(
    () => CartBloc(repository: sl<CartRepository>()),
  );

  sl.registerFactory<CheckoutBloc>(
    () => CheckoutBloc(repository: sl<PaymentRepository>()),
  );

  sl.registerFactory<WalletBloc>(
    () => WalletBloc(repository: sl<PaymentRepository>()),
  );

  sl.registerFactory<SocialFeedBloc>(
    () => SocialFeedBloc(repository: sl<SocialRepository>()),
  );

  sl.registerFactoryParam<PostDetailBloc, PostModel?, void>(
    (post, _) => PostDetailBloc(repository: sl<SocialRepository>(), initialPost: post),
  );

  sl.registerFactory<LocaleBloc>(
    () => LocaleBloc(sl<StorageService>()),
  );

  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      repository: sl<NotificationRepository>(),
      signalRService: sl<NotificationSignalRService>(),
      storageService: sl<StorageService>(),
    ),
  );
}
