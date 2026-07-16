import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String? jobTitle;
  final String? jobBudget;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    this.otherUserName = 'User',
    this.jobTitle,
    this.jobBudget,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await ref.read(chatNotifierProvider(widget.otherUserId).notifier).sendMessage(
          receiverId: widget.otherUserId,
          content: text,
        );
    _scrollToBottom();
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials.isEmpty ? 'U' : initials;
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $amPm';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatNotifierProvider(widget.otherUserId));
    final currentUser = ref.watch(authProvider).user;
    final currentUserId = currentUser?.id ?? 0;

    _scrollToBottom();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(widget.otherUserName),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUserName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length + 1, // +1 for date separator
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildDateSeparator('Today');
                      }
                      final message = messages[index - 1];
                      final isSent = message.senderId == currentUserId;
                      return _buildMessageBubble(message, isSent);
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ),
            ),

          // Job info banner
          if (widget.jobTitle != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobTitle!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (widget.jobBudget != null)
                          Text(
                            'Budget: ${widget.jobBudget}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (text) {
                          // Could trigger typing indicator
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD3410A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
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

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isSent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSent ? Colors.white : const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
