import 'package:activex_gym_app/widgets/trainer_fab.dart';
import 'package:flutter/material.dart';
import '../user/workout_plans_page.dart';
import '../user/nutrition_plans_page.dart';
import '../user/challenges_page.dart';
import 'trainer_profile_page.dart';

class TrainerMainScreen extends StatefulWidget {
  const TrainerMainScreen({super.key});

  @override
  State<TrainerMainScreen> createState() => _TrainerMainScreenState();
}

class _TrainerMainScreenState extends State<TrainerMainScreen> {
  int _idx = 0;
  final _tabs = const [
    WorkoutPlansPage(),
    NutritionPlansPage(),
    ChallengesPage(),
    TrainerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const barBg = Color(0xFFF3E5F5); // light purple
    const active = Color.fromARGB(255, 209, 60, 209);
    return Scaffold(
      body: _tabs[_idx],
      // Floating create buttons removed per design on Plans and Nutrition
      floatingActionButton: null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: barBg, boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, -2))]),
        child: BottomNavigationBar(
          backgroundColor:Colors.white,
          elevation: 0,
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          selectedItemColor: active,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center,), label: 'Plans'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Nutrition'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Challenges'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}


