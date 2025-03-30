import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/workout_log_service.dart';
import '../../services/auth_service.dart';
import '../../services/training_plan_service.dart';
import '../../models/workout_log.dart';
import 'workout_history_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkoutLogService, AuthService>(
      builder: (context, workoutLogService, authService, child) {
        final user = authService.currentUser;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<WorkoutLog>>(
          future: workoutLogService.getUserWorkoutLogs(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final workoutLogs = snapshot.data ?? [];

            if (workoutLogs.isEmpty) {
              return _buildEmptyState();
            }

            return _buildProgressOverview(context, workoutLogs);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insights,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Workout Data Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first workout to start tracking your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview(BuildContext context, List<WorkoutLog> logs) {
    // Group logs by workout
    final workoutMap = <String, List<WorkoutLog>>{};
    for (final log in logs) {
      if (!workoutMap.containsKey(log.workoutId)) {
        workoutMap[log.workoutId] = [];
      }
      workoutMap[log.workoutId]!.add(log);
    }

    // Sort by most recent workout
    final sortedWorkouts = workoutMap.entries.toList()
      ..sort((a, b) {
        final aDate = a.value.map((log) => log.startTime).reduce(
            (value, element) => value.isAfter(element) ? value : element);
        final bDate = b.value.map((log) => log.startTime).reduce(
            (value, element) => value.isAfter(element) ? value : element);
        return bDate.compareTo(aDate);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(logs),
          const SizedBox(height: 24),
          const Text(
            'Workout History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedWorkouts.map((entry) {
            return _buildWorkoutCard(context, entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<WorkoutLog> logs) {
    final totalWorkouts = logs.length;
    final completedWorkouts =
        logs.where((log) => log.endTime != null).length;
    final totalDuration = logs
        .where((log) => log.endTime != null)
        .map((log) =>
            log.endTime!.difference(log.startTime).inMinutes)
        .fold(0, (a, b) => a + b);

    final averageDuration =
        completedWorkouts > 0 ? totalDuration / completedWorkouts : 0;

    // Get the most recent workout date
    final mostRecentDate = logs.isNotEmpty
        ? logs
            .map((log) => log.startTime)
            .reduce((value, element) =>
                value.isAfter(element) ? value : element)
        : null;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Workouts',
                  totalWorkouts.toString(),
                  Icons.fitness_center,
                ),
                _buildStatItem(
                  'Completed',
                  completedWorkouts.toString(),
                  Icons.check_circle,
                ),
                _buildStatItem(
                  'Avg. Duration',
                  '${averageDuration.toStringAsFixed(0)} min',
                  Icons.timer,
                ),
              ],
            ),
            if (mostRecentDate != null) ...[  
              const Divider(height: 32),
              Text(
                'Last workout: ${_formatDate(mostRecentDate)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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

  Widget _buildWorkoutCard(
      BuildContext context, String workoutId, List<WorkoutLog> logs) {
    // Sort logs by date (most recent first)
    logs.sort((a, b) => b.startTime.compareTo(a.startTime));

    return Consumer<TrainingPlanService>(
      builder: (context, trainingPlanService, child) {
        final workout = trainingPlanService.getWorkoutById(workoutId);
        final workoutName = workout?.name ?? 'Unknown Workout';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(workoutName),
            subtitle: Text('${logs.length} sessions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutHistoryScreen(
                    workoutId: workoutId,
                    workoutName: workoutName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}