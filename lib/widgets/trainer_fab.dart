import 'package:flutter/material.dart';
import '../services/auth.dart';
import '../screens/workout_plan_form_page.dart';
import '../screens/nutrition_plan_form_page.dart';

class TrainerFab extends StatelessWidget {
  const TrainerFab({super.key, required this.page, this.backgroundColor = const Color(0xFFE9E1FF), this.foregroundColor = const Color(0xFF5E35B1)});
  final String page; // 'workout' | 'nutrition'
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (!MockAuthService.instance.isTrainer) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () async {
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => page == 'workout' ? const WorkoutPlanFormPage() : const NutritionPlanFormPage(),
          ),
        );
        if (created == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan created')));
        }
      },
      icon: Icon(Icons.add, color: foregroundColor),
      label: Text('Create', style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700)),
      backgroundColor: backgroundColor,
    );
  }
}


