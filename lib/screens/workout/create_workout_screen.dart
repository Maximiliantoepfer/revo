import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/training_plan_service.dart';
import 'edit_workout_screen.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final String trainingPlanId;

  const CreateWorkoutScreen({super.key, required this.trainingPlanId});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createWorkout() async {
    if (_formKey.currentState!.validate()) {
      final trainingPlanService =
          Provider.of<TrainingPlanService>(context, listen: false);

      try {
        final workout = await trainingPlanService.addWorkout(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          trainingPlanId: widget.trainingPlanId,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EditWorkoutScreen(
                workoutId: workout.id,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating workout: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainingPlanService = Provider.of<TrainingPlanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Push Day, Leg Day, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your workout';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your workout',
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
              ElevatedButton(
                onPressed:
                    trainingPlanService.isLoading ? null : _createWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: trainingPlanService.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}