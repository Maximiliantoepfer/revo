import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'local_storage_service.dart';
import 'dart:developer' as developer;

class ExerciseService extends ChangeNotifier {
  // Wir behalten die Firestore-Referenz für den Fall, dass wir später wieder auf Firestore umstellen wollen
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;
  final LocalStorageService _localStorageService = LocalStorageService();

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ExerciseService() {
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Versuche, Übungen aus dem lokalen Speicher zu laden
      _exercises = await _localStorageService.loadExercises();
      developer.log('Loaded ${_exercises.length} exercises from local storage');

      // Wenn keine Übungen vorhanden sind, erstelle vordefinierte Übungen
      if (_exercises.isEmpty) {
        developer.log('No exercises found, creating predefined exercises');
        await _createPredefinedExercises();
      }
    } catch (e) {
      _errorMessage = 'Failed to load exercises: $e';
      developer.log(_errorMessage!, error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveExercises() async {
    try {
      await _localStorageService.saveExercises(_exercises);
      developer.log('Saved ${_exercises.length} exercises to local storage');
    } catch (e) {
      _errorMessage = 'Failed to save exercises: $e';
      developer.log(_errorMessage!, error: e);
    }
  }

  Future<void> _createPredefinedExercises() async {
    final predefinedExercises = [
      Exercise(
        id: 'ex1',
        name: 'Push-ups',
        description: 'A classic bodyweight exercise for chest, shoulders, and triceps.',
        imageUrl: 'assets/images/pushup.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.duration],
        isCustom: false,
        category: ExerciseCategory.chest,
      ),
      Exercise(
        id: 'ex2',
        name: 'Pull-ups',
        description: 'A compound upper body exercise that targets the back and biceps.',
        imageUrl: 'assets/images/pullup.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.weight],
        isCustom: false,
        category: ExerciseCategory.back,
      ),
      Exercise(
        id: 'ex3',
        name: 'Squats',
        description: 'A compound lower body exercise that targets the quadriceps, hamstrings, and glutes.',
        imageUrl: 'assets/images/squat.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.weight],
        isCustom: false,
        category: ExerciseCategory.legs,
      ),
      Exercise(
        id: 'ex4',
        name: 'Deadlifts',
        description: 'A compound exercise that targets the lower back, glutes, and hamstrings.',
        imageUrl: 'assets/images/deadlift.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.weight],
        isCustom: false,
        category: ExerciseCategory.back,
      ),
      Exercise(
        id: 'ex5',
        name: 'Bench Press',
        description: 'A compound upper body exercise that targets the chest, shoulders, and triceps.',
        imageUrl: 'assets/images/benchpress.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.weight],
        isCustom: false,
        category: ExerciseCategory.chest,
      ),
      Exercise(
        id: 'ex6',
        name: 'Lunges',
        description: 'A unilateral lower body exercise that targets the quadriceps, hamstrings, and glutes.',
        imageUrl: 'assets/images/lunge.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.weight],
        isCustom: false,
        category: ExerciseCategory.legs,
      ),
      Exercise(
        id: 'ex7',
        name: 'Plank',
        description: 'A core exercise that targets the abdominals and lower back.',
        imageUrl: 'assets/images/plank.jpg',
        trackingTypes: [TrackingType.duration],
        isCustom: false,
        category: ExerciseCategory.core,
      ),
      Exercise(
        id: 'ex8',
        name: 'Dips',
        description: 'A compound upper body exercise that targets the chest, shoulders, and triceps.',
        imageUrl: 'assets/images/dips.jpg',
        trackingTypes: [TrackingType.repetitions, TrackingType.weight],
        isCustom: false,
        category: ExerciseCategory.arms,
      ),
    ];

    developer.log('Adding ${predefinedExercises.length} predefined exercises');
    _exercises.addAll(predefinedExercises);
    await _saveExercises();
    notifyListeners();
  }

  Future<Exercise> addExercise({
    required String name,
    required String description,
    String? imageUrl,
    required List<TrackingType> trackingTypes,
    required String userId,
    required ExerciseCategory category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final newExercise = Exercise(
        id: 'ex_${now.millisecondsSinceEpoch}',
        name: name,
        description: description,
        imageUrl: imageUrl,
        trackingTypes: trackingTypes,
        isCustom: true,
        userId: userId,
        category: category,
      );

      _exercises.add(newExercise);
      await _saveExercises();
      developer.log('Added new exercise: ${newExercise.name}');
      
      _isLoading = false;
      notifyListeners();
      return newExercise;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add exercise: $e';
      developer.log(_errorMessage!, error: e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> updateExercise(Exercise exercise) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final index = _exercises.indexWhere((e) => e.id == exercise.id);
      if (index != -1) {
        _exercises[index] = exercise;
        await _saveExercises();
        developer.log('Updated exercise: ${exercise.name}');
      } else {
        developer.log('Exercise not found for update: ${exercise.id}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update exercise: $e';
      developer.log(_errorMessage!, error: e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _exercises.removeWhere((e) => e.id == exerciseId);
      await _saveExercises();
      developer.log('Deleted exercise: $exerciseId');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete exercise: $e';
      developer.log(_errorMessage!, error: e);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      developer.log('Exercise not found: $id', error: e);
      return null;
    }
  }

  List<Exercise> getUserExercises(String userId) {
    final userExercises = _exercises.where((exercise) => exercise.userId == userId).toList();
    developer.log('Found ${userExercises.length} exercises for user: $userId');
    return userExercises;
  }

  List<Exercise> getPredefinedExercises() {
    final predefinedExercises = _exercises.where((exercise) => !exercise.isCustom).toList();
    developer.log('Found ${predefinedExercises.length} predefined exercises');
    return predefinedExercises;
  }

  Future<void> refreshExercises() async {
    developer.log('Refreshing exercises');
    await _loadExercises();
  }
}