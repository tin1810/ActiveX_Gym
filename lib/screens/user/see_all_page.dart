import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/network_service.dart';
import '../../utils/app_text_style.dart';
import 'exercise_detail_page.dart';

class SeeAllPage extends StatefulWidget {
  const SeeAllPage({super.key});

  @override
  State<SeeAllPage> createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  final api = const ApiServiceFor();
  late Future<List<ExerciseModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.fetchExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('All Exercises'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
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
                    'No exercises available',
                    style: AppTextStyle.mediumText(size: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _ExerciseCard(exercise: exercise);
            },
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});
  final ExerciseModel exercise;

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
              demoUrl: exercise.videoUrl.isNotEmpty 
                  ? exercise.videoUrl 
                  : 'https://www.youtube.com/watch?v=IODxDxX7oi4',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.play_circle_filled, size: 50, color: Colors.grey),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Video',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.semiBoldText(size: 14, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(exercise.difficulty).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                exercise.difficulty,
                style: TextStyle(
                  color: _getDifficultyColor(exercise.difficulty),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${exercise.sets} sets • ${exercise.reps} reps',
              style: AppTextStyle.regularText(size: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}


