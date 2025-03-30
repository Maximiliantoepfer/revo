import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import '../../models/exercise.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

class ExerciseListScreen extends StatefulWidget {
  final bool selectionMode;

  const ExerciseListScreen({super.key, this.selectionMode = false});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Select Exercise' : 'Exercises'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Predefined'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExerciseList(true),
                _buildExerciseList(false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExerciseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExerciseList(bool predefined) {
    return Consumer2<ExerciseService, AuthService>(
      builder: (context, exerciseService, authService, child) {
        if (exerciseService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Exercise> exercises = predefined
            ? exerciseService.getPredefinedExercises()
            : exerciseService.getUserExercises(
                authService.currentUser?.id ?? '');

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          exercises = exercises
              .where((exercise) =>
                  exercise.name.toLowerCase().contains(_searchQuery) ||
                  exercise.description.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (exercises.isEmpty) {
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
                Text(
                  predefined
                      ? 'No predefined exercises found'
                      : 'No custom exercises yet',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: exercise.imageUrl != null
                    ? CircleAvatar(
                        backgroundImage: AssetImage(exercise.imageUrl!),
                      )
                    : CircleAvatar(
                        child: Text(exercise.name[0]),
                      ),
                title: Text(exercise.name),
                subtitle: Text(
                  exercise.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: widget.selectionMode
                    ? const Icon(Icons.arrow_forward_ios)
                    : null,
                onTap: () {
                  if (widget.selectionMode) {
                    Navigator.pop(context, exercise);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetailScreen(
                          exerciseId: exercise.id,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}