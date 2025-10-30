import 'package:flutter/material.dart';
import '../widgets/header_section.dart';
import '../widgets/workout_progress_card.dart';
import '../widgets/today_workouts_card.dart';
import '../widgets/popular_exercises_section.dart';

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
              const SizedBox(height: 30),
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
