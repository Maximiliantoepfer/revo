import 'package:flutter/material.dart';
import '../models/training_plan.dart';
import '../models/workout.dart';
import 'local_storage_service.dart';
import 'dart:developer' as developer;

class TrainingPlanService extends ChangeNotifier {
  List<TrainingPlan> _trainingPlans = [];
  Map<String, List<Workout>> _workouts = {}; // trainingPlanId -> List<Workout>
  bool _isLoading = false;
  final LocalStorageService _localStorageService = LocalStorageService();

  TrainingPlanService() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trainingPlans = await _localStorageService.loadTrainingPlans();
      _workouts = await _localStorageService.loadWorkouts();
      developer.log('Loaded ${_trainingPlans.length} training plans and workouts for ${_workouts.keys.length} plans');
    } catch (e) {
      developer.log('Error loading training plans: $e', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      await _localStorageService.saveTrainingPlans(_trainingPlans);
      await _localStorageService.saveWorkouts(_workouts);
      developer.log('Saved ${_trainingPlans.length} training plans and workouts for ${_workouts.keys.length} plans');
    } catch (e) {
      developer.log('Error saving training plans: $e', error: e);
    }
  }

  List<TrainingPlan> get trainingPlans => _trainingPlans;
  bool get isLoading => _isLoading;

  Future<List<TrainingPlan>> getUserTrainingPlans(String userId) async {
    final userPlans = _trainingPlans.where((plan) => plan.userId == userId).toList();
    developer.log('Found ${userPlans.length} training plans for user: $userId');
    return userPlans;
  }

  Future<TrainingPlan?> getActiveTrainingPlan(String userId) async {
    try {
      final activePlan = _trainingPlans.firstWhere(
          (plan) => plan.userId == userId && plan.isActive);
      developer.log('Found active training plan for user $userId: ${activePlan.name}');
      return activePlan;
    } catch (e) {
      developer.log('No active training plan found for user: $userId');
      return null;
    }
  }

  Future<List<Workout>> getTrainingPlanWorkouts(String trainingPlanId) async {
    final workouts = _workouts[trainingPlanId] ?? [];
    developer.log('Found ${workouts.length} workouts for training plan: $trainingPlanId');
    return workouts;
  }

  Future<TrainingPlan> createTrainingPlan({
    required String name,
    required String description,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final newTrainingPlan = TrainingPlan(
      id: 'tp_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      userId: userId,
      isActive: _trainingPlans.where((plan) => plan.userId == userId).isEmpty,
      createdAt: now,
      updatedAt: now,
    );

    _trainingPlans.add(newTrainingPlan);
    _workouts[newTrainingPlan.id] = [];

    await _saveData(); // Speichern der Daten
    developer.log('Created new training plan: ${newTrainingPlan.name}');

    _isLoading = false;
    notifyListeners();

    return newTrainingPlan;
  }

  Future<void> updateTrainingPlan(TrainingPlan trainingPlan) async {
    _isLoading = true;
    notifyListeners();

    final index = _trainingPlans.indexWhere((p) => p.id == trainingPlan.id);
    if (index != -1) {
      _trainingPlans[index] = trainingPlan.copyWith(
        updatedAt: DateTime.now(),
      );
      developer.log('Updated training plan: ${trainingPlan.name}');
    } else {
      developer.log('Training plan not found for update: ${trainingPlan.id}');
    }

    await _saveData(); // Speichern der Daten

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTrainingPlan(String trainingPlanId) async {
    _isLoading = true;
    notifyListeners();

    _trainingPlans.removeWhere((p) => p.id == trainingPlanId);
    _workouts.remove(trainingPlanId);

    await _saveData(); // Speichern der Daten
    developer.log('Deleted training plan: $trainingPlanId');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setActiveTrainingPlan(
      String trainingPlanId, String userId) async {
    _isLoading = true;
    notifyListeners();

    // Deactivate all other training plans for this user
    for (int i = 0; i < _trainingPlans.length; i++) {
      if (_trainingPlans[i].userId == userId) {
        final isActive = _trainingPlans[i].id == trainingPlanId;
        _trainingPlans[i] = _trainingPlans[i].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
        if (isActive) {
          developer.log('Set training plan as active: ${_trainingPlans[i].name}');
        }
      }
    }

    await _saveData(); // Speichern der Daten

    _isLoading = false;
    notifyListeners();
  }

  Future<Workout> addWorkout({
    required String name,
    required String description,
    required String trainingPlanId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final newWorkout = Workout(
      id: 'wo_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      exercises: [],
      trainingPlanId: trainingPlanId,
      createdAt: now,
      updatedAt: now,
    );

    if (_workouts.containsKey(trainingPlanId)) {
      _workouts[trainingPlanId]!.add(newWorkout);
    } else {
      _workouts[trainingPlanId] = [newWorkout];
    }

    // Update the training plan's updatedAt timestamp
    final planIndex = _trainingPlans.indexWhere((p) => p.id == trainingPlanId);
    if (planIndex != -1) {
      _trainingPlans[planIndex] = _trainingPlans[planIndex].copyWith(
        updatedAt: now,
      );
    }

    await _saveData(); // Speichern der Daten
    developer.log('Added new workout: ${newWorkout.name} to training plan: $trainingPlanId');

    _isLoading = false;
    notifyListeners();

    return newWorkout;
  }

  Future<void> updateWorkout(Workout workout) async {
    _isLoading = true;
    notifyListeners();

    final workouts = _workouts[workout.trainingPlanId] ?? [];
    final index = workouts.indexWhere((w) => w.id == workout.id);
    
    if (index != -1) {
      workouts[index] = workout.copyWith(
        updatedAt: DateTime.now(),
      );
      _workouts[workout.trainingPlanId] = workouts;

      // Update the training plan's updatedAt timestamp
      final planIndex = _trainingPlans.indexWhere((p) => p.id == workout.trainingPlanId);
      if (planIndex != -1) {
        _trainingPlans[planIndex] = _trainingPlans[planIndex].copyWith(
          updatedAt: DateTime.now(),
        );
      }
      developer.log('Updated workout: ${workout.name}');
    } else {
      developer.log('Workout not found for update: ${workout.id}');
    }

    await _saveData(); // Speichern der Daten

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteWorkout(String workoutId, String trainingPlanId) async {
    _isLoading = true;
    notifyListeners();

    if (_workouts.containsKey(trainingPlanId)) {
      _workouts[trainingPlanId]!.removeWhere((w) => w.id == workoutId);

      // Update the training plan's updatedAt timestamp
      final planIndex = _trainingPlans.indexWhere((p) => p.id == trainingPlanId);
      if (planIndex != -1) {
        _trainingPlans[planIndex] = _trainingPlans[planIndex].copyWith(
          updatedAt: DateTime.now(),
        );
      }
      developer.log('Deleted workout: $workoutId from training plan: $trainingPlanId');
    }

    await _saveData(); // Speichern der Daten

    _isLoading = false;
    notifyListeners();
  }

  Workout? getWorkoutById(String workoutId) {
    for (final workouts in _workouts.values) {
      try {
        final workout = workouts.firstWhere((workout) => workout.id == workoutId);
        return workout;
      } catch (e) {
        // Workout not found in this list, continue searching
      }
    }
    developer.log('Workout not found: $workoutId');
    return null;
  }
}