
import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final int id;
  final String title;
  final String description;
  final String location;
  final String postedAt;
  final int minBudget;
  final int maxBudget;
  final bool isNew;
  final String category;
  final double? distanceKm;
  final String clientName;
  final String? clientPhone;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.postedAt,
    required this.minBudget,
    required this.maxBudget,
    required this.isNew,
    required this.category,
    this.distanceKm,
    this.clientName = 'Client',
    this.clientPhone,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // Compute a relative "posted ago" string from createdAt if available
    String postedAt = json['postedAt'] ?? '';
    if (postedAt.isEmpty && json['createdAt'] != null) {
      try {
        final created = DateTime.parse(json['createdAt']);
        final diff = DateTime.now().difference(created);
        if (diff.inDays > 0) {
          postedAt = '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          postedAt = '${diff.inHours}h ago';
        } else {
          postedAt = '${diff.inMinutes}m ago';
        }
      } catch (_) {
        postedAt = '';
      }
    }

    final clientMap = json['client'] as Map<String, dynamic>?;
    final clientName = clientMap?['fullName'] ?? 'Client';
    final clientPhone = clientMap?['phoneNumber'] as String?;

    return Job(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['locationName'] ?? json['location'] ?? '',
      postedAt: postedAt,
      minBudget: (json['budgetMin'] ?? json['minBudget'] ?? 0).toInt(),
      maxBudget: (json['budgetMax'] ?? json['maxBudget'] ?? 0).toInt(),
      isNew: json['isNew'] ?? (json['status'] == 'OPEN'),
      category: json['category'] is Map ? (json['category']['name'] ?? '') : (json['category'] ?? ''),
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
      clientName: clientName,
      clientPhone: clientPhone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'postedAt': postedAt,
        'minBudget': minBudget,
        'maxBudget': maxBudget,
        'isNew': isNew,
        'category': category,
        'distanceKm': distanceKm,
        'clientName': clientName,
        'clientPhone': clientPhone,
      };

  @override
  List<Object?> get props =>
      [id, title, description, location, postedAt, minBudget, maxBudget, isNew, category, distanceKm, clientName, clientPhone];
}
