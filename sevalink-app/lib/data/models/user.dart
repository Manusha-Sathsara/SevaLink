// lib/data/models/user.dart
import 'package:equatable/equatable.dart';
class User extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
    );
  }
  @override
  List<Object?> get props => [id, fullName, email, phoneNumber, role];
}
