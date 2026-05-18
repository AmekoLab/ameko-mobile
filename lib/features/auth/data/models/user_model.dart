import 'package:ameko_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    super.fullName,
    super.firstName,
    super.lastName,
    super.role,
    super.token,
    super.gender,
    super.dateOfBirth,
    super.phoneNumber,
    super.image,
    super.storeAddress,
    super.storeDescription,
    super.banner,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      role: json['role'] as String?,
      token: json['token'] as String?,
      gender: json['gender'] as int?,
      dateOfBirth: json['dateOfBirth'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      image: json['image'] as String?,
      storeAddress: json['storeAddress'] as String?,
      storeDescription: json['storeDescription'] as String?,
      banner: json['banner'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'token': token,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'phoneNumber': phoneNumber,
        'image': image,
        'storeAddress': storeAddress,
        'storeDescription': storeDescription,
        'banner': banner,
      };
}
