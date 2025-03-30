import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/workout_log_service.dart';
import '../../models/workout_log.dart';
import 'workout_log_detail_screen.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  final String workoutId;
  final String workoutName;

  const WorkoutHistoryScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$workoutName History'),
      ),
      body: Consumer<WorkoutLogService>(
        builder: (context, workoutLogService, child) {
          return FutureBuilder<List<WorkoutLog>>(
            future: workoutLogService.getWorkoutLogs(workoutId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final logs = snapshot.data ?? [];

              if (logs.isEmpty) {
                return const Center(
                  child: Text('No workout history found'),
                );
              }

              // Sort logs by date (most recent first)
              logs.sort((a, b) => b.startTime.compareTo(a.startTime));

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(_formatDate(log.startTime)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Duration: ${_formatDuration(log.startTime, log.endTime)}'),
                          if (log.notes.isNotEmpty)
                            Text(
                              'Notes: ${log.notes}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutLogDetailScreen(
                              workoutLogId: log.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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