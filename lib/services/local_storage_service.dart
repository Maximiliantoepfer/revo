import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_plan.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../models/exercise.dart';
import 'dart:developer' as developer;

class LocalStorageService {
  // Keys für SharedPreferences
  static const String _trainingPlansKey = 'training_plans';
  static const String _workoutsKey = 'workouts';
  static const String _workoutLogsKey = 'workout_logs';
  static const String _activeWorkoutLogKey = 'active_workout_log';
  static const String _exercisesKey = 'exercises';

  // Training Plans
  Future<void> saveTrainingPlans(List<TrainingPlan> trainingPlans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = trainingPlans.map((plan) => plan.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_trainingPlansKey, jsonString);
      developer.log('Saved ${trainingPlans.length} training plans');
    } catch (e) {
      developer.log('Error saving training plans: $e', error: e);
      throw Exception('Failed to save training plans: $e');
    }
  }

  Future<List<TrainingPlan>> loadTrainingPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_trainingPlansKey);
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('No training plans found in storage');
        return [];
      }

      final jsonData = jsonDecode(jsonString) as List;
      final plans = jsonData.map((item) => TrainingPlan.fromJson(item)).toList();
      developer.log('Loaded ${plans.length} training plans');
      return plans;
    } catch (e) {
      developer.log('Error loading training plans: $e', error: e);
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Workouts
  Future<void> saveWorkouts(Map<String, List<Workout>> workouts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = {};
      
      workouts.forEach((key, value) {
        jsonData[key] = value.map((workout) => workout.toJson()).toList();
      });
      
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_workoutsKey, jsonString);
      developer.log('Saved workouts for ${workouts.keys.length} training plans');
    } catch (e) {
      developer.log('Error saving workouts: $e', error: e);
      throw Exception('Failed to save workouts: $e');
    }
  }

  Future<Map<String, List<Workout>>> loadWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_workoutsKey);
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('No workouts found in storage');
        return {};
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = <String, List<Workout>>{};
      
      jsonData.forEach((key, value) {
        final workoutList = (value as List)
            .map((item) => Workout.fromJson(item))
            .toList();
        result[key] = workoutList;
      });
      
      developer.log('Loaded workouts for ${result.keys.length} training plans');
      return result;
    } catch (e) {
      developer.log('Error loading workouts: $e', error: e);
      // Return empty map instead of throwing to prevent app crashes
      return {};
    }
  }

  // Workout Logs
  Future<void> saveWorkoutLogs(List<WorkoutLog> workoutLogs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = workoutLogs.map((log) => log.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_workoutLogsKey, jsonString);
      developer.log('Saved ${workoutLogs.length} workout logs');
    } catch (e) {
      developer.log('Error saving workout logs: $e', error: e);
      throw Exception('Failed to save workout logs: $e');
    }
  }

  Future<List<WorkoutLog>> loadWorkoutLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_workoutLogsKey);
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('No workout logs found in storage');
        return [];
      }

      final jsonData = jsonDecode(jsonString) as List;
      final logs = jsonData.map((item) => WorkoutLog.fromJson(item)).toList();
      developer.log('Loaded ${logs.length} workout logs');
      return logs;
    } catch (e) {
      developer.log('Error loading workout logs: $e', error: e);
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Active Workout Log
  Future<void> saveActiveWorkoutLog(WorkoutLog? workoutLog) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (workoutLog == null) {
        await prefs.remove(_activeWorkoutLogKey);
        developer.log('Removed active workout log');
      } else {
        final jsonString = jsonEncode(workoutLog.toJson());
        await prefs.setString(_activeWorkoutLogKey, jsonString);
        developer.log('Saved active workout log: ${workoutLog.id}');
      }
    } catch (e) {
      developer.log('Error saving active workout log: $e', error: e);
      throw Exception('Failed to save active workout log: $e');
    }
  }

  Future<WorkoutLog?> loadActiveWorkoutLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_activeWorkoutLogKey);
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('No active workout log found in storage');
        return null;
      }

      final jsonData = jsonDecode(jsonString);
      final log = WorkoutLog.fromJson(jsonData);
      developer.log('Loaded active workout log: ${log.id}');
      return log;
    } catch (e) {
      developer.log('Error loading active workout log: $e', error: e);
      // Return null instead of throwing to prevent app crashes
      return null;
    }
  }

  // Exercises
  Future<void> saveExercises(List<Exercise> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = exercises.map((exercise) => exercise.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_exercisesKey, jsonString);
      developer.log('Saved ${exercises.length} exercises');
    } catch (e) {
      developer.log('Error saving exercises: $e', error: e);
      throw Exception('Failed to save exercises: $e');
    }
  }

  Future<List<Exercise>> loadExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_exercisesKey);
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('No exercises found in storage');
        return [];
      }

      final jsonData = jsonDecode(jsonString) as List;
      final exercises = jsonData.map((item) => Exercise.fromJson(item)).toList();
      developer.log('Loaded ${exercises.length} exercises');
      return exercises;
    } catch (e) {
      developer.log('Error loading exercises: $e', error: e);
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trainingPlansKey);
      await prefs.remove(_workoutsKey);
      await prefs.remove(_workoutLogsKey);
      await prefs.remove(_activeWorkoutLogKey);
      await prefs.remove(_exercisesKey);
      developer.log('Cleared all local storage data');
    } catch (e) {
      developer.log('Error clearing data: $e', error: e);
      throw Exception('Failed to clear data: $e');
    }
  }
}