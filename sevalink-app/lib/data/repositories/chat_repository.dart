import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/chat.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(this._dioClient);

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.chatRooms);
      final List<dynamic> dataList = response.data['data'] ?? [];
      return dataList.map((json) => ChatRoom.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChatRoom> getOrCreateRoom(int otherUserId) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.chatRoomWith(otherUserId));
      return ChatRoom.fromJson(response.data['data'] ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ChatMessage>> getChatHistory(int roomId) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.chatHistory(roomId));
      final List<dynamic> dataList = response.data['data'] ?? [];
      return dataList.map((json) => ChatMessage.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markRoomAsRead(int roomId) async {
    try {
      await _dioClient.dio.put(ApiEndpoints.markChatRead(roomId));
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
    return 'An error occurred while managing chat session. Please try again.';
  }
}
