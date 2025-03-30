import 'workout.dart';

class TrainingPlan {
  final String id;
  final String name;
  final String description;
  final String userId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Workout> workouts;

  TrainingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.workouts = const [],
  });

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      userId: json['userId'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      workouts: json['workouts'] != null
          ? (json['workouts'] as List).map((w) => Workout.fromJson(w)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'workouts': workouts.map((w) => w.toJson()).toList(),
    };
  }

  TrainingPlan copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Workout>? workouts,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workouts: workouts ?? this.workouts,
    );
  }
}