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
  final int? clientId;
  final String? clientName;

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
    this.clientId,
    this.clientName,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final clientJson = json['client'] as Map<String, dynamic>?;
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
      clientId: clientJson != null ? clientJson['id'] as int? : json['clientId'] as int?,
      clientName: clientJson != null ? clientJson['fullName'] as String? : json['clientName'] as String?,
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
        'clientId': clientId,
        'clientName': clientName,
      };

  @override
  List<Object?> get props =>
      [id, title, description, location, postedAt, minBudget, maxBudget, isNew, category, clientId, clientName];
}
