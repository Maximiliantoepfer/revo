import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/workout_log_service.dart';
import '../../services/training_plan_service.dart';
import '../../models/workout_log.dart';
import '../../models/exercise_log.dart';
import '../../models/exercise.dart';

class WorkoutLogDetailScreen extends StatelessWidget {
  final String workoutLogId;

  const WorkoutLogDetailScreen({super.key, required this.workoutLogId});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutLogService>(
      builder: (context, workoutLogService, child) {
        final workoutLog = workoutLogService.getWorkoutLogById(workoutLogId);

        if (workoutLog == null) {
          return const Scaffold(
            body: Center(child: Text('Workout log not found')),
          );
        }

        return Consumer<TrainingPlanService>(
          builder: (context, trainingPlanService, _) {
            final workout =
                trainingPlanService.getWorkoutById(workoutLog.workoutId);
            final workoutName = workout?.name ?? 'Unknown Workout';

            return Scaffold(
              appBar: AppBar(
                title: Text(workoutName),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWorkoutSummary(workoutLog),
                    const SizedBox(height: 24),
                    const Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...workoutLog.exerciseLogs.map((exerciseLog) {
                      return _buildExerciseCard(exerciseLog, trainingPlanService);
                    }).toList(),
                    if (workoutLog.notes.isNotEmpty) ...[  
                      const SizedBox(height: 24),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(workoutLog.notes),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutSummary(WorkoutLog workoutLog) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Date',
                  _formatDate(workoutLog.startTime),
                  Icons.calendar_today,
                ),
                _buildSummaryItem(
                  'Time',
                  _formatTime(workoutLog.startTime),
                  Icons.access_time,
                ),
                _buildSummaryItem(
                  'Duration',
                  _formatDuration(workoutLog.startTime, workoutLog.endTime),
                  Icons.timer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(
      ExerciseLog exerciseLog, TrainingPlanService trainingPlanService) {
    // Find the exercise
    final workout = trainingPlanService.getWorkoutById(exerciseLog.workoutLogId);
    final workoutExercise = workout?.exercises.firstWhere(
      (e) => e.exercise.id == exerciseLog.exerciseId,
      orElse: () => throw Exception('Exercise not found'),
    );

    final exerciseName = workoutExercise?.exercise.name ?? 'Unknown Exercise';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sets',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...exerciseLog.sets.map((setLog) {
              return _buildSetLogItem(setLog, workoutExercise?.exercise);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetLogItem(SetLog setLog, Exercise? exercise) {
    final trackingValues = <Widget>[];

    setLog.values.forEach((type, value) {
      String formattedValue = '';
      switch (type) {
        case TrackingType.repetitions:
          formattedValue = '$value reps';
          break;
        case TrackingType.weight:
          formattedValue = '$value kg';
          break;
        case TrackingType.duration:
          formattedValue = '$value sec';
          break;
        case TrackingType.distance:
          formattedValue = '$value m';
          break;
      }

      trackingValues.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(formattedValue),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            setLog.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: setLog.isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text('Set ${setLog.setNumber}'),
          const Spacer(),
          ...trackingValues,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'In progress';

    final duration = end.difference(start);
    final minutes = duration.inMinutes;

    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = duration.inHours;
      final remainingMinutes = minutes - (hours * 60);
      return '$hours h $remainingMinutes min';
    }
  }
}