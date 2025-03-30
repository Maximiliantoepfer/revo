import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;

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
      // Load predefined exercises
      final predefinedSnapshot = await _firestore
          .collection('exercises')
          .where('isCustom', isEqualTo: false)
          .get();

      // Load user exercises
      final userSnapshot = await _firestore
          .collection('exercises')
          .where('isCustom', isEqualTo: true)
          .get();

      final predefinedExercises = predefinedSnapshot.docs
          .map((doc) => Exercise.fromJson(doc.data()))
          .toList();

      final userExercises = userSnapshot.docs
          .map((doc) => Exercise.fromJson(doc.data()))
          .toList();

      _exercises = [...predefinedExercises, ...userExercises];

      // If no predefined exercises exist, create them
      if (predefinedExercises.isEmpty) {
        await _createPredefinedExercises();
      }
    } catch (e) {
      _errorMessage = 'Failed to load exercises: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createPredefinedExercises() async {
    final batch = _firestore.batch();
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

    for (final exercise in predefinedExercises) {
      final docRef = _firestore.collection('exercises').doc(exercise.id);
      batch.set(docRef, exercise.toJson());
    }

    await batch.commit();
    _exercises.addAll(predefinedExercises);
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
      final docRef = _firestore.collection('exercises').doc();
      final newExercise = Exercise(
        id: docRef.id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        trackingTypes: trackingTypes,
        isCustom: true,
        userId: userId,
        category: category,
      );

      await docRef.set(newExercise.toJson());
      _exercises.add(newExercise);
      
      _isLoading = false;
      notifyListeners();
      return newExercise;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add exercise: $e';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> updateExercise(Exercise exercise) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('exercises')
          .doc(exercise.id)
          .update(exercise.toJson());

      final index = _exercises.indexWhere((e) => e.id == exercise.id);
      if (index != -1) {
        _exercises[index] = exercise;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update exercise: $e';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('exercises').doc(exerciseId).delete();
      _exercises.removeWhere((e) => e.id == exerciseId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete exercise: $e';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Exercise> getUserExercises(String userId) {
    return _exercises.where((exercise) => exercise.userId == userId).toList();
  }

  List<Exercise> getPredefinedExercises() {
    return _exercises.where((exercise) => !exercise.isCustom).toList();
  }

  Future<void> refreshExercises() async {
    await _loadExercises();
  }
}