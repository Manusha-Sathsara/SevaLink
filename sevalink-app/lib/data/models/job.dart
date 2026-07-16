// lib/data/models/job.dart
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
      };

  @override
  List<Object?> get props =>
      [id, title, description, location, postedAt, minBudget, maxBudget, isNew, category];
}
