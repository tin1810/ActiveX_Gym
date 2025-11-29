import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/er_models.dart';
import '../../models/exercise.dart';
import '../../utils/app_text_style.dart';
import '../../services/auth.dart';
import '../../services/network_service.dart';
import 'workout_plan_form_page.dart';

class TrainerWorkoutPlanDetailPage extends StatefulWidget {
  const TrainerWorkoutPlanDetailPage({super.key, required this.plan});

  final WorkoutPlanModel plan;

  @override
  State<TrainerWorkoutPlanDetailPage> createState() => _TrainerWorkoutPlanDetailPageState();
}

class _TrainerWorkoutPlanDetailPageState extends State<TrainerWorkoutPlanDetailPage> {
  final api = const ApiServiceFor();

  Future<void> _deletePlan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout Plan'),
        content: const Text('Are you sure you want to delete this workout plan? This action cannot be undone.'),
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
      await api.deleteWorkoutPlan(widget.plan.id);
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    }
  }

  Future<void> _editPlan() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutPlanFormPage(workoutPlan: widget.plan),
      ),
    );
    if (updated == true && mounted) {
      setState(() {}); // Refresh to show updated data
    }
  }

  Widget _buildWorkoutImage() {
    final plan = widget.plan;
    if (plan.imageUrl != null && plan.imageUrl!.isNotEmpty) {
      if (plan.imageUrl!.startsWith('data:image')) {
        try {
          final base64String = plan.imageUrl!.split(',')[1];
          final imageBytes = base64Decode(base64String);
          return Image.memory(
            imageBytes,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (e) {
          return _buildPlaceholder();
        }
      } else {
        return Image.network(
          plan.imageUrl!,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
      child: Center(
        child: Icon(Icons.fitness_center, size: 90, color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Trainer/Admin only')),
      );
    }

    final plan = widget.plan;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Workout Plan Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // IconButton(
          //   onPressed: _editPlan,
          //   icon: const Icon(Icons.edit),
          //   tooltip: 'Edit',
          // ),
          IconButton(
            onPressed: _deletePlan,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildWorkoutImage(),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(plan.difficulty),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.difficulty.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricsRow(plan),
                  const SizedBox(height: 24),
                  if (plan.description.isNotEmpty) ...[
                    _buildSection('About Plan', plan.description),
                    const SizedBox(height: 24),
                  ],
                  if (plan.tags != null && plan.tags!.isNotEmpty) ...[
                    _buildTags(plan.tags!),
                    const SizedBox(height: 24),
                  ],
                  if (plan.equipment != null) ...[
                    _buildEquipment(plan.equipment!),
                    const SizedBox(height: 24),
                  ],
                  _buildSchedule(plan),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editPlan,
                      icon: const Icon(Icons.edit),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Edit Workout Plan'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED957),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(WorkoutPlanModel plan) {
    return Row(
      children: [
        if (plan.durationMinutes != null)
          Expanded(
            child: _MetricCard(
              icon: Icons.access_time,
              iconColor: const Color(0xFF4A90E2),
              bg: const Color(0xFFEFF5FF),
              title: 'Duration',
              value: '${plan.durationMinutes} min',
            ),
          ),
        if (plan.durationMinutes != null) const SizedBox(width: 12),
        if (plan.kcal != null)
          Expanded(
            child: _MetricCard(
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFE67E22),
              bg: const Color(0xFFFFF4E6),
              title: 'Calories',
              value: '${plan.kcal} kcal',
            ),
          ),
        if (plan.kcal != null) const SizedBox(width: 12),
        if (plan.exercisesCount != null)
          Expanded(
            child: _MetricCard(
              icon: Icons.fitness_center,
              iconColor: const Color(0xFF2E7D32),
              bg: const Color(0xFFE8F5E9),
              title: 'Exercises',
              value: '${plan.exercisesCount}',
            ),
          ),
        if (plan.exercisesCount == null && plan.durationMinutes == null && plan.kcal == null)
          Expanded(
            child: _MetricCard(
              icon: Icons.event,
              iconColor: const Color(0xFF2E7D32),
              bg: const Color(0xFFE8F5E9),
              title: 'Workouts',
              value: '${plan.workouts.length}',
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(content, style: AppTextStyle.regularText(size: 14, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildTags(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipment(String equipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Equipment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.fitness_center, color: Color(0xFF8E44FF), size: 18),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2E9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                equipment,
                style: const TextStyle(color: Color(0xFF6E49B5), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSchedule(WorkoutPlanModel plan) {
    final items = plan.workouts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This plan has no scheduled workouts yet.',
                    style: AppTextStyle.regularText(size: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          )
        else
          FutureBuilder<List<ExerciseModel>>(
            future: api.fetchExercises(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final allExercises = snapshot.data!;
              // Create a map of exercise ID to exercise for quick lookup
              final exerciseMap = {for (var e in allExercises) e.id: e};
              
              return Column(
                children: [
                  for (final entry in items.asMap().entries)
                    Builder(
                      builder: (context) {
                        final workout = entry.value;
                        final exercise = exerciseMap[workout.workoutId];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(color: Color(0xFF64B5F6), shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Day ${workout.dayOfWeek + 1}: ${exercise?.title ?? workout.workoutId}',
                                      style: AppTextStyle.semiBoldText(size: 14, color: Colors.black),
                                    ),
                                    const SizedBox(height: 6),
                                    if (exercise != null) ...[
                                      Text(
                                        '${workout.sets} sets • ${workout.reps}',
                                        style: AppTextStyle.regularText(size: 12, color: Colors.grey[700]),
                                      ),
                                      if (exercise.targetMuscles.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: exercise.targetMuscles.take(3).map((muscle) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3F2FD),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                muscle,
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2)),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ] else
                                      Text(
                                        '${workout.sets} sets • ${workout.reps}',
                                        style: AppTextStyle.regularText(size: 12, color: Colors.grey[700]),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'advanced':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

