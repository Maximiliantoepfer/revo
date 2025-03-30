import 'package:flutter/material.dart';
import '../models/training_plan.dart';
import '../models/workout.dart';

class TrainingPlanService extends ChangeNotifier {
  List<TrainingPlan> _trainingPlans = [];
  Map<String, List<Workout>> _workouts = {}; // trainingPlanId -> List<Workout>
  bool _isLoading = false;

  List<TrainingPlan> get trainingPlans => _trainingPlans;
  bool get isLoading => _isLoading;

  Future<List<TrainingPlan>> getUserTrainingPlans(String userId) async {
    return _trainingPlans.where((plan) => plan.userId == userId).toList();
  }

  Future<TrainingPlan?> getActiveTrainingPlan(String userId) async {
    try {
      return _trainingPlans.firstWhere(
          (plan) => plan.userId == userId && plan.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<List<Workout>> getTrainingPlanWorkouts(String trainingPlanId) async {
    return _workouts[trainingPlanId] ?? [];
  }

  Future<TrainingPlan> createTrainingPlan({
    required String name,
    required String description,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would save this to a database or API
    await Future.delayed(const Duration(seconds: 1));

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

    _isLoading = false;
    notifyListeners();

    return newTrainingPlan;
  }

  Future<void> updateTrainingPlan(TrainingPlan trainingPlan) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would update this in a database or API
    await Future.delayed(const Duration(seconds: 1));

    final index = _trainingPlans.indexWhere((p) => p.id == trainingPlan.id);
    if (index != -1) {
      _trainingPlans[index] = trainingPlan.copyWith(
        updatedAt: DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTrainingPlan(String trainingPlanId) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would delete this from a database or API
    await Future.delayed(const Duration(seconds: 1));

    _trainingPlans.removeWhere((p) => p.id == trainingPlanId);
    _workouts.remove(trainingPlanId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setActiveTrainingPlan(
      String trainingPlanId, String userId) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would update this in a database or API
    await Future.delayed(const Duration(seconds: 1));

    // Deactivate all other training plans for this user
    for (int i = 0; i < _trainingPlans.length; i++) {
      if (_trainingPlans[i].userId == userId) {
        _trainingPlans[i] = _trainingPlans[i].copyWith(
          isActive: _trainingPlans[i].id == trainingPlanId,
          updatedAt: DateTime.now(),
        );
      }
    }

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

    // In a real app, you would save this to a database or API
    await Future.delayed(const Duration(seconds: 1));

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

    _isLoading = false;
    notifyListeners();

    return newWorkout;
  }

  Future<void> updateWorkout(Workout workout) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would update this in a database or API
    await Future.delayed(const Duration(seconds: 1));

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
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteWorkout(String workoutId, String trainingPlanId) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you would delete this from a database or API
    await Future.delayed(const Duration(seconds: 1));

    if (_workouts.containsKey(trainingPlanId)) {
      _workouts[trainingPlanId]!.removeWhere((w) => w.id == workoutId);

      // Update the training plan's updatedAt timestamp
      final planIndex = _trainingPlans.indexWhere((p) => p.id == trainingPlanId);
      if (planIndex != -1) {
        _trainingPlans[planIndex] = _trainingPlans[planIndex].copyWith(
          updatedAt: DateTime.now(),
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Workout? getWorkoutById(String workoutId) {
    for (final workouts in _workouts.values) {
      try {
        return workouts.firstWhere((workout) => workout.id == workoutId);
      } catch (e) {
        // Workout not found in this list, continue searching
      }
    }
    return null;
  }
}