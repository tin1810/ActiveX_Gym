import 'package:flutter/material.dart';
import '../../models/er_models.dart';
import '../../models/exercise.dart';
import '../../utils/app_text_style.dart';
import '../../services/auth.dart';
import '../../services/network_service.dart';
import '../../services/database_helper.dart';
import 'exercise_detail_page.dart';

class WorkoutPlanDetailPage extends StatefulWidget {
  const WorkoutPlanDetailPage({super.key, required this.plan});
  final WorkoutPlanModel plan;

  @override
  State<WorkoutPlanDetailPage> createState() => _WorkoutPlanDetailPageState();
}

class _WorkoutPlanDetailPageState extends State<WorkoutPlanDetailPage> {
  final api = const ApiServiceFor();
  Set<String> _favoriteExerciseIds = {};
  String? _trainerName;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadTrainerName();
  }

  Future<void> _loadTrainerName() async {
    try {
      final trainer = await DatabaseHelper.instance.getUserById(widget.plan.trainerId);
      if (trainer != null && mounted) {
        setState(() {
          _trainerName = trainer.name;
        });
      }
    } catch (e) {
      // If trainer not found, use fallback
      if (mounted) {
        setState(() {
          _trainerName = 'Trainer';
        });
      }
    }
  }

  Future<void> _loadFavorites() async {
    final userId = MockAuthService.instance.currentUser.id;
    final favorites = await DatabaseHelper.instance.getFavoriteExercises(userId);
    setState(() {
      _favoriteExerciseIds = favorites;
    });
  }

  Future<void> _toggleFavorite(String exerciseId) async {
    final userId = MockAuthService.instance.currentUser.id;
    await DatabaseHelper.instance.toggleFavoriteExercise(userId, exerciseId);
    setState(() {
      if (_favoriteExerciseIds.contains(exerciseId)) {
        _favoriteExerciseIds.remove(exerciseId);
      } else {
        _favoriteExerciseIds.add(exerciseId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderMedia(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 16),
                          _buildMetrics(),
                          const SizedBox(height: 24),
                          _buildAbout(),
                          const SizedBox(height: 24),
                          _buildSchedule(),
                          const SizedBox(height: 24),
                          _buildExercises(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Workout Plan Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeaderMedia() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(0)),
          child: Center(
            child: Icon(Icons.fitness_center, size: 90, color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20)),
            child: Text(widget.plan.difficulty, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.plan.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            'Trainer: ${_trainerName ?? 'Loading...'}',
            style: AppTextStyle.regularText(size: 12, color: Colors.grey[800]),
          ),
        ]),
      ],
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.timeline,
            iconColor: const Color(0xFF4A90E2),
            bg: const Color(0xFFEFF5FF),
            title: 'Difficulty',
            value: widget.plan.difficulty,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.event,
            iconColor: const Color(0xFF2E7D32),
            bg: const Color(0xFFE8F5E9),
            title: 'Workouts',
            value: '${widget.plan.workouts.length}',
          ),
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(widget.plan.description, style: AppTextStyle.regularText(size: 14, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildSchedule() {
    final items = widget.plan.workouts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Text('This plan has no scheduled workouts yet.', style: AppTextStyle.regularText(size: 13, color: Colors.grey[700])),
          )
        else
          for (final entry in items.asMap().entries)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Day ${entry.value.dayOfWeek + 1}: Workout ${entry.value.workoutId}', style: AppTextStyle.semiBoldText(size: 14, color: Colors.black)),
                    const SizedBox(height: 6),
                    Text('${entry.value.sets} sets • ${entry.value.reps}', style: AppTextStyle.regularText(size: 12, color: Colors.grey[700])),
                  ]),
                ),
              ]),
            ),
      ],
    );
  }

  Widget _buildExercises() {
    // Get unique exercise IDs from workouts
    final exerciseIds = widget.plan.workouts.map((w) => w.workoutId).toSet().toList();
    
    return FutureBuilder<List<ExerciseModel>>(
      future: api.fetchExercises(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final allExercises = snapshot.data!;
        // Filter exercises that are in the plan
        final planExercises = allExercises.where((e) => exerciseIds.contains(e.id)).toList();
        
        if (planExercises.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final exercise in planExercises)
              _ExerciseCard(
              exercise: exercise,
              isFavorite: _favoriteExerciseIds.contains(exercise.id),
              onFavoriteToggle: () => _toggleFavorite(exercise.id),
            )
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.iconColor, required this.bg, required this.title, required this.value});
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final ExerciseModel exercise;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseDetailPage(
                exerciseName: exercise.title,
                level: exercise.difficulty,
                sets: exercise.sets,
                reps: exercise.reps,
                restTime: '${exercise.restSeconds}s',
                targetMuscles: exercise.targetMuscles,
                equipment: 'None',
                demoUrl: exercise.videoUrl.isNotEmpty ? exercise.videoUrl : 'https://www.youtube.com',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Exercise icon/thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Color(0xFF2196F3),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // Exercise details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(exercise.difficulty).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exercise.difficulty,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(exercise.difficulty),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${exercise.sets} sets • ${exercise.reps}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Star button
            IconButton(
              onPressed: onFavoriteToggle,
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 24,
              ),
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ],
        ),
      ),
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


