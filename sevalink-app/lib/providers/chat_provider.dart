// Provider and Notifier implementations for chat feature
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide State;

import '../data/models/chat_models.dart';
import '../data/repositories/chat_repository.dart';
import 'auth_provider.dart'; // provides dioClientProvider

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

// -------------------------------------------------------------------
// Unread messages count provider
// -------------------------------------------------------------------
final unreadMessagesCountProvider = NotifierProvider.autoDispose<UnreadMessagesCountNotifier, int>((ref) => UnreadMessagesCountNotifier());

class UnreadMessagesCountNotifier extends AutoDisposeNotifier<int> {
  late final ChatRepository _repository;
  Timer? _timer;

  @override
  int build() {
    _repository = ref.read(chatRepositoryProvider);
    // Start with zero count, will be updated shortly
    _updateCount();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _updateCount());
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  Future<void> _updateCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = count;
    } catch (_) {}
  }
}

// -------------------------------------------------------------------
// Chat rooms provider
// -------------------------------------------------------------------
final chatRoomsProvider = NotifierProvider.autoDispose<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>((ref) => ChatRoomsNotifier());

class ChatRoomsNotifier extends AutoDisposeNotifier<AsyncValue<List<ChatRoomModel>>> {
  late final ChatRepository _repository;
  Timer? _timer;

  @override
  AsyncValue<List<ChatRoomModel>> build() {
    _repository = ref.read(chatRepositoryProvider);
    _fetchRooms();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchRooms());
    ref.onDispose(() => _timer?.cancel());
    // Initial loading state
    return const AsyncValue.loading();
  }

  Future<void> _fetchRooms() async {
    try {
      final rooms = await _repository.getChatRooms();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Exposed method for UI to manually refresh
  Future<void> fetchRooms() => _fetchRooms();

  Future<Map<String, dynamic>> initializeRoom(int recipientId) async {
    final data = await _repository.getOrCreateRoom(recipientId);
    await _fetchRooms();
    return data;
  }
}

// -------------------------------------------------------------------
// Chat messages provider (family) — one instance per roomId
// -------------------------------------------------------------------
final chatMessagesProvider = NotifierProvider.autoDispose.family<ChatMessagesNotifier, AsyncValue<List<ChatMessageModel>>, int>((ref, roomId) => ChatMessagesNotifier(roomId));

class ChatMessagesNotifier extends AutoDisposeFamilyNotifier<AsyncValue<List<ChatMessageModel>>, int> {
  late final ChatRepository _repository;
  Timer? _timer;
  late final int _roomId;

  @override
  AsyncValue<List<ChatMessageModel>> build(int roomId) {
    _roomId = roomId;
    _repository = ref.read(chatRepositoryProvider);
    _fetchMessages(roomId);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages(roomId));
    ref.onDispose(() => _timer?.cancel());
    // Initial loading state
    return const AsyncValue.loading();
  }

  Future<void> _fetchMessages(int roomId) async {
    try {
      final msgs = await _repository.getMessages(roomId);
      state = AsyncValue.data(msgs);
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> _pollMessages(int roomId) async {
    try {
      final msgs = await _repository.getMessages(roomId);
      final current = state.value ?? [];
      if (msgs.length != current.length || (msgs.isNotEmpty && current.isNotEmpty && msgs.last.id != current.last.id)) {
        state = AsyncValue.data(msgs);
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(int recipientId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      final sent = await _repository.sendMessage(_roomId, recipientId, content);
      final current = state.value ?? [];
      state = AsyncValue.data([...current, sent]);
      return true;
    } catch (_) {
      return false;
    }
  }
}
