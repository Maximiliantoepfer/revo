import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/training_plan_service.dart';
import '../../services/workout_log_service.dart';
import '../../services/auth_service.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/exercise.dart';
import '../../models/workout_log.dart';
import '../../models/exercise_log.dart';

class WorkoutScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutScreen({super.key, required this.workoutId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
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

        return Consumer<WorkoutLogService>(
          builder: (context, workoutLogService, _) {
            final isWorkoutActive = workoutLogService.hasActiveWorkout;
            final activeWorkoutLog = workoutLogService.activeWorkoutLog;
            final isThisWorkoutActive = isWorkoutActive &&
                activeWorkoutLog?.workoutId == workout.id;

            return Scaffold(
              appBar: AppBar(
                title: Text(workout.name),
                actions: [
                  if (isThisWorkoutActive)
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () {
                        _showFinishWorkoutDialog(context, workoutLogService);
                      },
                    ),
                ],
              ),
              body: isThisWorkoutActive
                  ? _buildActiveWorkout(workout, activeWorkoutLog!)
                  : _buildWorkoutOverview(workout, workoutLogService),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutOverview(
      Workout workout, WorkoutLogService workoutLogService) {
    return Column(
      children: [
        Padding(
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
              const SizedBox(height: 16),
              Text(
                '${workout.exercises.length} exercises',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startWorkout(workout, workoutLogService),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Workout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _buildExercisesList(workout),
        ),
      ],
    );
  }

  Widget _buildExercisesList(Workout workout) {
    if (workout.exercises.isEmpty) {
      return const Center(
        child: Text('No exercises in this workout'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: workout.exercises.length,
      itemBuilder: (context, index) {
        final exercise = workout.exercises[index];
        return Card(
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
                if (exercise.notes.isNotEmpty)
                  Text(
                    'Notes: ${exercise.notes}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildActiveWorkout(Workout workout, WorkoutLog workoutLog) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout in Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Started: ${_formatTime(workoutLog.startTime)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Consumer<WorkoutLogService>(
                builder: (context, service, _) => ElevatedButton(
                  onPressed: service.isLoading
                      ? null
                      : () => _showFinishWorkoutDialog(context, service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: service.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Finish'),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _buildActiveExercisesList(workout, workoutLog),
        ),
      ],
    );
  }

  Widget _buildActiveExercisesList(Workout workout, WorkoutLog workoutLog) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: workoutLog.exerciseLogs.length,
      itemBuilder: (context, index) {
        final exerciseLog = workoutLog.exerciseLogs[index];
        final workoutExercise = workout.exercises.firstWhere(
          (e) => e.exercise.id == exerciseLog.exerciseId,
          orElse: () => workout.exercises.first,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    workoutExercise.exercise.imageUrl != null
                        ? CircleAvatar(
                            backgroundImage: AssetImage(
                                workoutExercise.exercise.imageUrl!),
                          )
                        : CircleAvatar(
                            child: Text(workoutExercise.exercise.name[0]),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workoutExercise.exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (workoutExercise.notes.isNotEmpty)
                            Text(
                              workoutExercise.notes,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sets',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...exerciseLog.sets.map((setLog) {
                  return _buildSetLogItem(
                      setLog, workoutExercise, exerciseLog);
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetLogItem(SetLog setLog, WorkoutExercise workoutExercise,
      ExerciseLog exerciseLog) {
    return Consumer<WorkoutLogService>(
      builder: (context, service, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Checkbox(
                value: setLog.isCompleted,
                onChanged: (value) {
                  if (value != null) {
                    service.updateSetLog(
                      exerciseLogId: exerciseLog.id,
                      setNumber: setLog.setNumber,
                      values: setLog.values,
                      isCompleted: value,
                    );
                  }
                },
              ),
              Text('Set ${setLog.setNumber}'),
              const Spacer(),
              ...workoutExercise.exercise.trackingTypes.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildTrackingValueField(
                    type,
                    setLog,
                    exerciseLog,
                    service,
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackingValueField(TrackingType type, SetLog setLog,
      ExerciseLog exerciseLog, WorkoutLogService service) {
    final controller = TextEditingController(
        text: setLog.values[type]?.toString() ?? '0');

    // Update controller when value changes
    controller.addListener(() {
      final newValues = Map<TrackingType, dynamic>.from(setLog.values);
      switch (type) {
        case TrackingType.repetitions:
        case TrackingType.duration:
        case TrackingType.distance:
          newValues[type] = int.tryParse(controller.text) ?? 0;
          break;
        case TrackingType.weight:
          newValues[type] = double.tryParse(controller.text) ?? 0.0;
          break;
      }

      service.updateSetLog(
        exerciseLogId: exerciseLog.id,
        setNumber: setLog.setNumber,
        values: newValues,
        isCompleted: setLog.isCompleted,
      );
    });

    String suffix = '';
    double width = 60.0;

    switch (type) {
      case TrackingType.repetitions:
        suffix = 'reps';
        width = 60.0;
        break;
      case TrackingType.weight:
        suffix = 'kg';
        width = 70.0;
        break;
      case TrackingType.duration:
        suffix = 's';
        width = 60.0;
        break;
      case TrackingType.distance:
        suffix = 'm';
        width = 70.0;
        break;
    }

    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: const OutlineInputBorder(),
          suffixText: suffix,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _startWorkout(Workout workout, WorkoutLogService workoutLogService) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Workout'),
        content: Text('Ready to start ${workout.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await workoutLogService.startWorkout(
                workoutId: workout.id,
                userId: authService.currentUser!.id,
                workout: workout,
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showFinishWorkoutDialog(
      BuildContext context, WorkoutLogService workoutLogService) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your workout?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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
              Navigator.pop(context);
              await workoutLogService.finishWorkout(
                notes: notesController.text.trim(),
              );
            },
            child: const Text('Finish'),
          ),
        ],
      ),
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}