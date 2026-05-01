import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/services/storage_service.dart';
import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/auth/domain/entities/user_entity.dart';
import 'package:ameko_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ameko_app/core/services/chat_service.dart';
import 'package:ameko_app/features/social/data/services/social_signalr_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;
  final ChatService _chatService;
  final SocialSignalRService _socialService;

  AuthBloc({
    required AuthRepository repository,
    required StorageService storage,
    required ChatService chatService,
    required SocialSignalRService socialService,
  })  : _repository = repository,
        _storage = storage,
        _chatService = chatService,
        _socialService = socialService,
        super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<LoggedOut>(_onLoggedOut);
    on<ProfileFetchRequested>(_onProfileFetchRequested);
  }

  Future<void> _initRealtime(String? token) async {
    final chatHubUrl = dotenv.env['CHAT_HUB_URL'];
    final baseUrl = dotenv.env['BASE_URL'];
    final socialHubUrl = dotenv.env['SOCIAL_HUB_URL'] ?? 
        (baseUrl != null ? baseUrl.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://') + 'hub' : null);

    if (chatHubUrl != null) {
      _chatService.connect(chatHubUrl, token: token);
    }
    
    if (socialHubUrl != null) {
      _socialService.connect(socialHubUrl, token: token);
    }
  }

  /// Check token on app start → auto-login if token exists.
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final hasToken = await _storage.hasToken();
      if (hasToken) {
        final userJson = _storage.getUser();
        if (userJson != null) {
          final user = UserEntity.fromJson(userJson);
          appLogger.i('AppStarted: restoring session for ${user.username}');
          
          final token = await _storage.getToken();
          _initRealtime(token); // Connect SignalR
          
          emit(AuthSuccess(user: user));
          return;
        }
      }
      appLogger.d('AppStarted: no active session');
      emit(const AuthInitial());
    } catch (e) {
      appLogger.e('AppStarted error', error: e);
      emit(const AuthInitial());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.login(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) {
        appLogger.w('Login failed: ${failure.message}');
        emit(AuthFailure(message: failure.message));
      },
      (user) {
        appLogger.i('Login success: ${user.username}');
        
        _storage.getToken().then((token) => _initRealtime(token)); // Connect SignalR
        
        emit(AuthSuccess(user: user));
      },
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.register(
      name: event.name,
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.forgotPassword(email: event.email);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (message) => emit(AuthActionSuccess(message: message)),
    );
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.resetPassword(
      email: event.email,
      code: event.code,
      newPassword: event.newPassword,
      confirmPassword: event.confirmPassword,
    );
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (message) => emit(AuthActionSuccess(message: message)),
    );
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.verifyOtp(otp: event.otp);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (_) => emit(const AuthActionSuccess(message: 'OTP verified successfully.')),
    );
  }

  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _chatService.disconnect();
    await _socialService.disconnect();
    final result = await _repository.logout();
    appLogger.i('User logged out');
    
    result.fold(
      (failure) => emit(const AuthInitial()), // If somehow logout fails, still go to Initial
      (message) {
        emit(AuthActionSuccess(message: message));
        emit(const AuthInitial());
      },
    );
  }

  Future<void> _onProfileFetchRequested(
    ProfileFetchRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _storage.getToken();
    final userJson = _storage.getUser();

    if (token != null && userJson != null) {
      final id = userJson['id'] ?? '';
      
      final result = await _repository.getProfile(id: id, token: token);
      
      result.fold(
        (failure) {
          appLogger.w('Profile refresh failed: ${failure.message}');
          // Stay on current state
        },
        (user) {
          appLogger.i('Profile refreshed for: ${user.username}');
          emit(AuthSuccess(user: user));
        },
      );
    }
  }
}
