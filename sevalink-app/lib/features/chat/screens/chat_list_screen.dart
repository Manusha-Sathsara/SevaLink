import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/chat_provider.dart';
import '../../../data/models/chat_models.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const ChatListScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final localTime = dateTime.toLocal();
    if (localTime.year == now.year && localTime.month == now.month && localTime.day == now.day) {
      return DateFormat.jm().format(localTime);
    } else if (now.difference(localTime).inDays < 7) {
      return DateFormat('E').format(localTime);
    } else {
      return DateFormat('MMM d').format(localTime);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getRoleColor(String role) {
    if (role.toUpperCase() == 'WORKER') {
      return const Color(0xFF0F9B8E);
    }
    return const Color(0xFFE65100);
  }

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(chatRoomsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // Conversation List
          Expanded(
            child: roomsState.when(
              data: (rooms) {
                final filteredRooms = rooms.where((room) {
                  return room.otherUserFullName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No conversations found' : 'No messages yet',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching for something else'
                              : 'Chat rooms will appear here once you message a worker',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredRooms.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 84,
                    endIndent: 16,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    final hasUnread = room.unreadCount > 0;
                    final initials = _getInitials(room.otherUserFullName);
                    final roleColor = _getRoleColor(room.otherUserRole);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Route to active chat room
                          context.push('/chat/room', extra: {
                            'chatRoomId': room.id,
                            'recipientId': room.otherUserId,
                            'recipientName': room.otherUserFullName,
                            'recipientRole': room.otherUserRole,
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar / initials
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [roleColor.withOpacity(0.85), roleColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: roleColor.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name + Message Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Name + Role Badge
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  room.otherUserFullName,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                                    color: const Color(0xFF1F2937),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  room.otherUserRole,
                                                  style: TextStyle(
                                                    color: roleColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Time
                                        Text(
                                          _formatTime(room.lastMessageAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                            color: hasUnread ? const Color(0xFFE65100) : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // Message snippet + Badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            room.lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: hasUnread ? const Color(0xFF1F2937) : Colors.grey.shade600,
                                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (hasUnread) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            minWidth: 20,
                                            height: 20,
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE65100),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${room.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load messages: $err',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
