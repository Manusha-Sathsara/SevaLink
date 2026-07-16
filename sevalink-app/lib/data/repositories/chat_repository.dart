import '../../core/network/dio_client.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(this._dioClient);

  Future<List<ChatMessageModel>> getConversation(int otherUserId) async {
    try {
      final response = await _dioClient.dio.get('/chat/conversation/$otherUserId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch conversation');
    } catch (e) {
      throw Exception('Error fetching conversation: $e');
    }
  }

  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _dioClient.dio.get('/chat/conversations');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ChatConversation.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch conversations');
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  Future<ChatMessageModel> sendMessage({
    required int receiverId,
    required String content,
    int? jobPostId,
  }) async {
    try {
      final response = await _dioClient.dio.post('/chat/send', data: {
        'receiverId': receiverId,
        'content': content,
        if (jobPostId != null) 'jobPostId': jobPostId,
      });
      if (response.statusCode == 200) {
        return ChatMessageModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}
