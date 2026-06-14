import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/websocket_provider.dart';
import '../../../services/websocket_service.dart';
import '../../../data/models/chat_models.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int? chatRoomId;
  final int? recipientId;
  final String recipientName;
  final String recipientRole;

  const ChatRoomScreen({
    super.key,
    this.chatRoomId,
    this.recipientId,
    required this.recipientName,
    required this.recipientRole,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _activeRoomId;
  bool _initializingRoom = false;

  @override
  void initState() {
    super.initState();
    _activeRoomId = widget.chatRoomId;
    if (_activeRoomId == null && widget.recipientId != null) {
      _initializeChatRoom();
    } else {
      _scrollToBottomDelayed();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    setState(() => _initializingRoom = true);
    try {
      final roomData = await ref
          .read(chatRoomsProvider.notifier)
          .initializeRoom(widget.recipientId!);
      if (mounted) {
        setState(() {
          _activeRoomId = roomData['id'];
          _initializingRoom = false;
        });
        _scrollToBottomDelayed();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _initializingRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize conversation')),
        );
      }
    }
  }

  void _scrollToBottomDelayed() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime.toLocal());
  }

  String _getGroupHeader(DateTime dateTime) {
    final now = DateTime.now();
    final localDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (localDate == today) {
      return 'Today';
    } else if (localDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(dateTime);
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

  Future<void> _sendMessage(int currentUserId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeRoomId == null) return;

    _messageController.clear();

    // Deduce actual recipient ID
    int finalRecipientId = widget.recipientId ?? 0;
    if (finalRecipientId == 0 && _activeRoomId != null) {
      final roomsState = ref.read(chatRoomsProvider);
      final room = roomsState.value?.firstWhere(
        (r) => r.id == _activeRoomId,
        orElse: () => throw Exception(),
      );
      if (room != null) finalRecipientId = room.otherUserId;
    }

    final success = await ref
        .read(chatMessagesProvider(_activeRoomId!).notifier)
        .sendMessage(finalRecipientId, text);

    if (success) {
      _scrollToBottomDelayed();
      ref.read(chatRoomsProvider.notifier).fetchRooms();
    }
  }

  // ── Connection Status Badge ──────────────────────────────────────────────
  Widget _buildConnectionBadge(WsConnectionState state) {
    final isLive = state == WsConnectionState.connected;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isLive ? const Color(0xFF22C55E) : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isLive ? 'Live' : widget.recipientRole,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? 0;
    final roleColor = _getRoleColor(widget.recipientRole);

    // Watch WebSocket connection state
    final wsState = ref.watch(wsConnectionStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor.withOpacity(0.8), roleColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.recipientName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  wsState.when(
                    data: (s) => _buildConnectionBadge(s),
                    loading: () => _buildConnectionBadge(WsConnectionState.connecting),
                    error: (_, __) => _buildConnectionBadge(WsConnectionState.disconnected),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Color(0xFF4B5563)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4B5563)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _initializingRoom
                ? const Center(child: CircularProgressIndicator())
                : _activeRoomId == null
                    ? const Center(child: Text('Initializing chat room...'))
                    : ref.watch(chatMessagesProvider(_activeRoomId!)).when(
                          data: (messages) {
                            if (messages.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.waving_hand_rounded,
                                        size: 48, color: roleColor.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Say Hello to ${widget.recipientName}!',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Group messages by date
                            final Map<String, List<ChatMessageModel>> grouped = {};
                            for (var msg in messages) {
                              final header = _getGroupHeader(msg.timestamp);
                              grouped.putIfAbsent(header, () => []).add(msg);
                            }

                            // Scroll to bottom on new messages
                            ref.listen<AsyncValue<List<ChatMessageModel>>>(
                                chatMessagesProvider(_activeRoomId!), (prev, next) {
                              if (prev?.value?.length != next.value?.length) {
                                _scrollToBottomDelayed();
                              }
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              itemCount: grouped.keys.length,
                              itemBuilder: (context, groupIndex) {
                                final dateHeader =
                                    grouped.keys.elementAt(groupIndex);
                                final groupMessages = grouped[dateHeader]!;

                                return Column(
                                  children: [
                                    // Date Header
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300
                                                .withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            dateHeader,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Messages under date group
                                    ...groupMessages.map((msg) {
                                      final isMe =
                                          msg.senderId == currentUserId;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          mainAxisAlignment: isMe
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (!isMe) ...[
                                              // Recipient avatar
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: roleColor
                                                      .withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    _getInitials(
                                                        widget.recipientName),
                                                    style: TextStyle(
                                                      color: roleColor,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],

                                            // Message Bubble
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: isMe
                                                      ? const Color(0xFFE65100)
                                                      : Colors.white,
                                                  borderRadius: BorderRadius
                                                      .only(
                                                    topLeft:
                                                        const Radius.circular(
                                                            16),
                                                    topRight:
                                                        const Radius.circular(
                                                            16),
                                                    bottomLeft: Radius.circular(
                                                        isMe ? 16 : 4),
                                                    bottomRight: Radius.circular(
                                                        isMe ? 4 : 16),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.03),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      msg.content,
                                                      style: TextStyle(
                                                        color: isMe
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF1F2937),
                                                        fontSize: 14.5,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _formatTime(
                                                              msg.timestamp),
                                                          style: TextStyle(
                                                            color: isMe
                                                                ? Colors.white
                                                                    .withOpacity(
                                                                        0.7)
                                                                : Colors.grey
                                                                    .shade400,
                                                            fontSize: 9,
                                                          ),
                                                        ),
                                                        // Read receipt ticks (sent messages only)
                                                        if (isMe) ...[
                                                          const SizedBox(
                                                              width: 4),
                                                          Icon(
                                                            msg.isRead
                                                                ? Icons
                                                                    .done_all_rounded
                                                                : Icons
                                                                    .done_rounded,
                                                            color: msg.isRead
                                                                ? Colors.blue
                                                                    .shade200
                                                                : Colors.white
                                                                    .withOpacity(
                                                                        0.85),
                                                            size: 11,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) =>
                              Center(child: Text('Error loading messages: $err')),
                        ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Attachment Button
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: Color(0xFF4B5563), size: 24),
                      onPressed: () {},
                    ),
                  ),

                  // Text Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(currentUserId),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 14.5),
                      ),
                    ),
                  ),

                  // Send Button
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendMessage(currentUserId),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE65100),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
