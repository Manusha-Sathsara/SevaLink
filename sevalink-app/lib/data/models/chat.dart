import 'user.dart';

class ChatRoom {
  final int id;
  final String chatId;
  final User user1;
  final User user2;
  final String lastMessage;
  final DateTime lastMessageTimestamp;

  ChatRoom({
    required this.id,
    required this.chatId,
    required this.user1,
    required this.user2,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? 0,
      chatId: json['chatId'] ?? '',
      user1: User.fromJson(json['user1'] ?? {}),
      user2: User.fromJson(json['user2'] ?? {}),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.parse(json['lastMessageTimestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'user1': {
        'id': user1.id,
        'fullName': user1.fullName,
        'email': user1.email,
        'phoneNumber': user1.phoneNumber,
        'role': user1.role,
      },
      'user2': {
        'id': user2.id,
        'fullName': user2.fullName,
        'email': user2.email,
        'phoneNumber': user2.phoneNumber,
        'role': user2.role,
      },
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
    };
  }

  // Helper method to get the user other than the current logged-in user
  User getOtherUser(int currentUserId) {
    return user1.id == currentUserId ? user2 : user1;
  }
}

class ChatMessage {
  final int id;
  final int chatRoomId;
  final int senderId;
  final int recipientId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      chatRoomId: json['chatRoomId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      recipientId: json['recipientId'] ?? 0,
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
