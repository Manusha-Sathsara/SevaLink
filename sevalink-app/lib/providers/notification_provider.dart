import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import 'auth_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  Timer? _timer;

  @override
  NotificationState build() {
    // Schedule the initial fetch after the provider is initialized
    Future.microtask(() => fetchNotifications());
    
    // Poll every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications();
    });

    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return NotificationState();
  }

  Future<void> fetchNotifications() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      if (state.notifications.isEmpty) {
        state = state.copyWith(isLoading: true);
      }
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('/notifications/user/${user.id}');
      
      final data = response.data;
      final List<dynamic> notifsJson = data['notifications'];
      final List<NotificationModel> notifications = notifsJson.map((json) => NotificationModel.fromJson(json)).toList();
      final int unreadCount = data['unreadCount'];

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.dio.put('/notifications/$notificationId/read');
      
      // Update local state immediately
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId && !n.isRead) {
          return NotificationModel(
            id: n.id,
            workerId: n.workerId,
            title: n.title,
            message: n.message,
            relatedJobId: n.relatedJobId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      // Revert or show error
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
