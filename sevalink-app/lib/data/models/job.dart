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
    return Job(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      postedAt: json['postedAt'] ?? '',
      minBudget: json['minBudget'] ?? 0,
      maxBudget: json['maxBudget'] ?? 0,
      isNew: json['isNew'] ?? false,
      category: json['category'] ?? '',
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
