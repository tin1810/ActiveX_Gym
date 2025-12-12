import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/network_service.dart';
import '../../services/auth.dart';
import '../../utils/app_text_style.dart';
import 'exercise_form_page.dart';

class ExercisesManagementPage extends StatefulWidget {
  const ExercisesManagementPage({super.key});

  @override
  State<ExercisesManagementPage> createState() => _ExercisesManagementPageState();
}

class _ExercisesManagementPageState extends State<ExercisesManagementPage> {
  final api = const ApiServiceFor();
  late Future<List<ExerciseModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.fetchExercises();
  }

  void _refresh() {
    setState(() {
      _future = api.fetchExercises();
    });
  }

  Future<void> _deleteExercise(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: const Text('Are you sure you want to delete this exercise? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await api.deleteExercise(id);
        if (mounted) {
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercise deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(12);
          } else if (errorMessage.startsWith('Exception:')) {
            errorMessage = errorMessage.substring(10);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete exercise: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Trainer/Admin only')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, 
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ExerciseFormPage()),
          );
          if (created == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Exercise'),
      ),
      body: FutureBuilder<List<ExerciseModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercises = snapshot.data!;
          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises yet',
                    style: AppTextStyle.mediumText(size: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first exercise',
                    style: AppTextStyle.regularText(size: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final ex = exercises[i];
              return _ExerciseCard(
                exercise: ex,
                onEdit: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ExerciseFormPage(exercise: ex),
                    ),
                  );
                  if (updated == true) _refresh();
                },
                onDelete: () => _deleteExercise(ex.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });
  final ExerciseModel exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_outline, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: AppTextStyle.semiBoldText(size: 16, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Badge(
                      label: exercise.difficulty,
                      color: _getDifficultyColor(exercise.difficulty),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${exercise.sets} sets • ${exercise.reps} reps',
                        style: AppTextStyle.regularText(size: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: exercise.targetMuscles.take(3).map((muscle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        muscle,
                        style: AppTextStyle.regularText(size: 10, color: Colors.grey[700]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

