import 'package:flutter/material.dart';
import '../models/workout_log.dart';
import '../models/exercise_log.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutLogService extends ChangeNotifier {
  List<WorkoutLog> _workoutLogs = [];
  WorkoutLog? _activeWorkoutLog;
  bool _isLoading = false;

  List<WorkoutLog> get workoutLogs => _workoutLogs;
  WorkoutLog? get activeWorkoutLog => _activeWorkoutLog;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkout => _activeWorkoutLog != null;

  Future<List<WorkoutLog>> getUserWorkoutLogs(String userId) async {
    return _workoutLogs.where((log) => log.userId == userId).toList();
  }

  Future<List<WorkoutLog>> getWorkoutLogs(String workoutId) async {
    return _workoutLogs.where((log) => log.workoutId == workoutId).toList();
  }

  Future<WorkoutLog> startWorkout({
    required String workoutId,
    required String userId,
    required Workout workout,
  }) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would save this to a database or API
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();
    final newWorkoutLog = WorkoutLog(
      id: 'wl_${now.millisecondsSinceEpoch}',
      workoutId: workoutId,
      userId: userId,
      startTime: now,
      exerciseLogs: _createInitialExerciseLogs(workout),
    );

    _workoutLogs.add(newWorkoutLog);
    _activeWorkoutLog = newWorkoutLog;

    _isLoading = false;
    notifyListeners();

    return newWorkoutLog;
  }

  List<ExerciseLog> _createInitialExerciseLogs(Workout workout) {
    final now = DateTime.now();
    return workout.exercises.map((workoutExercise) {
      return ExerciseLog(
        id: 'el_${now.millisecondsSinceEpoch}_${workoutExercise.id}',
        exerciseId: workoutExercise.exercise.id,
        workoutLogId: 'wl_${now.millisecondsSinceEpoch}',
        sets: List.generate(
          workoutExercise.sets,
          (index) => SetLog(
            id: 'sl_${now.millisecondsSinceEpoch}_${workoutExercise.id}_$index',
            setNumber: index + 1,
            values: Map.from(workoutExercise.defaultValues),
            isCompleted: false,
          ),
        ),
        timestamp: now,
      );
    }).toList();
  }

  Future<void> updateSetLog({
    required String exerciseLogId,
    required int setNumber,
    required Map<TrackingType, dynamic> values,
    required bool isCompleted,
  }) async {
    if (_activeWorkoutLog == null) return;

    _isLoading = true;
    notifyListeners();

    // In a real app, you would update this in a database or API
    await Future.delayed(const Duration(milliseconds: 300));

    final exerciseLogIndex = _activeWorkoutLog!.exerciseLogs
        .indexWhere((log) => log.id == exerciseLogId);

    if (exerciseLogIndex != -1) {
      final exerciseLog = _activeWorkoutLog!.exerciseLogs[exerciseLogIndex];
      final setIndex =
          exerciseLog.sets.indexWhere((set) => set.setNumber == setNumber);

      if (setIndex != -1) {
        final updatedSets = List<SetLog>.from(exerciseLog.sets);
        updatedSets[setIndex] = updatedSets[setIndex].copyWith(
          values: values,
          isCompleted: isCompleted,
        );

        final updatedExerciseLogs =
            List<ExerciseLog>.from(_activeWorkoutLog!.exerciseLogs);
        updatedExerciseLogs[exerciseLogIndex] = ExerciseLog(
          id: exerciseLog.id,
          exerciseId: exerciseLog.exerciseId,
          workoutLogId: exerciseLog.workoutLogId,
          sets: updatedSets,
          timestamp: exerciseLog.timestamp,
        );

        _activeWorkoutLog = _activeWorkoutLog!.copyWith(
          exerciseLogs: updatedExerciseLogs,
        );

        // Update the workout log in the list
        final logIndex =
            _workoutLogs.indexWhere((log) => log.id == _activeWorkoutLog!.id);
        if (logIndex != -1) {
          _workoutLogs[logIndex] = _activeWorkoutLog!;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> finishWorkout({String? notes}) async {
    if (_activeWorkoutLog == null) return;

    _isLoading = true;
    notifyListeners();

    // In a real app, you would update this in a database or API
    await Future.delayed(const Duration(seconds: 1));

    final updatedWorkoutLog = _activeWorkoutLog!.copyWith(
      endTime: DateTime.now(),
      notes: notes,
    );

    final logIndex =
        _workoutLogs.indexWhere((log) => log.id == _activeWorkoutLog!.id);
    if (logIndex != -1) {
      _workoutLogs[logIndex] = updatedWorkoutLog;
    }

    _activeWorkoutLog = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelWorkout() async {
    if (_activeWorkoutLog == null) return;

    _isLoading = true;
    notifyListeners();

    // In a real app, you would delete this from a database or API
    await Future.delayed(const Duration(seconds: 1));

    _workoutLogs.removeWhere((log) => log.id == _activeWorkoutLog!.id);
    _activeWorkoutLog = null;

    _isLoading = false;
    notifyListeners();
  }

  WorkoutLog? getWorkoutLogById(String id) {
    try {
      return _workoutLogs.firstWhere((log) => log.id == id);
    } catch (e) {
      return null;
    }
  }
}