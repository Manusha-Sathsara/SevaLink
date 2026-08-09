import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
class AuthRepository {
  final DioClient _dioClient;
  AuthRepository(this._dioClient);
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );
      return response.data['data']; // Returns { accessToken, refreshToken, user }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<void> resetPassword(String pin, String newPassword) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': pin,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<User> getCurrentUser() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.me);
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiEndpoints.logout);
    } on DioException {
      // Ignore network errors on logout
    }
  }

  String _handleError(DioException e) {
    // Server responded with an error (4xx / 5xx)
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Server error (${e.response?.statusCode}). Please try again.';
    }
    // No response — network-level error
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Cannot connect to server. Make sure the backend is running.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      default:
        return 'Network error: ${e.message ?? 'Unknown error'}. Please try again.';
    }
  }
}
