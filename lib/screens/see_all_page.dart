import 'package:flutter/material.dart';
import 'workout_detail_page.dart';

class SeeAllPage extends StatelessWidget {
  const SeeAllPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ExerciseItem> items = [
      _ExerciseItem('Dumbbell Workout', Icons.fitness_center, const Color(0xFF4A90E2), '12 Workout', '120 min'),
      _ExerciseItem('Free hand exercises', Icons.accessibility_new, const Color(0xFF34C759), '15 Workout', '90 min'),
      _ExerciseItem('Yoga', Icons.self_improvement, const Color(0xFF8E44FF), '18 Workout', '100 min'),
      _ExerciseItem('Pilates', Icons.self_improvement, const Color(0xFF9B59B6), '10 Workout', '80 min'),
      _ExerciseItem('Cardio Burn', Icons.directions_run, const Color(0xFFE67E22), '14 Workout', '60 min'),
      _ExerciseItem('Core Strength', Icons.sports_gymnastics, const Color(0xFF16A085), '16 Workout', '75 min'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Popular Exercises'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _ExerciseCard(item: item);
        },
      ),
    );
  }
}

class _ExerciseItem {
  _ExerciseItem(this.title, this.icon, this.iconBg, this.workouts, this.duration);
  final String title;
  final IconData icon;
  final Color iconBg;
  final String workouts;
  final String duration;
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.item});
  final _ExerciseItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final int durationMinutes = int.tryParse(item.duration.split(' ').first) ?? 60;
        final int numExercises = int.tryParse(item.workouts.split(' ').first) ?? 8;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailPage(
              title: item.title,
              level: 'Beginner',
              durationMinutes: durationMinutes,
              kcal: 150,
              numExercises: numExercises,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.workouts,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              item.duration,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}


