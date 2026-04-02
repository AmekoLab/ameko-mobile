import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? role;
  final String? token;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.role,
    this.token,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role,
        'token': token,
      };

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String?,
        role: json['role'] as String?,
        token: json['token'] as String?,
      );

  @override
  List<Object?> get props => [id, username, email, fullName, role, token];
}
