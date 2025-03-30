import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/training_plan_service.dart';
import 'training_plan_screen.dart';

class CreateTrainingPlanScreen extends StatefulWidget {
  const CreateTrainingPlanScreen({super.key});

  @override
  State<CreateTrainingPlanScreen> createState() =>
      _CreateTrainingPlanScreenState();
}

class _CreateTrainingPlanScreenState extends State<CreateTrainingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTrainingPlan() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final trainingPlanService =
          Provider.of<TrainingPlanService>(context, listen: false);

      if (authService.currentUser == null) return;

      try {
        final trainingPlan = await trainingPlanService.createTrainingPlan(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          userId: authService.currentUser!.id,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingPlanScreen(
                trainingPlanId: trainingPlan.id,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating training plan: $e')),
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
        title: const Text('Create Training Plan'),
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
                  hintText: 'e.g., Full Body, Push-Pull-Legs, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your training plan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your training plan',
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
                onPressed: trainingPlanService.isLoading
                    ? null
                    : _createTrainingPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: trainingPlanService.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Training Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}