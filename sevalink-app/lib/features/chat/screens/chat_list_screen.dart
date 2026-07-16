import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/chat_provider.dart';
import '../../../data/models/chat_message.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int _currentNavIndex = 2; // Chat tab

  void _onNavTapped(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        context.go('/client/home');
        break;
      case 1:
        context.go('/client/jobs');
        break;
      case 2:
        break; // Already here
      case 3:
        context.go('/client/profile');
        break;
    }
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

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Orange header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD3410A), Color(0xFFE8520B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/client/home'),
                    ),
                    const Expanded(
                      child: Text(
                        'Messages',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conversations list
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) => conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start chatting with workers!',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) => _buildConversationTile(conversations[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD3410A))),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    return InkWell(
      onTap: () {
        context.push('/client/chat/${conversation.partnerId}',
            extra: {'name': conversation.partnerName});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8520B).withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(conversation.partnerName),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFD3410A),
                      ),
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.partnerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _timeAgo(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD3410A),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFFD3410A),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, height: 1.5),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.work_outline_rounded)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.work_rounded)),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_outline_rounded)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_rounded)),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline_rounded)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
