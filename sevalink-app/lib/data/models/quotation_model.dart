import 'package:equatable/equatable.dart';
import '../../core/constants/api_endpoints.dart';

class Quotation extends Equatable {
  final int id;
  final int jobPostId;
  final String jobTitle;
  final int workerId;
  final int workerUserId;
  final String workerName;
  final String workerAvatar; // Fallback or empty if not provided
  final String workerProfession;
  final double workerRating;
  final int workerReviewCount;
  final String workerLocation;
  final int workerExperienceYears;
  final String workerSkills;
  final int workerTotalJobs;
  final String workerBio;
  
  final String message;
  final double proposedPrice;
  final String eta;
  final String status;
  final String createdAt;

  const Quotation({
    required this.id,
    required this.jobPostId,
    required this.jobTitle,
    required this.workerId,
    required this.workerUserId,
    required this.workerName,
    required this.workerAvatar,
    required this.workerProfession,
    required this.workerRating,
    required this.workerReviewCount,
    required this.workerLocation,
    required this.workerExperienceYears,
    required this.workerSkills,
    required this.workerTotalJobs,
    required this.workerBio,
    required this.message,
    required this.proposedPrice,
    required this.eta,
    required this.status,
    required this.createdAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final workerJson = json['worker'] ?? {};
    final userJson = workerJson['user'] ?? {};
    final jobJson = json['jobPost'] ?? {};

    return Quotation(
      id: json['id'] ?? 0,
      jobPostId: jobJson['id'] ?? 0,
      jobTitle: jobJson['title'] ?? '',
      workerId: workerJson['id'] ?? 0,
      workerUserId: userJson['id'] ?? 0,
      workerName: userJson['fullName'] ?? 'Unknown Worker',
      workerAvatar: (userJson['profileImageUrl'] != null && (userJson['profileImageUrl'] as String).isNotEmpty)
          ? ApiEndpoints.rewriteImageUrl(userJson['profileImageUrl'] as String)
          : '',
      workerProfession: workerJson['category'] is Map ? (workerJson['category']['name'] ?? 'Professional') : 'Professional',
      workerRating: (workerJson['rating'] ?? 0.0).toDouble(),
      workerReviewCount: workerJson['totalJobs'] ?? 0,
      workerLocation: userJson['location'] ?? 'Unknown Location',
      workerExperienceYears: workerJson['experienceYears'] ?? 0,
      workerSkills: workerJson['skills'] ?? '',
      workerTotalJobs: workerJson['totalJobs'] ?? 0,
      workerBio: workerJson['bio'] ?? '',
      message: json['message'] ?? '',
      proposedPrice: (json['proposedPrice'] ?? 0).toDouble(),
      eta: json['eta'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'proposedPrice': proposedPrice,
        'eta': eta,
        'status': status,
        'createdAt': createdAt,
      };

  @override
  List<Object?> get props => [
        id,
        jobPostId,
        workerId,
        workerUserId,
        message,
        proposedPrice,
        eta,
        status,
        createdAt,
      ];
}
