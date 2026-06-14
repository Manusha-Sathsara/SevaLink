import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../data/models/chat_models.dart';

/// Connection states exposed to the UI.
enum WsConnectionState { disconnected, connecting, connected }

/// Singleton service that manages the STOMP WebSocket connection to the backend.
///
/// Usage:
///   1. Call [connect] once after login (done automatically by [websocketProvider]).
///   2. Call [subscribeToRoom] when a chat room screen opens.
///   3. Call [unsubscribeFromRoom] when the screen closes.
///   4. Call [sendMessage] to deliver a message over WebSocket (falls back to REST in provider).
///   5. Call [disconnect] on logout.
class WebSocketService {
  // ── Configuration ──────────────────────────────────────────────────────────
  static const String _wsUrl =
      'http://10.0.2.2:8080/ws-chat/websocket'; // Android emulator → localhost:8080

  static const int _reconnectDelayMs = 3000;

  // ── State ──────────────────────────────────────────────────────────────────
  StompClient? _client;
  bool _shouldBeConnected = false;

  final _connectionController =
      StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get connectionStream =>
      _connectionController.stream;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get connectionState => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  // Track active room subscriptions so we can re-subscribe after reconnect
  final Map<int, void Function(ChatMessageModel)> _roomCallbacks = {};
  final Map<int, StompUnsubscribe?> _unsubscribeFns = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Connect to the backend WebSocket using the stored JWT token.
  Future<void> connect(FlutterSecureStorage storage) async {
    if (_shouldBeConnected) return; // Already connecting/connected
    _shouldBeConnected = true;
    _setState(WsConnectionState.connecting);

    final token = await storage.read(key: 'access_token') ?? '';

    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: (frame) => _onConnected(frame),
        onDisconnect: (_) => _onDisconnected(),
        onWebSocketError: (error) => _onError(error, storage),
        onStompError: (frame) =>
            _onError('STOMP error: ${frame.body}', storage),
        reconnectDelay: const Duration(milliseconds: _reconnectDelayMs),
        connectionTimeout: const Duration(seconds: 10),
        // Pass JWT in STOMP CONNECT headers
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );

    _client!.activate();
  }

  void _onConnected(StompFrame frame) {
    _setState(WsConnectionState.connected);
    // Re-subscribe to any rooms that were active before reconnect
    _roomCallbacks.forEach((roomId, callback) {
      _subscribe(roomId, callback);
    });
  }

  void _onDisconnected() {
    _setState(WsConnectionState.disconnected);
    _unsubscribeFns.clear();
  }

  void _onError(Object error, FlutterSecureStorage storage) {
    _setState(WsConnectionState.disconnected);
    // Reconnection is handled automatically by StompClient's reconnectDelay
  }

  /// Gracefully disconnect (call on logout).
  void disconnect() {
    _shouldBeConnected = false;
    _unsubscribeFns.clear();
    _roomCallbacks.clear();
    _client?.deactivate();
    _client = null;
    _setState(WsConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }

  // ── Room Subscriptions ─────────────────────────────────────────────────────

  /// Subscribe to real-time messages for a given chat room.
  /// The [callback] is called each time a new message arrives.
  void subscribeToRoom(int roomId, void Function(ChatMessageModel) callback) {
    _roomCallbacks[roomId] = callback;
    if (isConnected) {
      _subscribe(roomId, callback);
    }
    // If not connected yet, _onConnected will re-subscribe when ready.
  }

  void _subscribe(int roomId, void Function(ChatMessageModel) callback) {
    // Cancel any existing subscription for this room first
    _unsubscribeFns[roomId]?.call();

    final fn = _client?.subscribe(
      destination: '/topic/messages/$roomId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          final msg = ChatMessageModel.fromJson(json);
          callback(msg);
        } catch (e) {
          // Ignore malformed frames
        }
      },
    );
    _unsubscribeFns[roomId] = fn;
  }

  /// Unsubscribe from a room's messages (call when leaving the chat screen).
  void unsubscribeFromRoom(int roomId) {
    _unsubscribeFns[roomId]?.call();
    _unsubscribeFns.remove(roomId);
    _roomCallbacks.remove(roomId);
  }

  // ── Sending Messages ───────────────────────────────────────────────────────

  /// Send a message over WebSocket to /app/chat.send.
  /// Returns true if the frame was sent, false if not connected (caller uses REST fallback).
  bool sendMessage({
    required int chatRoomId,
    required int recipientId,
    required String content,
    String messageType = 'TEXT',
  }) {
    if (!isConnected || _client == null) return false;

    _client!.send(
      destination: '/app/chat.send',
      body: jsonEncode({
        'chatRoomId': chatRoomId,
        'recipientId': recipientId,
        'content': content,
        'messageType': messageType,
      }),
    );
    return true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(WsConnectionState newState) {
    _state = newState;
    if (!_connectionController.isClosed) {
      _connectionController.add(newState);
    }
  }
}
