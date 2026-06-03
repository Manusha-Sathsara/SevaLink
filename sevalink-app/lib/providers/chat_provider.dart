import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

// Provider for global unread messages count
final unreadMessagesCountProvider = StateNotifierProvider<UnreadMessagesCountNotifier, int>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return UnreadMessagesCountNotifier(repository);
});

class UnreadMessagesCountNotifier extends StateNotifier<int> {
  final ChatRepository _repository;
  Timer? _timer;

  UnreadMessagesCountNotifier(this._repository) : super(0) {
    fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchCount();
    });
  }

  Future<void> fetchCount() async {
    try {
      final count = await _repository.getUnreadCount();
      if (mounted) {
        state = count;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Provider for the chat rooms list
final chatRoomsProvider = StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatRoomsNotifier(repository);
});

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoomModel>>> {
  final ChatRepository _repository;
  Timer? _pollingTimer;

  ChatRoomsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchRooms();
    _startPolling();
  }

  Future<void> fetchRooms() async {
    try {
      final rooms = await _repository.getChatRooms();
      if (mounted) {
        state = AsyncValue.data(rooms);
      }
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      _pollRooms();
    });
  }

  Future<void> _pollRooms() async {
    try {
      final rooms = await _repository.getChatRooms();
      if (mounted) {
        state = AsyncValue.data(rooms);
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> initializeRoom(int recipientId) async {
    final roomData = await _repository.getOrCreateRoom(recipientId);
    fetchRooms();
    return roomData;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

// Provider for active conversation messages (polled every 3 seconds)
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessageModel>>, int>((ref, roomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatMessagesNotifier(repository, roomId);
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final ChatRepository _repository;
  final int _roomId;
  Timer? _pollingTimer;

  ChatMessagesNotifier(this._repository, this._roomId) : super(const AsyncValue.loading()) {
    fetchMessages();
    _startPolling();
  }

  Future<void> fetchMessages() async {
    try {
      final messages = await _repository.getMessages(_roomId);
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollMessages();
    });
  }

  Future<void> _pollMessages() async {
    try {
      final messages = await _repository.getMessages(_roomId);
      if (mounted) {
        final currentMessages = state.value ?? [];
        if (messages.length != currentMessages.length ||
            (messages.isNotEmpty && currentMessages.isNotEmpty && messages.last.id != currentMessages.last.id)) {
          state = AsyncValue.data(messages);
        }
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(int recipientId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      final sentMsg = await _repository.sendMessage(_roomId, recipientId, content);
      if (mounted) {
        final currentMessages = state.value ?? [];
        state = AsyncValue.data([...currentMessages, sentMsg]);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
