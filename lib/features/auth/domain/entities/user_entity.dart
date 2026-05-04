import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? token;
  final int? gender;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? image;
  final String? storeAddress;
  final String? storeDescription;
  final String? banner;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.role,
    this.token,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.image,
    this.storeAddress,
    this.storeDescription,
    this.banner,
  });

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

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
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

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        firstName,
        lastName,
        role,
        token,
        gender,
        dateOfBirth,
        phoneNumber,
        image,
        storeAddress,
        storeDescription,
        banner,
      ];
}
