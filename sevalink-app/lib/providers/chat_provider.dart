// Provider and Notifier implementations for chat feature
// Integrates WebSocket real-time delivery + REST polling fallback
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat_models.dart';
import '../data/repositories/chat_repository.dart';
import '../services/websocket_service.dart';
import 'auth_provider.dart';       // provides dioClientProvider, secureStorageProvider
import 'websocket_provider.dart';  // provides webSocketServiceProvider

// -------------------------------------------------------------------
// Repository provider
// -------------------------------------------------------------------
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

// -------------------------------------------------------------------
// Unread messages count provider
// -------------------------------------------------------------------
final unreadMessagesCountProvider =
    NotifierProvider.autoDispose<UnreadMessagesCountNotifier, int>(
  UnreadMessagesCountNotifier.new,
);

class UnreadMessagesCountNotifier extends AutoDisposeNotifier<int> {
  late final ChatRepository _repository;
  Timer? _timer;

  @override
  int build() {
    _repository = ref.read(chatRepositoryProvider);
    _updateCount();
    // Poll every 10s for badge updates (lightweight call)
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _updateCount());
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
final chatRoomsProvider =
    NotifierProvider.autoDispose<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>(
  ChatRoomsNotifier.new,
);

class ChatRoomsNotifier extends AutoDisposeNotifier<AsyncValue<List<ChatRoomModel>>> {
  late final ChatRepository _repository;
  Timer? _timer;

  @override
  AsyncValue<List<ChatRoomModel>> build() {
    _repository = ref.read(chatRepositoryProvider);
    _fetchRooms();
    // Poll rooms list every 10s to catch room creation from other devices
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchRooms());
    ref.onDispose(() => _timer?.cancel());
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

  // Exposed for UI to manually refresh
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
final chatMessagesProvider = NotifierProvider.autoDispose
    .family<ChatMessagesNotifier, AsyncValue<List<ChatMessageModel>>, int>(
  ChatMessagesNotifier.new,
);

class ChatMessagesNotifier
    extends AutoDisposeFamilyNotifier<AsyncValue<List<ChatMessageModel>>, int> {
  late final ChatRepository _repository;
  late final WebSocketService _ws;
  Timer? _pollTimer;

  @override
  AsyncValue<List<ChatMessageModel>> build(int arg) {
    _repository = ref.read(chatRepositoryProvider);
    _ws = ref.read(webSocketServiceProvider);

    // 1. Fetch initial messages via REST
    _fetchMessages();

    // 2. Subscribe to real-time WebSocket topic for this room
    _ws.subscribeToRoom(arg, _onWsMessage);

    // 3. Keep a slow polling fallback (15s) for when WS is disconnected
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollMessages());

    ref.onDispose(() {
      _pollTimer?.cancel();
      _ws.unsubscribeFromRoom(arg);
    });

    return const AsyncValue.loading();
  }

  // Called by WebSocket subscription on every new message
  void _onWsMessage(ChatMessageModel msg) {
    final current = state.value ?? [];
    // Avoid duplicates (WS may fire and REST poll returns same message)
    if (current.any((m) => m.id == msg.id)) return;
    state = AsyncValue.data([...current, msg]);
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await _repository.getMessages(arg);
      state = AsyncValue.data(msgs);
    } catch (e, stack) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  // Lightweight poll: only update state if there are new messages
  Future<void> _pollMessages() async {
    try {
      final msgs = await _repository.getMessages(arg);
      final current = state.value ?? [];
      if (msgs.length != current.length ||
          (msgs.isNotEmpty &&
              current.isNotEmpty &&
              msgs.last.id != current.last.id)) {
        state = AsyncValue.data(msgs);
      }
    } catch (_) {}
  }

  /// Send a message — tries WebSocket first, falls back to REST.
  Future<bool> sendMessage(int recipientId, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      // Attempt WebSocket send first (no extra network round-trip)
      final wsSent = _ws.sendMessage(
        chatRoomId: arg,
        recipientId: recipientId,
        content: content,
      );

      if (!wsSent) {
        // WebSocket not connected — use REST, then append to local state
        final sent = await _repository.sendMessage(arg, recipientId, content);
        final current = state.value ?? [];
        state = AsyncValue.data([...current, sent]);
      }
      // If WS was sent, the server will broadcast it back and _onWsMessage adds it
      return true;
    } catch (_) {
      return false;
    }
  }
}
