import 'package:equatable/equatable.dart';
import '../../core/constants/api_endpoints.dart';

class ChatMessageModel extends Equatable {
  final int id;
  final int senderId;
  final String senderName;
  final int receiverId;
  final String receiverName;
  final int? jobPostId;
  final String content;
  final bool isRead;
  final String createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    this.jobPostId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      receiverId: json['receiverId'] ?? 0,
      receiverName: json['receiverName'] ?? '',
      jobPostId: json['jobPostId'],
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, senderId, receiverId, content, createdAt];
}

class ChatConversation extends Equatable {
  final int partnerId;
  final String partnerName;
  final String? partnerProfileImageUrl;
  final String lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  const ChatConversation({
    required this.partnerId,
    required this.partnerName,
    this.partnerProfileImageUrl,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      partnerId: json['partnerId'] ?? 0,
      partnerName: json['partnerName'] ?? '',
      partnerProfileImageUrl: json['partnerProfileImageUrl'] != null && (json['partnerProfileImageUrl'] as String).isNotEmpty
          ? ApiEndpoints.rewriteImageUrl(json['partnerProfileImageUrl'] as String)
          : null,
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
    );
  }

  @override
  List<Object?> get props => [partnerId, partnerName, lastMessage];
}
