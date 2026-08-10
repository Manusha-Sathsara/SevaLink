import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(this._dioClient);

  // POST /api/chat/room -> recipientId
  Future<Map<String, dynamic>> getOrCreateRoom(int recipientId) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiEndpoints.baseUrl}/chat/room',
        data: {'recipientId': recipientId},
      );
      return response.data['data']; // Returns the ChatRoom object
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/chat/rooms
  Future<List<ChatRoomModel>> getChatRooms() async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiEndpoints.baseUrl}/chat/rooms',
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ChatRoomModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/chat/room/{roomId}/messages
  Future<List<ChatMessageModel>> getMessages(int roomId) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiEndpoints.baseUrl}/chat/room/$roomId/messages',
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ChatMessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST /api/chat/message -> chatRoomId, recipientId, content
  Future<ChatMessageModel> sendMessage(int chatRoomId, int recipientId, String content) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiEndpoints.baseUrl}/chat/message',
        data: {
          'chatRoomId': chatRoomId,
          'recipientId': recipientId,
          'content': content,
        },
      );
      return ChatMessageModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/chat/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiEndpoints.baseUrl}/chat/unread-count',
      );
      return response.data['data'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
