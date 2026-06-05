// Provider and Notifier implementations for chat feature
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../data/models/chat_models.dart';
import '../data/repositories/chat_repository.dart';

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

// Provider for global unread messages count using Notifier
final unreadMessagesCountProvider = NotifierProvider<UnreadMessagesCountNotifier, int>(UnreadMessagesCountNotifier.new);

class UnreadMessagesCountNotifier extends Notifier<int> {
  late ChatRepository _repository;
  Timer? _timer;

  @override
  int build() {
    _repository = ref.watch(chatRepositoryProvider);
    fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchCount());
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  Future<void> fetchCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = count;
    } catch (_) {}
  }
}

// Provider for the chat rooms list using Notifier
final chatRoomsProvider = NotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>(ChatRoomsNotifier.new);

class ChatRoomsNotifier extends Notifier<AsyncValue<List<ChatRoomModel>>> {
  late ChatRepository _repository;
  Timer? _pollingTimer;

  @override
  AsyncValue<List<ChatRoomModel>> build() {
    _repository = ref.watch(chatRepositoryProvider);
    fetchRooms();
    _startPolling();
    ref.onDispose(() => _pollingTimer?.cancel());
    return const AsyncValue.loading();
  }

  Future<void> fetchRooms() async {
    try {
      final rooms = await _repository.getChatRooms();
      state = AsyncValue.data(rooms);
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) => fetchRooms());
  }

  Future<Map<String, dynamic>> initializeRoom(int recipientId) async {
    final roomData = await _repository.getOrCreateRoom(recipientId);
    fetchRooms();
    return roomData;
  }
}

// Provider for active conversation messages (polled every 3 seconds) using family Notifier
final chatMessagesProvider = NotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessageModel>>, int>(ChatMessagesNotifier.new);

class ChatMessagesNotifier extends FamilyNotifier<AsyncValue<List<ChatMessageModel>>, int> {
  late ChatRepository _repository;
  Timer? _pollingTimer;

  @override
  AsyncValue<List<ChatMessageModel>> build(int roomId) {
    _repository = ref.watch(chatRepositoryProvider);
    fetchMessages(roomId);
    _startPolling(roomId);
    ref.onDispose(() => _pollingTimer?.cancel());
    return const AsyncValue.loading();
  }

  Future<void> fetchMessages(int roomId) async {
    try {
      final messages = await _repository.getMessages(roomId);
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _startPolling(int roomId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages(roomId));
  }

  Future<void> _pollMessages(int roomId) async {
    try {
      final messages = await _repository.getMessages(roomId);
      final current = state.value ?? [];
      if (messages.length != current.length ||
          (messages.isNotEmpty && current.isNotEmpty && messages.last.id != current.last.id)) {
        state = AsyncValue.data(messages);
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(int recipientId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      final sent = await _repository.sendMessage(arg, recipientId, content);
      final current = state.value ?? [];
      state = AsyncValue.data([...current, sent]);
      return true;
    } catch (_) {
      return false;
    }
  }
}
