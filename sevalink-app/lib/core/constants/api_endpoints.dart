import 'dart:io' show Platform;

enum ConnectionMode {
  emulator,      // Android Emulator (10.0.2.2)
  usbReverse,    // Physical device with USB port forwarding (localhost)
  wifi,          // Wireless debugging over Wi-Fi (uses _wifiIp below)
}

class ApiEndpoints {
  // SWITCH CONNECTION MODE HERE
  static const ConnectionMode mode = ConnectionMode.usbReverse;

  // Enter your PC's local IP address here if mode is ConnectionMode.wifi:
  static const String _wifiIp = '192.168.1.38';


  static String get _localIp {
    switch (mode) {
      case ConnectionMode.emulator:
        return '10.0.2.2';
      case ConnectionMode.usbReverse:
        return 'localhost';
      case ConnectionMode.wifi:
        return _wifiIp;
    }
  }

  static String get localIp => _localIp;

  static String get baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://$_localIp:8080/api';
      }
    } catch (e) {
      // Web or other platforms — localhost works fine
    }
    return 'http://localhost:8080/api';
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get refreshToken => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';
  static String get clientDashboard => '$baseUrl/client/dashboard';

  /// Rewrites a URL that was built on the server (which may contain
  /// "localhost" or "127.0.0.1") to use the correct host so that the
  /// URL is reachable from a physical Android device.
  static String rewriteImageUrl(String url) {
    if (url.contains('/api/public/uploads/')) {
      final index = url.indexOf('/api/public/uploads/');
      final relativePath = url.substring(index);
      // Construct the host portion from baseUrl (removing the '/api' suffix)
      final host = baseUrl.replaceAll('/api', '');
      return '$host$relativePath';
    }
    // Fallback replacement for other local URLs
    return url
        .replaceFirst('http://localhost:', 'http://$_localIp:')
        .replaceFirst('http://127.0.0.1:', 'http://$_localIp:');
  }
}