import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/training_plan_service.dart';
import '../../models/training_plan.dart';
import '../../models/workout.dart';
import '../workout/create_workout_screen.dart';
import '../workout/edit_workout_screen.dart';

class TrainingPlanScreen extends StatefulWidget {
  final String trainingPlanId;

  const TrainingPlanScreen({super.key, required this.trainingPlanId});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingPlanService>(
      builder: (context, trainingPlanService, child) {
        final trainingPlan = trainingPlanService.trainingPlans
            .firstWhere((plan) => plan.id == widget.trainingPlanId);

        // Initialize controllers if not in editing mode
        if (!_isEditing) {
          _nameController.text = trainingPlan.name;
          _descriptionController.text = trainingPlan.description;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Training Plan' : trainingPlan.name),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              if (_isEditing) _buildEditForm(trainingPlan, trainingPlanService),
              if (!_isEditing) _buildTrainingPlanDetails(trainingPlan),
              const Divider(),
              Expanded(
                child: _buildWorkoutsList(trainingPlanService, trainingPlan),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateWorkoutScreen(
                    trainingPlanId: widget.trainingPlanId,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEditForm(
      TrainingPlan trainingPlan, TrainingPlanService trainingPlanService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nameController.text = trainingPlan.name;
                    _descriptionController.text = trainingPlan.description;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final updatedTrainingPlan = trainingPlan.copyWith(
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                  );

                  await trainingPlanService
                      .updateTrainingPlan(updatedTrainingPlan);

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
    );
  }

  Widget _buildTrainingPlanDetails(TrainingPlan trainingPlan) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trainingPlan.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trainingPlan.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDate(trainingPlan.createdAt)}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            'Last updated: ${_formatDate(trainingPlan.updatedAt)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList(
      TrainingPlanService trainingPlanService, TrainingPlan trainingPlan) {
    return FutureBuilder<List<Workout>>(
      future: trainingPlanService.getTrainingPlanWorkouts(trainingPlan.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data ?? [];

        if (workouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No workouts yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add your first workout to get started',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workouts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(workout.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(workout.description),
                            const SizedBox(height: 4),
                            Text(
                              '${workout.exercises.length} exercises',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditWorkoutScreen(
                                      workoutId: workout.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteWorkoutDialog(workout);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditWorkoutScreen(
                                workoutId: workout.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteWorkoutDialog(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text(
            'Are you sure you want to delete "${workout.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final trainingPlanService =
                  Provider.of<TrainingPlanService>(context, listen: false);
              await trainingPlanService.deleteWorkout(
                  workout.id, workout.trainingPlanId);
              if (mounted) {
                Navigator.pop(context);
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}