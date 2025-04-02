import 'package:flutter/material.dart';
import '../models/workout_log.dart';
import '../models/exercise_log.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import 'local_storage_service.dart';
import 'dart:developer' as developer;

class WorkoutLogService extends ChangeNotifier {
  List<WorkoutLog> _workoutLogs = [];
  WorkoutLog? _activeWorkoutLog;
  bool _isLoading = false;
  final LocalStorageService _localStorageService = LocalStorageService();

  WorkoutLogService() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _workoutLogs = await _localStorageService.loadWorkoutLogs();
      _activeWorkoutLog = await _localStorageService.loadActiveWorkoutLog();
      developer.log('Loaded ${_workoutLogs.length} workout logs, active log: ${_activeWorkoutLog?.id ?? "none"}');
    } catch (e) {
      developer.log('Error loading workout logs: $e', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      await _localStorageService.saveWorkoutLogs(_workoutLogs);
      await _localStorageService.saveActiveWorkoutLog(_activeWorkoutLog);
      developer.log('Saved ${_workoutLogs.length} workout logs, active log: ${_activeWorkoutLog?.id ?? "none"}');
    } catch (e) {
      developer.log('Error saving workout logs: $e', error: e);
    }
  }

  List<WorkoutLog> get workoutLogs => _workoutLogs;
  WorkoutLog? get activeWorkoutLog => _activeWorkoutLog;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkout => _activeWorkoutLog != null;

  Future<List<WorkoutLog>> getUserWorkoutLogs(String userId) async {
    final userLogs = _workoutLogs.where((log) => log.userId == userId).toList();
    developer.log('Found ${userLogs.length} workout logs for user: $userId');
    return userLogs;
  }

  Future<List<WorkoutLog>> getWorkoutLogs(String workoutId) async {
    final logs = _workoutLogs.where((log) => log.workoutId == workoutId).toList();
    developer.log('Found ${logs.length} logs for workout: $workoutId');
    return logs;
  }

  Future<WorkoutLog> startWorkout({
    required String workoutId,
    required String userId,
    required Workout workout,
  }) async {
    _isLoading = true;
    notifyListeners();

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

    await _saveData(); // Speichern der Daten
    developer.log('Started new workout: ${workout.name}, log ID: ${newWorkoutLog.id}');

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
    if (_activeWorkoutLog == null) {
      developer.log('Cannot update set log: no active workout');
      return;
    }

    _isLoading = true;
    notifyListeners();

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
        
        developer.log('Updated set $setNumber for exercise log: $exerciseLogId, completed: $isCompleted');
      } else {
        developer.log('Set not found: $setNumber in exercise log: $exerciseLogId');
      }
    } else {
      developer.log('Exercise log not found: $exerciseLogId');
    }

    await _saveData(); // Speichern der Daten

    _isLoading = false;
    notifyListeners();
  }

  Future<void> finishWorkout({String? notes}) async {
    if (_activeWorkoutLog == null) {
      developer.log('Cannot finish workout: no active workout');
      return;
    }

    _isLoading = true;
    notifyListeners();

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

    await _saveData(); // Speichern der Daten
    developer.log('Finished workout: ${updatedWorkoutLog.id}');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelWorkout() async {
    if (_activeWorkoutLog == null) {
      developer.log('Cannot cancel workout: no active workout');
      return;
    }

    _isLoading = true;
    notifyListeners();

    final workoutId = _activeWorkoutLog!.id;
    _workoutLogs.removeWhere((log) => log.id == workoutId);
    _activeWorkoutLog = null;

    await _saveData(); // Speichern der Daten
    developer.log('Canceled workout: $workoutId');

    _isLoading = false;
    notifyListeners();
  }

  WorkoutLog? getWorkoutLogById(String id) {
    try {
      return _workoutLogs.firstWhere((log) => log.id == id);
    } catch (e) {
      developer.log('Workout log not found: $id');
      return null;
    }
  }
}