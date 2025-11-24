import 'package:flutter/material.dart';
import '../screens/user/workout_detail_page.dart';
import '../screens/user/see_all_page.dart';

class PopularExercisesSection extends StatelessWidget {
  const PopularExercisesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Exercise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SeeAllPage(),
                  ),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _PopularItem(
                icon: Icons.fitness_center,
                iconBg: Color(0xFF4A90E2),
                title: 'Dumbbell\nWorkout',
                workouts: '12 Workout',
                duration: '120 min',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _PopularItem(
                icon: Icons.accessibility_new,
                iconBg: Color(0xFF34C759),
                title: 'Free hand\nexercises',
                workouts: '15 Workout',
                duration: '90 min',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _PopularItem(
                icon: Icons.self_improvement,
                iconBg: Color(0xFF8E44FF),
                title: 'Yoga',
                workouts: '18 Workout',
                duration: '100 min',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PopularItem extends StatelessWidget {
  const _PopularItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.workouts,
    required this.duration,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String workouts;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        final String cleanTitle = title.replaceAll('\n', ' ');
        final int durationMinutes = int.tryParse(duration.split(' ').first) ?? 60;
        final int numExercises = int.tryParse(workouts.split(' ').first) ?? 8;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailPage(
              title: cleanTitle,
              level: 'Beginner',
              durationMinutes: durationMinutes,
              kcal: 150,
              numExercises: numExercises,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
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
            workouts,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            duration,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
