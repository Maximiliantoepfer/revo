import 'exercise_log.dart';

class WorkoutLog {
  final String id;
  final String workoutId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<ExerciseLog> exerciseLogs;
  final String notes;

  WorkoutLog({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.exerciseLogs,
    this.notes = '',
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'],
      workoutId: json['workoutId'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      exerciseLogs: (json['exerciseLogs'] as List)
          .map((e) => ExerciseLog.fromJson(e))
          .toList(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  WorkoutLog copyWith({
    String? id,
    String? workoutId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    List<ExerciseLog>? exerciseLogs,
    String? notes,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      notes: notes ?? this.notes,
    );
  }
}