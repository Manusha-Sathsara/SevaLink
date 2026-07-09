import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/themes/app_theme.dart';

class NotificationsDrawer extends ConsumerWidget {
  const NotificationsDrawer({super.key});

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationModel notif) {
    // 1. Mark as read on the backend & local state
    ref.read(notificationProvider.notifier).markAsRead(notif.id);
    
    // 2. Close drawer
    Navigator.pop(context);

    // 3. Determine navigation route
    final isClient = ref.read(authProvider).user?.role == 'CLIENT';
    final titleLower = notif.title.toLowerCase();

    if (titleLower.contains('message') || titleLower.contains('msg')) {
      // Chat message notification
      final String partnerName = notif.title.replaceFirst(RegExp(r'New Message from ', caseSensitive: false), '').trim();
      
      // Let's read the conversations list to try to find partner ID
      final conversationsAsync = ref.read(conversationsProvider);
      int? partnerId;
      if (conversationsAsync is AsyncData) {
        final conversations = conversationsAsync.value;
        if (conversations != null) {
          for (final conv in conversations) {
            if (conv.partnerName.trim().toLowerCase() == partnerName.toLowerCase()) {
              partnerId = conv.partnerId;
              break;
            }
          }
        }
      }

      if (isClient) {
        if (partnerId != null) {
          context.push('/client/chat/$partnerId', extra: {'name': partnerName});
        } else {
          context.push('/client/chat');
        }
      } else {
        if (partnerId != null) {
          context.push('/worker/chat/$partnerId', extra: {'name': partnerName});
        } else {
          context.push('/worker/chat');
        }
      }
    } else if (notif.relatedJobId != null) {
      final jobId = notif.relatedJobId!;
      if (isClient) {
        if (titleLower.contains('quote') && titleLower.contains('received')) {
          // Quote received -> quotes section
          context.push('/client/jobs/$jobId/quotes', extra: <String, dynamic>{});
        } else {
          // Job milestone -> job timeline
          context.push('/client/jobs/$jobId/timeline');
        }
      } else {
        // Worker navigates to job timeline
        context.push('/worker/jobs/$jobId/timeline');
      }
    } else {
      // Fallback: navigate to home
      if (isClient) {
        context.go('/client/home');
      } else {
        context.go('/worker/home');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sevaColors;
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;

    return Drawer(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (notifications.isNotEmpty) ...[
                        IconButton(
                          icon: Icon(Icons.done_all, color: colors.textSecondary, size: 22),
                          tooltip: 'Mark all as read',
                          onPressed: () {
                            ref.read(notificationProvider.notifier).markAllAsRead();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_sweep_outlined, color: colors.textSecondary, size: 22),
                          tooltip: 'Clear all',
                          onPressed: () {
                            ref.read(notificationProvider.notifier).clearAll();
                          },
                        ),
                      ],
                      if (notificationState.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${notificationState.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: notificationState.isLoading && notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 52, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No notifications yet',
                                  style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            return InkWell(
                              onTap: () => _handleNotificationTap(context, ref, notif),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: notif.isRead ? Colors.transparent : const Color(0xFF0F9B8E).withValues(alpha: 0.05),
                                  border: Border(bottom: BorderSide(color: colors.divider)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: notif.isRead ? Colors.grey.shade100 : const Color(0xFF0F9B8E).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_active,
                                        color: notif.isRead ? Colors.grey.shade400 : const Color(0xFF0F9B8E),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 15,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colors.textSecondary,
                                              height: 1.3,
                                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
