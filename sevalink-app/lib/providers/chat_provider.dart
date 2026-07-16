import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/chat_repository.dart';
import '../data/models/chat_message.dart';
import 'auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

final conversationsProvider = FutureProvider<List<ChatConversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getConversations();
});

final conversationProvider = FutureProvider.family<List<ChatMessageModel>, int>((ref, otherUserId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getConversation(otherUserId);
});

class ChatNotifier extends Notifier<List<ChatMessageModel>> {
  final int otherUserId;

  ChatNotifier(this.otherUserId);

  @override
  List<ChatMessageModel> build() {
    _loadMessages();
    return [];
  }

  Future<void> _loadMessages() async {
    try {
      final repository = ref.read(chatRepositoryProvider);
      final messages = await repository.getConversation(otherUserId);
      state = messages;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendMessage({
    required int receiverId,
    required String content,
    int? jobPostId,
  }) async {
    try {
      final repository = ref.read(chatRepositoryProvider);
      final message = await repository.sendMessage(
        receiverId: receiverId,
        content: content,
        jobPostId: jobPostId,
      );
      state = [...state, message];
    } catch (e) {
      // Handle error
    }
  }
}

final chatNotifierProvider = NotifierProvider.family<ChatNotifier, List<ChatMessageModel>, int>((int otherUserId) {
  return ChatNotifier(otherUserId);
});
