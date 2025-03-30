import 'exercise.dart';

class WorkoutExercise {
  final String id;
  final Exercise exercise;
  final int sets;
  final Map<TrackingType, dynamic> defaultValues; // e.g. {repetitions: 12, weight: 50}
  final int orderIndex; // position in workout
  final String notes;

  WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.defaultValues,
    required this.orderIndex,
    this.notes = '',
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    Map<TrackingType, dynamic> defaultValues = {};
    (json['defaultValues'] as Map<String, dynamic>).forEach((key, value) {
      defaultValues[TrackingType.values.firstWhere(
          (e) => e.toString() == 'TrackingType.$key')] = value;
    });

    return WorkoutExercise(
      id: json['id'],
      exercise: Exercise.fromJson(json['exercise']),
      sets: json['sets'],
      defaultValues: defaultValues,
      orderIndex: json['orderIndex'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> defaultValuesJson = {};
    defaultValues.forEach((key, value) {
      defaultValuesJson[key.toString().split('.').last] = value;
    });

    return {
      'id': id,
      'exercise': exercise.toJson(),
      'sets': sets,
      'defaultValues': defaultValuesJson,
      'orderIndex': orderIndex,
      'notes': notes,
    };
  }

  WorkoutExercise copyWith({
    String? id,
    Exercise? exercise,
    int? sets,
    Map<TrackingType, dynamic>? defaultValues,
    int? orderIndex,
    String? notes,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      defaultValues: defaultValues ?? this.defaultValues,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
    );
  }
}