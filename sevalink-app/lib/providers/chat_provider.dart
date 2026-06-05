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

// -------------------------------------------------------------------
// Unread messages count provider
// -------------------------------------------------------------------
final unreadMessagesCountProvider = NotifierProvider.autoDispose<UnreadMessagesCountNotifier, int>(UnreadMessagesCountNotifier.new);

class UnreadMessagesCountNotifier extends Notifier<int> {
  late final ChatRepository _repository;
  Timer? _timer;

  @override
  int build() {
    _repository = ref.watch(chatRepositoryProvider);
    // initial fetch
    fetchCount();
    // periodic refresh
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

// -------------------------------------------------------------------
// Chat rooms provider
// -------------------------------------------------------------------
final chatRoomsProvider = NotifierProvider.autoDispose<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>(ChatRoomsNotifier.new);

class ChatRoomsNotifier extends Notifier<AsyncValue<List<ChatRoomModel>>> {
  late final ChatRepository _repository;
  Timer? _pollingTimer;

  @override
  AsyncValue<List<ChatRoomModel>> build() {
    _repository = ref.watch(chatRepositoryProvider);
    // initial load
    fetchRooms();
    // start polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) => fetchRooms());
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

  Future<Map<String, dynamic>> initializeRoom(int recipientId) async {
    final roomData = await _repository.getOrCreateRoom(recipientId);
    fetchRooms();
    return roomData;
  }
}

// -------------------------------------------------------------------
// Chat messages provider (family) – one instance per roomId
// -------------------------------------------------------------------
final chatMessagesProvider = NotifierProvider.autoDispose.family<ChatMessagesNotifier, AsyncValue<List<ChatMessageModel>>, int>(ChatMessagesNotifier.new);

class ChatMessagesNotifier extends FamilyNotifier<AsyncValue<List<ChatMessageModel>>, int> {
  late final ChatRepository _repository;
  Timer? _pollingTimer;

  @override
  AsyncValue<List<ChatMessageModel>> build(int roomId) {
    _repository = ref.watch(chatRepositoryProvider);
    // initial load
    fetchMessages(roomId);
    // start polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages(roomId));
    ref.onDispose(() => _pollingTimer?.cancel());
    return const AsyncValue.loading();
  }

  Future<void> fetchMessages(int roomId) async {
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

  Future<bool> sendMessage(int roomId, int recipientId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      final sent = await _repository.sendMessage(roomId, recipientId, content);
      final current = state.value ?? [];
      state = AsyncValue.data([...current, sent]);
      return true;
    } catch (_) {
      return false;
    }
  }
}
