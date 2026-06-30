class NotificationModel {
  final int id;
  final int workerId;
  final String title;
  final String message;
  final int? relatedJobId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.workerId,
    required this.title,
    required this.message,
    this.relatedJobId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      workerId: json['user']?['id'] ?? 0, // In backend it's mapped to user
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedJobId: json['jobPost']?['id'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
