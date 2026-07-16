import 'dart:io' show Platform;

class ApiEndpoints {
  static String get baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://172.20.10.8:8080/api';
      }
    } catch (e) {
      // Web or other platforms
      return 'http://localhost:8080/api';
    }
    return 'http://172.20.10.8:8080/api';
  }

  static String get clientDashboard => '$baseUrl/client-dashboard';
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get refreshToken => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';


}