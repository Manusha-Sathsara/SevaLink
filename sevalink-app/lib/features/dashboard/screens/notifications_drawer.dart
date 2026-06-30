import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/themes/app_theme.dart';

class NotificationsDrawer extends ConsumerWidget {
  const NotificationsDrawer({super.key});

  void _handleNotificationTap(BuildContext context, WidgetRef ref, int notifId) {
    ref.read(notificationProvider.notifier).markAsRead(notifId);
    Navigator.pop(context);
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                  if (notificationState.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notificationState.unreadCount} New',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                              onTap: () => _handleNotificationTap(context, ref, notif.id),
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
