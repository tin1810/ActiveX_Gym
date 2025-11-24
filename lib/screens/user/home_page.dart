import 'package:flutter/material.dart';
import '../../widgets/header_section.dart';
import '../../widgets/workout_progress_card.dart';
import '../../widgets/today_workouts_card.dart';
import '../../widgets/popular_exercises_section.dart';
import 'workout_plans_page.dart';
import 'challenges_page.dart';
import 'nutrition_plans_page.dart';
import 'progress_logs_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 30),
              const WorkoutProgressCard(),
              const SizedBox(height: 16),
              // Quick Links row (Plans, Challenges, Nutrition, Logs)
              Row(
                children: const [
                  // Expanded(
                  //   child: _QuickLink(
                  //     icon: Icons.rule_folder,
                  //     label: 'Plans',
                  //     routeType: _QuickRoute.plans,
                  //   ),
                  // ),
                  // SizedBox(width: 12),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.emoji_events,
                      label: 'Challenges',
                      routeType: _QuickRoute.challenges,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.restaurant_menu,
                      label: 'Nutrition',
                      routeType: _QuickRoute.nutrition,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.monitor_weight,
                      label: 'Logs',
                      routeType: _QuickRoute.logs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const TodayWorkoutsCard(),
              const SizedBox(height: 30),
              const PopularExercisesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

enum _QuickRoute { plans, challenges, nutrition, logs }

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.routeType});
  final IconData icon;
  final String label;
  final _QuickRoute routeType;

  void _navigate(BuildContext context) {
    switch (routeType) {
      case _QuickRoute.plans:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutPlansPage()));
        break;
      case _QuickRoute.challenges:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChallengesPage()));
        break;
      case _QuickRoute.nutrition:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionPlansPage()));
        break;
      case _QuickRoute.logs:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressLogsPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
