import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/training_plan_service.dart';
import '../../services/exercise_service.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/exercise.dart';
import '../exercise/exercise_list_screen.dart';
import 'workout_screen.dart';

class EditWorkoutScreen extends StatefulWidget {
  final String workoutId;

  const EditWorkoutScreen({super.key, required this.workoutId});

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
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
        final workout = trainingPlanService.getWorkoutById(widget.workoutId);

        if (workout == null) {
          return const Scaffold(
            body: Center(child: Text('Workout not found')),
          );
        }

        // Initialize controllers if not in editing mode
        if (!_isEditing) {
          _nameController.text = workout.name;
          _descriptionController.text = workout.description;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Workout' : workout.name),
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
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutScreen(
                          workoutId: workout.id,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              if (_isEditing)
                _buildEditForm(workout, trainingPlanService),
              if (!_isEditing) _buildWorkoutDetails(workout),
              const Divider(),
              Expanded(
                child: _buildExercisesList(workout, trainingPlanService),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseListScreen(
                    selectionMode: true,
                  ),
                ),
              );

              if (result != null && result is Exercise) {
                _showAddExerciseDialog(result, workout, trainingPlanService);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEditForm(
      Workout workout, TrainingPlanService trainingPlanService) {
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
                    _nameController.text = workout.name;
                    _descriptionController.text = workout.description;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final updatedWorkout = workout.copyWith(
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                  );

                  await trainingPlanService.updateWorkout(updatedWorkout);

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

  Widget _buildWorkoutDetails(Workout workout) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workout.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workout.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDate(workout.createdAt)}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            'Last updated: ${_formatDate(workout.updatedAt)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
      Workout workout, TrainingPlanService trainingPlanService) {
    if (workout.exercises.isEmpty) {
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
              'No exercises yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add exercises to your workout',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: workout.exercises.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final exercises = List<WorkoutExercise>.from(workout.exercises);
          final item = exercises.removeAt(oldIndex);
          exercises.insert(newIndex, item);

          // Update order indices
          for (int i = 0; i < exercises.length; i++) {
            exercises[i] = exercises[i].copyWith(orderIndex: i);
          }

          final updatedWorkout = workout.copyWith(exercises: exercises);
          trainingPlanService.updateWorkout(updatedWorkout);
        });
      },
      itemBuilder: (context, index) {
        final exercise = workout.exercises[index];
        return Card(
          key: Key(exercise.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: exercise.exercise.imageUrl != null
                ? CircleAvatar(
                    backgroundImage:
                        AssetImage(exercise.exercise.imageUrl!),
                  )
                : CircleAvatar(
                    child: Text(exercise.exercise.name[0]),
                  ),
            title: Text(exercise.exercise.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sets: ${exercise.sets}'),
                Text(_getTrackingInfo(exercise)),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditExerciseDialog(
                        exercise, workout, trainingPlanService);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteExerciseDialog(
                        exercise, workout, trainingPlanService);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTrackingInfo(WorkoutExercise exercise) {
    final trackingInfo = <String>[];

    exercise.defaultValues.forEach((type, value) {
      switch (type) {
        case TrackingType.repetitions:
          trackingInfo.add('$value reps');
          break;
        case TrackingType.weight:
          trackingInfo.add('$value kg');
          break;
        case TrackingType.duration:
          trackingInfo.add('$value sec');
          break;
        case TrackingType.distance:
          trackingInfo.add('$value m');
          break;
      }
    });

    return trackingInfo.join(', ');
  }

  void _showAddExerciseDialog(
      Exercise exercise, Workout workout, TrainingPlanService service) {
    final setsController = TextEditingController(text: '3');
    final Map<TrackingType, TextEditingController> trackingControllers = {};

    for (final type in exercise.trackingTypes) {
      switch (type) {
        case TrackingType.repetitions:
          trackingControllers[type] = TextEditingController(text: '12');
          break;
        case TrackingType.weight:
          trackingControllers[type] = TextEditingController(text: '10');
          break;
        case TrackingType.duration:
          trackingControllers[type] = TextEditingController(text: '30');
          break;
        case TrackingType.distance:
          trackingControllers[type] = TextEditingController(text: '100');
          break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Sets',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ...exercise.trackingTypes.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: trackingControllers[type],
                    decoration: InputDecoration(
                      labelText: _getTrackingLabel(type),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Parse values
              final sets = int.tryParse(setsController.text) ?? 3;
              final Map<TrackingType, dynamic> defaultValues = {};

              for (final type in exercise.trackingTypes) {
                switch (type) {
                  case TrackingType.repetitions:
                  case TrackingType.duration:
                  case TrackingType.distance:
                    defaultValues[type] =
                        int.tryParse(trackingControllers[type]!.text) ?? 0;
                    break;
                  case TrackingType.weight:
                    defaultValues[type] =
                        double.tryParse(trackingControllers[type]!.text) ?? 0.0;
                    break;
                }
              }

              // Create workout exercise
              final workoutExercise = WorkoutExercise(
                id: 'we_${DateTime.now().millisecondsSinceEpoch}',
                exercise: exercise,
                sets: sets,
                defaultValues: defaultValues,
                orderIndex: workout.exercises.length,
              );

              // Update workout
              final updatedExercises =
                  List<WorkoutExercise>.from(workout.exercises);
              updatedExercises.add(workoutExercise);

              final updatedWorkout =
                  workout.copyWith(exercises: updatedExercises);
              await service.updateWorkout(updatedWorkout);

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(WorkoutExercise workoutExercise,
      Workout workout, TrainingPlanService service) {
    final setsController =
        TextEditingController(text: workoutExercise.sets.toString());
    final Map<TrackingType, TextEditingController> trackingControllers = {};

    for (final type in workoutExercise.exercise.trackingTypes) {
      trackingControllers[type] = TextEditingController(
          text: workoutExercise.defaultValues[type].toString());
    }

    final notesController =
        TextEditingController(text: workoutExercise.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${workoutExercise.exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Sets',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ...workoutExercise.exercise.trackingTypes.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: trackingControllers[type],
                    decoration: InputDecoration(
                      labelText: _getTrackingLabel(type),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                );
              }).toList(),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Parse values
              final sets = int.tryParse(setsController.text) ?? 3;
              final Map<TrackingType, dynamic> defaultValues = {};

              for (final type in workoutExercise.exercise.trackingTypes) {
                switch (type) {
                  case TrackingType.repetitions:
                  case TrackingType.duration:
                  case TrackingType.distance:
                    defaultValues[type] =
                        int.tryParse(trackingControllers[type]!.text) ?? 0;
                    break;
                  case TrackingType.weight:
                    defaultValues[type] =
                        double.tryParse(trackingControllers[type]!.text) ?? 0.0;
                    break;
                }
              }

              // Update workout exercise
              final updatedWorkoutExercise = workoutExercise.copyWith(
                sets: sets,
                defaultValues: defaultValues,
                notes: notesController.text,
              );

              // Update workout
              final updatedExercises =
                  List<WorkoutExercise>.from(workout.exercises);
              final index = updatedExercises
                  .indexWhere((e) => e.id == workoutExercise.id);
              if (index != -1) {
                updatedExercises[index] = updatedWorkoutExercise;
              }

              final updatedWorkout =
                  workout.copyWith(exercises: updatedExercises);
              await service.updateWorkout(updatedWorkout);

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteExerciseDialog(WorkoutExercise workoutExercise,
      Workout workout, TrainingPlanService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
            'Are you sure you want to remove ${workoutExercise.exercise.name} from this workout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Remove exercise from workout
              final updatedExercises =
                  List<WorkoutExercise>.from(workout.exercises);
              updatedExercises
                  .removeWhere((e) => e.id == workoutExercise.id);

              // Update order indices
              for (int i = 0; i < updatedExercises.length; i++) {
                updatedExercises[i] =
                    updatedExercises[i].copyWith(orderIndex: i);
              }

              final updatedWorkout =
                  workout.copyWith(exercises: updatedExercises);
              await service.updateWorkout(updatedWorkout);

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

  String _getTrackingLabel(TrackingType type) {
    switch (type) {
      case TrackingType.repetitions:
        return 'Repetitions';
      case TrackingType.weight:
        return 'Weight (kg)';
      case TrackingType.duration:
        return 'Duration (seconds)';
      case TrackingType.distance:
        return 'Distance (meters)';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}