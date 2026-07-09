import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationsDrawer extends ConsumerWidget {
  final void Function(NotificationModel)? onNotificationTap;

  const NotificationsDrawer({super.key, this.onNotificationTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          ref.read(notificationProvider.notifier).markAllAsRead();
                        },
                        child: const Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: Color(0xFF2A9134),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ref.read(notificationProvider.notifier).clearAll();
                        },
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            
            Expanded(
              child: notificationState.isLoading && notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(notifications, ref, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications, WidgetRef ref, BuildContext context) {
    // For demo purposes, we group unread as TODAY and read as EARLIER.
    final today = notifications.where((n) => !n.isRead).toList();
    final earlier = notifications.where((n) => n.isRead).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (today.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text('TODAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...today.map((n) => _buildNotificationCard(n, ref, context)),
          const SizedBox(height: 12),
        ],
        if (earlier.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text('EARLIER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...earlier.map((n) => _buildNotificationCard(n, ref, context)),
        ],
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, WidgetRef ref, BuildContext context) {
    IconData icon = Icons.notifications_none;
    Color bgColor = Colors.grey.shade100;
    Color iconColor = Colors.grey.shade600;

    final lowerTitle = notif.title.toLowerCase();
    if (lowerTitle.contains('quote')) {
      icon = Icons.attach_money_rounded;
      bgColor = const Color(0xFFE8F5E9); 
      iconColor = const Color(0xFF2E7D32); 
    } else if (lowerTitle.contains('completed') || lowerTitle.contains('accepted')) {
      icon = Icons.check_circle_outline;
      bgColor = const Color(0xFFE8F8EE); 
      iconColor = const Color(0xFFE65C00); 
    } else if (lowerTitle.contains('message') || lowerTitle.contains('chat')) {
      icon = Icons.chat_bubble_outline;
      bgColor = const Color(0xFFE8F8EE); 
      iconColor = const Color(0xFF2A9134); 
    } else {
      icon = Icons.info_outline;
      bgColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left border indicator
            Container(
              width: 3,
              color: notif.isRead ? Colors.transparent : const Color(0xFFE65C00),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  ref.read(notificationProvider.notifier).markAsRead(notif.id);
                  if (onNotificationTap != null) {
                    onNotificationTap!(notif);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notif.createdAt.isNotEmpty ? notif.createdAt : 'Just now',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Unread dot
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935), // Red dot
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
