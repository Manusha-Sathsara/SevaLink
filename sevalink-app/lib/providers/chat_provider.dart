// Provider and Notifier implementations for chat feature
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:riverpod/riverpod.dart';

import 'auth_provider.dart';
import '../data/models/chat_models.dart';
import '../data/repositories/chat_repository.dart';

// Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

// -------------------------------------------------------------------
// Unread messages count provider
// -------------------------------------------------------------------
final unreadMessagesCountProvider =
    StateNotifierProvider.autoDispose<UnreadMessagesCountNotifier, int>((ref) => UnreadMessagesCountNotifier(ref));

class UnreadMessagesCountNotifier extends StateNotifier<int> {
  final Ref ref;
  late final ChatRepository _repository;
  Timer? _timer;

  UnreadMessagesCountNotifier(this.ref) : super(0) {
    _repository = ref.watch(chatRepositoryProvider);
    // initial fetch
    fetchCount();
    // periodic refresh
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchCount());
    ref.onDispose(() => _timer?.cancel());
  }

  Future<void> fetchCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = count;
    } catch (_) {}
  }
}

// -------------------------------------------------------------------
// Chat rooms provider
// -------------------------------------------------------------------
final chatRoomsProvider =
    StateNotifierProvider.autoDispose<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>((ref) => ChatRoomsNotifier(ref));

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoomModel>>> {
  final Ref ref;
  late final ChatRepository _repository;
  Timer? _pollingTimer;

  ChatRoomsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _repository = ref.watch(chatRepositoryProvider);
    // initial load
    fetchRooms();
    // start polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) => fetchRooms());
    ref.onDispose(() => _pollingTimer?.cancel());
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

  Future<Map<String, dynamic>> initializeRoom(int recipientId) async {
    final roomData = await _repository.getOrCreateRoom(recipientId);
    fetchRooms();
    return roomData;
  }
}

// -------------------------------------------------------------------
// Chat messages provider (family) – one instance per roomId
// -------------------------------------------------------------------
final chatMessagesProvider =
    StateNotifierProvider.autoDispose.family<ChatMessagesNotifier,
        AsyncValue<List<ChatMessageModel>>, int>((ref, roomId) => ChatMessagesNotifier(ref, roomId));

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final Ref ref;
  final int _roomId;
  late final ChatRepository _repository;
  Timer? _pollingTimer;

  ChatMessagesNotifier(this.ref, this._roomId) : super(const AsyncValue.loading()) {
    _repository = ref.watch(chatRepositoryProvider);
    // initial load
    fetchMessages();
    // start polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
    ref.onDispose(() => _pollingTimer?.cancel());
  }

  Future<void> fetchMessages() async {
    try {
      final msgs = await _repository.getMessages(_roomId);
      state = AsyncValue.data(msgs);
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> _pollMessages() async {
    try {
      final msgs = await _repository.getMessages(_roomId);
      final current = state.value ?? [];
      if (msgs.length != current.length ||
          (msgs.isNotEmpty && current.isNotEmpty && msgs.last.id != current.last.id)) {
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
