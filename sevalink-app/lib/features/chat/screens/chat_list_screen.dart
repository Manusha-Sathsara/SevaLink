import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../data/models/chat.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh rooms list when opening the screen
    Future.microtask(() {
      ref.read(chatProvider.notifier).loadRooms();
    });
  }

  // Format timestamp helper
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && now.day == dateTime.day) {
      // Today: e.g. 6:47 PM
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dateTime.day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // e.g. Monday
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // e.g. 24 May
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dateTime.day} ${months[dateTime.month - 1]}';
    }
  }

  // Generate a background color for initials avatar
  Color _getAvatarBgColor(String name) {
    final colors = [
      const Color(0xFFE8F1FE),
      const Color(0xFFFEF5E5),
      const Color(0xFFFEF0E5),
      const Color(0xFFF4EBFE),
      const Color(0xFFFEE8F0),
      const Color(0xFFE8F8EE),
    ];
    int code = name.isEmpty ? 0 : name.codeUnitAt(0);
    return colors[code % colors.length];
  }

  // Generate avatar text color based on background color
  Color _getAvatarTextColor(Color bg) {
    if (bg == const Color(0xFFE8F1FE)) return const Color(0xFF2962FF);
    if (bg == const Color(0xFFFEF5E5)) return const Color(0xFFD49A00);
    if (bg == const Color(0xFFFEF0E5)) return const Color(0xFFE65C00);
    if (bg == const Color(0xFFF4EBFE)) return const Color(0xFF9C27B0);
    if (bg == const Color(0xFFFEE8F0)) return const Color(0xFFE91E63);
    if (bg == const Color(0xFFE8F8EE)) return const Color(0xFF2E7D32);
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final currentUserId = ref.watch(authProvider).user?.id ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF006B3D), size: 28),
            onPressed: () {
              // Action to start new chat or select user (Can open a dialog or worker list sheet)
              _showNewChatDialog(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: chatState.isLoadingRooms
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006B3D)))
          : chatState.rooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFF006B3D),
                  onRefresh: () => ref.read(chatProvider.notifier).loadRooms(),
                  child: ListView.separated(
                    itemCount: chatState.rooms.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFF3F4F6),
                      indent: 76,
                    ),
                    itemBuilder: (context, index) {
                      final room = chatState.rooms[index];
                      final otherUser = room.getOtherUser(currentUserId);
                      final avatarColor = _getAvatarBgColor(otherUser.fullName);
                      final avatarTextColor = _getAvatarTextColor(avatarColor);

                      return InkWell(
                        onTap: () async {
                          // Load chat history and navigate
                          await ref.read(chatProvider.notifier).loadHistory(room.id);
                          if (context.mounted) {
                            context.push(
                              '/chat/room/${room.id}',
                              extra: {
                                'otherUserName': otherUser.fullName,
                                'otherUserRole': otherUser.role,
                              },
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: avatarColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    otherUser.fullName.isNotEmpty
                                        ? otherUser.fullName.substring(0, 1).toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: avatarTextColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Name and Message snippet
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      otherUser.fullName,
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      room.lastMessage.isNotEmpty ? room.lastMessage : 'No messages yet',
                                      style: TextStyle(
                                        color: room.lastMessage.isNotEmpty
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade400,
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Time and unread dot
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    room.lastMessage.isNotEmpty
                                        ? _formatTimestamp(room.lastMessageTimestamp)
                                        : '',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Live WebSocket status indicator or unread badge (we will calculate it locally or display)
                                  // For simplicity, if room last message was not read and sender is not me, show green dot
                                  // But since room object does not directly track unread count, we can do a mock green dot if needed or retrieve it.
                                  // Let's check if the last message in room is unread:
                                  // In a real app we'd have unreadCount, let's keep it simple and clean.
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Messages Yet',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initiate a conversation with a service worker or client to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to search for users to chat (New Conversation)
  void _showNewChatDialog(BuildContext context) {
    // This allows selecting a user to chat. Since we have a search endpoint or can get list,
    // let's retrieve all users and let the current user select one.
    // For mock/simple demonstration: we can list users in a dialog list view.
    showDialog(
      context: context,
      builder: (dialogCtx) => _NewChatDialog(parentCtx: context),
    );
  }
}

// Sub-widget for selecting user to start chat
class _NewChatDialog extends ConsumerStatefulWidget {
  final BuildContext parentCtx;
  const _NewChatDialog({required this.parentCtx});

  @override
  ConsumerState<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<_NewChatDialog> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('/users'); // Fetch all registered users
      final currentUserId = ref.read(authProvider).user?.id ?? 0;

      final List<dynamic> allUsers = response.data;
      setState(() {
        // Filter out ourselves
        _users = allUsers.where((u) => u['id'] != currentUserId).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Start New Chat',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.only(top: 12),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF006B3D)))
            : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                : _users.isEmpty
                    ? const Center(child: Text('No other users registered.'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (ctx, index) {
                          final user = _users[index];
                          final name = user['fullName'] ?? 'User';
                          final role = user['role'] ?? 'CLIENT';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE8F1FE),
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                style: const TextStyle(color: Color(0xFF2962FF)),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(role == 'CLIENT' ? 'Client' : 'Worker'),
                            onTap: () async {
                              Navigator.pop(context); // close dialog
                              final otherUserId = user['id'] as int;

                              // Initialize chat session
                              final room = await ref
                                  .read(chatProvider.notifier)
                                  .startChatWithUser(otherUserId);

                              if (room != null && widget.parentCtx.mounted) {
                                widget.parentCtx.push(
                                  '/chat/room/${room.id}',
                                  extra: {
                                    'otherUserName': name,
                                    'otherUserRole': role,
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        )
      ],
    );
  }
}
