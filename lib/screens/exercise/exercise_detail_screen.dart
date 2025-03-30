import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import '../../models/exercise.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<TrackingType, bool> _selectedTrackingTypes = {
    TrackingType.repetitions: false,
    TrackingType.weight: false,
    TrackingType.duration: false,
    TrackingType.distance: false,
  };
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExerciseService, AuthService>(
      builder: (context, exerciseService, authService, child) {
        final exercise = exerciseService.getExerciseById(widget.exerciseId);

        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Exercise not found')),
          );
        }

        // Initialize controllers and tracking types if not in editing mode
        if (!_isEditing) {
          _nameController.text = exercise.name;
          _descriptionController.text = exercise.description;

          for (final type in TrackingType.values) {
            _selectedTrackingTypes[type] =
                exercise.trackingTypes.contains(type);
          }
        }

        final canEdit = exercise.isCustom &&
            exercise.userId == authService.currentUser?.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Exercise' : exercise.name),
            actions: [
              if (canEdit && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              if (canEdit && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteExerciseDialog(exercise, exerciseService);
                  },
                ),
            ],
          ),
          body: _isEditing
              ? _buildEditForm(exercise, exerciseService)
              : _buildExerciseDetails(exercise),
        );
      },
    );
  }

  Widget _buildExerciseDetails(Exercise exercise) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.imageUrl != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  exercise.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tracking Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...exercise.trackingTypes.map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    _getTrackingTypeLabel(type),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          if (exercise.isCustom)
            Text(
              'Custom exercise created by you',
              style: const TextStyle(color: Colors.grey),
            )
          else
            const Text(
              'Predefined exercise',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm(Exercise exercise, ExerciseService exerciseService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tracking Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTrackingTypeCheckbox(
              TrackingType.repetitions,
              'Repetitions',
              'Track the number of repetitions',
            ),
            _buildTrackingTypeCheckbox(
              TrackingType.weight,
              'Weight',
              'Track the weight used',
            ),
            _buildTrackingTypeCheckbox(
              TrackingType.duration,
              'Duration',
              'Track how long the exercise is performed',
            ),
            _buildTrackingTypeCheckbox(
              TrackingType.distance,
              'Distance',
              'Track the distance covered',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = exercise.name;
                      _descriptionController.text = exercise.description;

                      for (final type in TrackingType.values) {
                        _selectedTrackingTypes[type] =
                            exercise.trackingTypes.contains(type);
                      }
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    // Get selected tracking types
                    final trackingTypes = _selectedTrackingTypes.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();

                    if (trackingTypes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please select at least one tracking type')),
                      );
                      return;
                    }

                    final updatedExercise = exercise.copyWith(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      trackingTypes: trackingTypes,
                    );

                    await exerciseService.updateExercise(updatedExercise);

                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTypeCheckbox(
      TrackingType type, String title, String subtitle) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: _selectedTrackingTypes[type],
      onChanged: (value) {
        setState(() {
          _selectedTrackingTypes[type] = value ?? false;
        });
      },
    );
  }

  void _showDeleteExerciseDialog(
      Exercise exercise, ExerciseService exerciseService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
            'Are you sure you want to delete "${exercise.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await exerciseService.deleteExercise(exercise.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getTrackingTypeLabel(TrackingType type) {
    switch (type) {
      case TrackingType.repetitions:
        return 'Repetitions';
      case TrackingType.weight:
        return 'Weight';
      case TrackingType.duration:
        return 'Duration';
      case TrackingType.distance:
        return 'Distance';
    }
  }
}