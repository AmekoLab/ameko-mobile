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
    on<SendOtpRequested>(_onSendOtpRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
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
          _initRealtime(token);
          
          emit(AuthSuccess(user: user));
          return;
        }
      }
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
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) {
        _storage.getToken().then((token) => _initRealtime(token));
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
      username: event.username,
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );

    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (user) async {
        // Step 2: Send activation code
        final otpResult = await _repository.sendActivationCode(event.email);
        otpResult.fold(
          (failure) => emit(AuthFailure(message: 'Tài khoản đã tạo nhưng không gửi được mã kích hoạt: ${failure.message}')),
          (_) => emit(const AuthActionSuccess(message: 'Đăng ký thành công. Vui lòng kiểm tra mã OTP trong email.')),
        );
      },
    );
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.sendActivationCode(event.email);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (_) => emit(const AuthActionSuccess(message: 'Mã OTP đã được gửi lại.')),
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
      (_) => emit(const AuthActionSuccess(message: 'Yêu cầu đặt lại mật khẩu đã được gửi.')),
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
      (_) => emit(const AuthActionSuccess(message: 'Đặt lại mật khẩu thành công.')),
    );
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.verifyOtp(email: event.email, code: event.code);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (_) => emit(const AuthActionSuccess(message: 'Xác thực OTP thành công. Vui lòng đăng nhập.')),
    );
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthSuccess) {
      emit(const AuthLoading());
      final result = await _repository.updateProfile(
        userId: currentState.user.id,
        firstName: event.firstName,
        lastName: event.lastName,
        gender: event.gender,
        dateOfBirth: event.dateOfBirth,
        phoneNumber: event.phoneNumber,
        image: event.image,
        storeAddress: event.storeAddress,
        storeDescription: event.storeDescription,
        banner: event.banner,
      );
      result.fold(
        (failure) => emit(AuthFailure(message: failure.message)),
        (user) => emit(AuthSuccess(user: user)),
      );
    }
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthSuccess) {
      emit(const AuthLoading());
      final result = await _repository.changePassword(
        userId: currentState.user.id,
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
        confirmNewPassword: event.confirmNewPassword,
      );
      result.fold(
        (failure) => emit(AuthFailure(message: failure.message)),
        (_) => emit(const AuthActionSuccess(message: 'Đổi mật khẩu thành công.')),
      );
    }
  }

  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _chatService.disconnect();
    await _socialService.disconnect();
    await _repository.logout();
    emit(const AuthInitial());
  }

  Future<void> _onProfileFetchRequested(
    ProfileFetchRequested event,
    Emitter<AuthState> emit,
  ) async {
    final userJson = _storage.getUser();
    if (userJson != null) {
      final id = userJson['id'] ?? '';
      final result = await _repository.getProfile(id: id);
      result.fold(
        (failure) => appLogger.w('Profile refresh failed: ${failure.message}'),
        (user) => emit(AuthSuccess(user: user)),
      );
    }
  }
}
