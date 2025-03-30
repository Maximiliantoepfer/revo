import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import '../../models/exercise.dart';

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExerciseCategory _selectedCategory = ExerciseCategory.chest;
  final Map<TrackingType, bool> _selectedTrackingTypes = {
    TrackingType.repetitions: true,
    TrackingType.weight: false,
    TrackingType.duration: false,
    TrackingType.distance: false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createExercise() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);

      if (authService.currentUser == null) return;

      // Get selected tracking types
      final trackingTypes = _selectedTrackingTypes.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (trackingTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one tracking type')),
        );
        return;
      }

      try {
        await exerciseService.addExercise(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          trackingTypes: trackingTypes,
          userId: authService.currentUser!.id,
          category: _selectedCategory,
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating exercise: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseService = Provider.of<ExerciseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exercise'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Bench Press, Squats, etc.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name for your exercise';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExerciseCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ExerciseCategory.values.map((category) {
                    return DropdownMenuItem<ExerciseCategory>(
                      value: category,
                      child: Text(category.toString().split('.').last.capitalize()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the exercise and how to perform it',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
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
                const Text(
                  'Select what you want to track for this exercise:',
                  style: TextStyle(color: Colors.grey),
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
                ElevatedButton(
                  onPressed:
                      exerciseService.isLoading ? null : _createExercise,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: exerciseService.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Exercise'),
                ),
              ],
            ),
          ),
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
}