import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class ApiEndpoints {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.126.126.148:8080/api';
    }
    return 'http://10.126.126.148:8080/api';
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get refreshToken => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';
  
  // Client Endpoints
  static String get clientDashboard => '$baseUrl/client/dashboard';

  // Chat Endpoints
  static String get chatRooms => '$baseUrl/chat/rooms';
  static String chatRoomWith(int otherUserId) => '$baseUrl/chat/rooms/with/$otherUserId';
  static String chatHistory(int roomId) => '$baseUrl/chat/messages/$roomId';
  static String markChatRead(int roomId) => '$baseUrl/chat/messages/$roomId/read';

  // WebSocket connection base path (translates http:// to ws://)
  static String get wsBaseUrl {
    final httpUrl = baseUrl;
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://').replaceFirst('/api', '/ws');
    }
    return httpUrl.replaceFirst('http://', 'ws://').replaceFirst('/api', '/ws');
  }
  static String get chatWs => '$wsBaseUrl/chat';
}
