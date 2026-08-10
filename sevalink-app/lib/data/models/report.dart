// lib/data/models/report.dart
import 'package:equatable/equatable.dart';

enum ReportType {
  FRAUD_OR_SCAM,
  ABUSIVE_BEHAVIOR,
  FAKE_PROFILE,
  SPAM,
  INAPPROPRIATE_CONTENT,
  UNSAFE_BEHAVIOR,
  POLICY_VIOLATION,
  OTHER;

  String get displayName {
    switch (this) {
      case ReportType.FRAUD_OR_SCAM:
        return 'Fraud or Scam';
      case ReportType.ABUSIVE_BEHAVIOR:
        return 'Abusive Behavior';
      case ReportType.FAKE_PROFILE:
        return 'Fake Profile';
      case ReportType.SPAM:
        return 'Spam';
      case ReportType.INAPPROPRIATE_CONTENT:
        return 'Inappropriate Content';
      case ReportType.UNSAFE_BEHAVIOR:
        return 'Unsafe Behavior';
      case ReportType.POLICY_VIOLATION:
        return 'Policy Violation';
      case ReportType.OTHER:
        return 'Other';
    }
  }
}

enum ReportStatus {
  PENDING,
  UNDER_REVIEW,
  ACTION_TAKEN,
  DISMISSED;

  String get displayName {
    switch (this) {
      case ReportStatus.PENDING:
        return 'Pending';
      case ReportStatus.UNDER_REVIEW:
        return 'Under Review';
      case ReportStatus.ACTION_TAKEN:
        return 'Action Taken';
      case ReportStatus.DISMISSED:
        return 'Dismissed';
    }
  }
}

class Report extends Equatable {
  final int id;
  final int reporterId;
  final String reporterName;
  final String reporterEmail;
  final int reportedUserId;
  final String reportedUserName;
  final String reportedUserEmail;
  final int? jobId;
  final String? jobTitle;
  final ReportType reportType;
  final String description;
  final String? evidence;
  final ReportStatus status;
  final String? adminNote;
  final String? actionTaken;
  final String createdAt;
  final String updatedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reportedUserEmail,
    this.jobId,
    this.jobTitle,
    required this.reportType,
    required this.description,
    this.evidence,
    required this.status,
    this.adminNote,
    this.actionTaken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      reporterId: json['reporterId'] ?? 0,
      reporterName: json['reporterName'] ?? '',
      reporterEmail: json['reporterEmail'] ?? '',
      reportedUserId: json['reportedUserId'] ?? 0,
      reportedUserName: json['reportedUserName'] ?? '',
      reportedUserEmail: json['reportedUserEmail'] ?? '',
      jobId: json['jobId'] as int?,
      jobTitle: json['jobTitle'] as String?,
      reportType: ReportType.values.firstWhere(
        (e) => e.name == json['reportType'],
        orElse: () => ReportType.OTHER,
      ),
      description: json['description'] ?? '',
      evidence: json['evidence'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.PENDING,
      ),
      adminNote: json['adminNote'] as String?,
      actionTaken: json['actionTaken'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, reportedUserId, reportType, status, createdAt];
}
