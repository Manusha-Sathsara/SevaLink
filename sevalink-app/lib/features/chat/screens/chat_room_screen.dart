import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../data/models/chat.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String otherUserName;
  final String otherUserRole;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after layout loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(int recipientId) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final success = ref.read(chatProvider.notifier).sendMessage(recipientId, text);
    if (success) {
      _messageController.clear();
      // Scroll to bottom after the message confirms locally
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Trying to reconnect...')),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final currentUserId = currentUser?.id ?? 0;

    // Determine other user's ID by checking the active messages
    int otherUserId = 0;
    if (chatState.activeMessages.isNotEmpty) {
      final firstMsg = chatState.activeMessages.first;
      otherUserId = firstMsg.senderId == currentUserId ? firstMsg.recipientId : firstMsg.senderId;
    } else {
      // Find room in rooms list to get other user ID
      final room = chatState.rooms.firstWhere(
        (r) => r.id == widget.roomId,
        orElse: () => ChatRoom(
          id: widget.roomId,
          chatId: '',
          user1: currentUser ?? const User(id: 0, fullName: '', email: '', phoneNumber: '', role: ''),
          user2: const User(id: 0, fullName: '', email: '', phoneNumber: '', role: ''),
          lastMessage: '',
          lastMessageTimestamp: DateTime.now(),
        ),
      );
      otherUserId = room.user1.id == currentUserId ? room.user2.id : room.user1.id;
    }

    // Auto scroll to bottom when new messages arrive
    ref.listen(chatProvider, (prev, next) {
      if (prev?.activeMessages.length != next.activeMessages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    // Theme color based on role
    final primaryColor = currentUser?.role == 'CLIENT' ? const Color(0xFFE65100) : const Color(0xFF006B3D);

    return WillPopScope(
      onWillPop: () async {
        ref.read(chatProvider.notifier).closeActiveRoom();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                      onPressed: () {
                        ref.read(chatProvider.notifier).closeActiveRoom();
                        context.pop();
                      },
                    ),
                    // Avatar image container matching Figma
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade100, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          widget.otherUserName.isNotEmpty
                              ? widget.otherUserName.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Status
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUserName,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: chatState.isConnected ? const Color(0xFF10B981) : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chatState.isConnected ? 'Online' : 'Connecting...',
                                style: TextStyle(
                                  color: chatState.isConnected ? const Color(0xFF10B981) : Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 3-dot Menu Icon
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
                      onPressed: () {
                        // Options menu (Clear chat history, block user etc.)
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Message List Area
            Expanded(
              child: chatState.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF006B3D)))
                  : chatState.activeMessages.isEmpty
                      ? _buildEmptyConversation()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          itemCount: chatState.activeMessages.length,
                          itemBuilder: (context, index) {
                            final message = chatState.activeMessages[index];
                            final isMe = message.senderId == currentUserId;

                            // Render Date header block if it's the first message or a new day
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final prevMessage = chatState.activeMessages[index - 1];
                              if (message.timestamp.day != prevMessage.timestamp.day ||
                                  message.timestamp.month != prevMessage.timestamp.month ||
                                  message.timestamp.year != prevMessage.timestamp.year) {
                                showDateHeader = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateHeader) _buildDateHeader(message.timestamp),
                                _buildMessageBubble(message, isMe, primaryColor),
                              ],
                            );
                          },
                        ),
            ),
            // Input Area
            _buildInputBar(otherUserId, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    String dateText = 'Today';
    if (timestamp.day != now.day || timestamp.month != now.month || timestamp.year != now.year) {
      final difference = now.difference(timestamp);
      if (difference.inDays == 1 || (difference.inDays == 0 && now.day != timestamp.day)) {
        dateText = 'Yesterday';
      } else {
        final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        dateText = '${timestamp.day} ${months[timestamp.month - 1]}';
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, Color userColor) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? userColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isMe ? null : Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF374151),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(int recipientId, Color userColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send Button
          GestureDetector(
            onTap: () => _sendMessage(recipientId),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: userColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.waving_hand_rounded,
              size: 40,
              color: Color(0xFFFFB020),
            ),
            const SizedBox(height: 14),
            Text(
              'Say Hello to ${widget.otherUserName}!',
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start your conversation now.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
