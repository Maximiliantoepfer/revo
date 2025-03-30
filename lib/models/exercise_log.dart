import 'exercise.dart';

class ExerciseLog {
  final String id;
  final String exerciseId;
  final String workoutLogId;
  final List<SetLog> sets;
  final DateTime timestamp;

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.workoutLogId,
    required this.sets,
    required this.timestamp,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'],
      exerciseId: json['exerciseId'],
      workoutLogId: json['workoutLogId'],
      sets: (json['sets'] as List).map((s) => SetLog.fromJson(s)).toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'workoutLogId': workoutLogId,
      'sets': sets.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SetLog {
  final String id;
  final int setNumber;
  final Map<TrackingType, dynamic> values; // e.g. {repetitions: 12, weight: 50}
  final bool isCompleted;

  SetLog({
    required this.id,
    required this.setNumber,
    required this.values,
    required this.isCompleted,
  });

  factory SetLog.fromJson(Map<String, dynamic> json) {
    Map<TrackingType, dynamic> values = {};
    (json['values'] as Map<String, dynamic>).forEach((key, value) {
      values[TrackingType.values.firstWhere(
          (e) => e.toString() == 'TrackingType.$key')] = value;
    });

    return SetLog(
      id: json['id'],
      setNumber: json['setNumber'],
      values: values,
      isCompleted: json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> valuesJson = {};
    values.forEach((key, value) {
      valuesJson[key.toString().split('.').last] = value;
    });

    return {
      'id': id,
      'setNumber': setNumber,
      'values': valuesJson,
      'isCompleted': isCompleted,
    };
  }

  SetLog copyWith({
    String? id,
    int? setNumber,
    Map<TrackingType, dynamic>? values,
    bool? isCompleted,
  }) {
    return SetLog(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      values: values ?? this.values,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}