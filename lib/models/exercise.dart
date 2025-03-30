enum TrackingType { repetitions, weight, duration, distance }

enum ExerciseCategory { chest, back, legs, shoulders, arms, core, cardio }

class Exercise {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<TrackingType> trackingTypes;
  final bool isCustom;
  final String? userId; // null for predefined exercises
  final ExerciseCategory category;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.trackingTypes,
    required this.isCustom,
    this.userId,
    required this.category,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      trackingTypes: (json['trackingTypes'] as List)
          .map((type) => TrackingType.values.firstWhere(
              (e) => e.toString() == 'TrackingType.${type}'))
          .toList(),
      isCustom: json['isCustom'],
      userId: json['userId'],
      category: ExerciseCategory.values.firstWhere(
          (e) => e.toString() == 'ExerciseCategory.${json['category']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'trackingTypes': trackingTypes
          .map((type) => type.toString().split('.').last)
          .toList(),
      'isCustom': isCustom,
      'userId': userId,
      'category': category.toString().split('.').last,
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<TrackingType>? trackingTypes,
    bool? isCustom,
    String? userId,
    ExerciseCategory? category,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      trackingTypes: trackingTypes ?? this.trackingTypes,
      isCustom: isCustom ?? this.isCustom,
      userId: userId ?? this.userId,
      category: category ?? this.category,
    );
  }
}