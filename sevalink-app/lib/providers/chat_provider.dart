import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import 'auth_provider.dart';
import '../data/models/chat.dart';
import '../data/repositories/chat_repository.dart';

// Chat State Model
class ChatState {
  final List<ChatRoom> rooms;
  final List<ChatMessage> activeMessages;
  final int? activeRoomId;
  final bool isLoadingRooms;
  final bool isLoadingHistory;
  final String? error;
  final bool isConnected;

  ChatState({
    this.rooms = const [],
    this.activeMessages = const [],
    this.activeRoomId,
    this.isLoadingRooms = false,
    this.isLoadingHistory = false,
    this.error,
    this.isConnected = false,
  });

  ChatState copyWith({
    List<ChatRoom>? rooms,
    List<ChatMessage>? activeMessages,
    int? activeRoomId,
    bool? isLoadingRooms,
    bool? isLoadingHistory,
    String? error,
    bool? isConnected,
  }) {
    return ChatState(
      rooms: rooms ?? this.rooms,
      activeMessages: activeMessages ?? this.activeMessages,
      activeRoomId: activeRoomId !== null ? activeRoomId : this.activeRoomId, // Allow setting to null
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

// Global Providers
final chatRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRepository(dioClient);
});

class ChatNotifier extends Notifier<ChatState> {
  late ChatRepository _repository;
  WebSocket? _webSocket;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;

  @override
  ChatState build() {
    _repository = ref.watch(chatRepositoryProvider);

    // Watch auth status: if logged out, disconnect WebSocket
    ref.listen(authProvider, (previous, next) {
      if (next.user == null) {
        disconnectWebSocket();
      } else if (previous?.user == null && next.user != null) {
        connectWebSocket();
        loadRooms();
      }
    });

    // Auto-connect if user is already authenticated
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      // Connect WebSocket in the next microtask to avoid building state inside builder
      Future.microtask(() {
        connectWebSocket();
        loadRooms();
      });
    }

    // Clean up on dispose
    ref.onDispose(() {
      _shouldReconnect = false;
      disconnectWebSocket();
    });

    return ChatState();
  }

  // Connect to backend WebSocket
  Future<void> connectWebSocket() async {
    if (_webSocket != null && state.isConnected) return;

    _shouldReconnect = true;
    final token = await ref.read(secureStorageProvider).read(key: 'access_token');
    if (token == null) return;

    try {
      final wsUri = Uri.parse('${ApiEndpoints.chatWs}?token=$token');
      _webSocket = await WebSocket.connect(wsUri.toString())
          .timeout(const Duration(seconds: 10));

      state = state.copyWith(isConnected: true, error: null);

      _wsSubscription = _webSocket!.listen(
        (data) => _onMessageReceived(data),
        onDone: () => _onDisconnected(),
        onError: (err) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (e) {
      _onDisconnected();
    }
  }

  void disconnectWebSocket() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _wsSubscription?.cancel();
    _webSocket?.close();
    _webSocket = null;
    state = state.copyWith(isConnected: false);
  }

  void _onDisconnected() {
    state = state.copyWith(isConnected: false);
    _webSocket = null;

    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        connectWebSocket();
      });
    }
  }

  // Handle incoming WebSocket message
  void _onMessageReceived(dynamic data) {
    try {
      final Map<String, dynamic> json = jsonDecode(data.toString());
      final message = ChatMessage.fromJson(json);

      // If message belongs to active open chat room, append it and mark as read
      if (state.activeRoomId != null && message.chatRoomId == state.activeRoomId) {
        state = state.copyWith(
          activeMessages: [...state.activeMessages, message],
        );
        // Call API to mark as read in background
        if (message.senderId != ref.read(authProvider).user?.id) {
          _repository.markRoomAsRead(state.activeRoomId!);
        }
      }

      // Update rooms list last message cache
      _updateRoomLastMessage(message);
    } catch (e) {
      // Handle parsing or local state update error
    }
  }

  // Update a room in list or trigger reload
  void _updateRoomLastMessage(ChatMessage message) {
    bool roomFound = false;
    final updatedRooms = state.rooms.map((room) {
      if (room.id == message.chatRoomId) {
        roomFound = true;
        return ChatRoom(
          id: room.id,
          chatId: room.chatId,
          user1: room.user1,
          user2: room.user2,
          lastMessage: message.content,
          lastMessageTimestamp: message.timestamp,
        );
      }
      return room;
    }).toList();

    // Sort by timestamp
    updatedRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

    if (roomFound) {
      state = state.copyWith(rooms: updatedRooms);
    } else {
      // Room was created or is not in list, fetch rooms list again
      loadRooms();
    }
  }

  // Fetch all chat rooms
  Future<void> loadRooms() async {
    state = state.copyWith(isLoadingRooms: true);
    try {
      final roomsList = await _repository.getChatRooms();
      state = state.copyWith(rooms: roomsList, isLoadingRooms: false);
    } catch (e) {
      state = state.copyWith(isLoadingRooms: false, error: e.toString());
    }
  }

  // Load chat history for a room
  Future<void> loadHistory(int roomId) async {
    state = state.copyWith(isLoadingHistory: true, activeRoomId: roomId);
    try {
      final history = await _repository.getChatHistory(roomId);
      state = state.copyWith(activeMessages: history, isLoadingHistory: false);

      // Mark messages as read on the backend
      final currentUserId = ref.read(authProvider).user?.id;
      final unreadExist = history.any((msg) => !msg.isRead && msg.senderId != currentUserId);
      if (unreadExist) {
        await _repository.markRoomAsRead(roomId);
        // Reload rooms list to clear unread indicator
        loadRooms();
      }
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: e.toString());
    }
  }

  // Send message
  bool sendMessage(int recipientId, String content) {
    if (_webSocket == null || !state.isConnected) {
      return false;
    }

    try {
      final payload = {
        'recipientId': recipientId,
        'content': content,
      };
      _webSocket!.add(jsonEncode(payload));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Close active room (clean up on screen back)
  void closeActiveRoom() {
    // Custom logic to set activeRoomId to null and clear history
    state = ChatState(
      rooms: state.rooms,
      activeMessages: const [],
      activeRoomId: null,
      isLoadingRooms: state.isLoadingRooms,
      isLoadingHistory: false,
      isConnected: state.isConnected,
    );
  }

  // Get or create room and load history
  Future<ChatRoom?> startChatWithUser(int otherUserId) async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final room = await _repository.getOrCreateRoom(otherUserId);
      await loadHistory(room.id);
      return room;
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: e.toString());
      return null;
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
