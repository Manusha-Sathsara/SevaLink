import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import 'auth_provider.dart'; // provides secureStorageProvider

/// Singleton [WebSocketService] available across the app.
/// Disposed automatically when the provider scope is destroyed.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();

  // Connect using the stored JWT as soon as the provider is read
  final storage = ref.read(secureStorageProvider);
  service.connect(storage);

  // Disconnect cleanly when the provider is disposed (logout / app exit)
  ref.onDispose(service.dispose);

  return service;
});

/// Stream provider that exposes the current WebSocket connection state.
/// Use this to show connected/disconnected indicators in the UI.
final wsConnectionStateProvider = StreamProvider<WsConnectionState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionStream;
});
