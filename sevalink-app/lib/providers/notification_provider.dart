import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import 'auth_provider.dart';
import 'worker_feed_provider.dart';
import 'worker_jobs_list_provider.dart';
import 'client_jobs_provider.dart';

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
    
    // Poll every 15 seconds so denied/accepted quotes update quickly
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
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

      final prevCount = state.notifications.length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );

      // If any newly arrived notification is a quote decline or acceptance,
      // auto-refresh the feeds so the screens update immediately.
      if (notifications.length > prevCount) {
        final newOnes = notifications.skip(prevCount);
        
        final hasDecline = newOnes.any((n) =>
            n.title.toLowerCase().contains('declined') ||
            n.title.toLowerCase().contains('denied') ||
            n.title.toLowerCase().contains('rejected') ||
            n.title.toLowerCase().contains('deleted') ||
            n.title.toLowerCase().contains('cancelled') ||
            n.title.toLowerCase().contains('canceled'));
            
        final hasAccept = newOnes.any((n) =>
            n.title.toLowerCase().contains('accepted') ||
            n.title.toLowerCase().contains('approved'));

        final hasNewQuote = newOnes.any((n) =>
            n.title.toLowerCase().contains('new quote received') ||
            n.title.toLowerCase().contains('quote'));

        if (hasDecline || hasAccept) {
          // ignore: unused_result
          ref.read(workerFeedProvider.notifier).refresh();
          // ignore: unused_result
          ref.read(workerJobsListProvider.notifier).loadJobs();
        }

        if (hasNewQuote) {
          ref.invalidate(clientJobsProvider);
          ref.invalidate(clientJobStatsProvider);
        }
      }
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

  Future<void> markAllAsRead() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final user = ref.read(authProvider).user;
      if (user != null) {
        // Attempt backend call, ignore if it fails
        try {
          await dioClient.dio.put('/notifications/user/${user.id}/read-all');
        } catch (_) {}
      }
      
      final updatedNotifications = state.notifications.map((n) {
        if (!n.isRead) {
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
        unreadCount: 0,
      );
    } catch (e) {
      // Revert or show error
    }
  }

  Future<void> clearAll() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final user = ref.read(authProvider).user;
      if (user != null) {
        // Attempt backend call, ignore if it fails
        try {
          await dioClient.dio.delete('/notifications/user/${user.id}/clear-all');
        } catch (_) {}
      }
      
      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
      );
    } catch (e) {
      // Revert or show error
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
