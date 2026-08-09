import '../../core/constants/api_endpoints.dart';

/// Rewrites a server-built URL so it is reachable from a physical device.
/// The backend stores image URLs with "localhost" which only works when
/// running in an emulator. On a real device the URL must point to the
/// actual PC IP/host.
String? _rewriteUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  return ApiEndpoints.rewriteImageUrl(url);
}

class WorkerSearchResult {
  final int id;
  final String name;
  final String profession;
  final double rating;
  final int hourlyRate;
  final String location;
  final bool isVerified;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final int totalReviews;
  final int totalJobs;
  final bool isAvailable;
  final String bio;

  const WorkerSearchResult({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.hourlyRate,
    required this.location,
    required this.isVerified,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.totalReviews = 0,
    this.totalJobs = 0,
    this.isAvailable = true,
    this.bio = '',
  });

  int get experienceYears {
    if (bio.isEmpty) return 1;
    final regex = RegExp(r'(\d+)\+?\s*(?:year|yr)', caseSensitive: false);
    final match = regex.firstMatch(bio);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1; // default fallback
  }

  factory WorkerSearchResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final category = json['category'] as Map<String, dynamic>? ?? {};

    return WorkerSearchResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: user['fullName'] as String? ?? 'Unknown',
      profession: category['name'] as String? ?? 'Unknown',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 0,
      location: user['location'] as String? ?? 'Unknown Location',
      isVerified: user['isPhoneVerified'] as bool? ?? false,
      imageUrl: _rewriteUrl(user['profileImageUrl'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      bio: json['bio'] as String? ?? '',
    );
  }
}
