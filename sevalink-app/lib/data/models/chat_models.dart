import 'package:equatable/equatable.dart';

class ChatRoomModel extends Equatable {
  final int id;
  final int otherUserId;
  final String otherUserFullName;
  final String otherUserRole;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatRoomModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserFullName,
    required this.otherUserRole,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] ?? 0,
      otherUserId: json['otherUserId'] ?? 0,
      otherUserFullName: json['otherUserFullName'] ?? '',
      otherUserRole: json['otherUserRole'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt']).toLocal()
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        otherUserId,
        otherUserFullName,
        otherUserRole,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}

class ChatMessageModel extends Equatable {
  final int id;
  final int chatRoomId;
  final int senderId;
  final int recipientId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? 0,
      chatRoomId: json['chatRoom']?['id'] ?? json['chatRoomId'] ?? 0,
      senderId: json['sender']?['id'] ?? json['senderId'] ?? 0,
      recipientId: json['recipient']?['id'] ?? json['recipientId'] ?? 0,
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp']).toLocal()
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatRoomId,
        senderId,
        recipientId,
        content,
        timestamp,
        isRead,
      ];
}
