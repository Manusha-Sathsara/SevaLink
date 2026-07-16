class WorkerSearchResult {
  final int id;
  final String name;
  final String profession;
  final double rating;
  final int hourlyRate;
  final String location;
  final bool isVerified;
  final String? imageUrl;

  const WorkerSearchResult({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.hourlyRate,
    required this.location,
    required this.isVerified,
    this.imageUrl,
  });

  factory WorkerSearchResult.fromJson(Map<String, dynamic> json) {
    return WorkerSearchResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      profession: json['profession'] as String? ?? json['category'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? json['verified'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String? ?? json['profileImageUrl'] as String?,
    );
  }
}
