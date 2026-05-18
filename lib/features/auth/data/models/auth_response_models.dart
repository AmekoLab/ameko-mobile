import 'package:ameko_app/features/auth/data/models/user_model.dart';

class LoginResponseModel {
  final bool success;
  final String message;
  final LoginDataModel? data;
  final dynamic errors;

  LoginResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? LoginDataModel.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }
}

class LoginDataModel {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String role;
  final String token;
  final String refreshToken;

  LoginDataModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
    required this.token,
    required this.refreshToken,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(
      id: (json['id'] ?? json['userId'] ?? json['sub'] ?? '').toString(),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      role: json['role'] as String? ?? '',
      token: (json['token'] ?? json['accessToken'] ?? json['idToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? json['refresh_token'] ?? '').toString(),
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      role: role,
      token: token,
    );
  }
}

class ProfileResponseModel {
  final bool success;
  final String message;
  final UserModel? data;
  final dynamic errors;

  ProfileResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? UserModel.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }
}
