// lib/data/models/auth_models.dart
class LoginRequest {
  final String identifier;
  final String password;
  LoginRequest({required this.identifier, required this.password});
  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
      };
}
class RegisterRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String role;
  final String birthday;
  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.role,
    required this.birthday,
  });
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
        'birthday': birthday, // Format: YYYY-MM-DD
      };
}
