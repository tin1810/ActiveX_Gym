import 'package:flutter/material.dart';
import '../screens/workout_detail_page.dart';

class TodayWorkoutsCard extends StatelessWidget {
  const TodayWorkoutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today Workouts (17)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WorkoutDetailPage(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              // color: const Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '90min',
                            style: TextStyle(
                              color: Colors.white,
                                    fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '1,200kcal',
                            style: TextStyle(
                              color: Colors.white,  fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Upper Body Workout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[400],
                    image: DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1470"),fit: BoxFit.cover)
                  ),
                  // child: const Icon(
                  //   Icons.fitness_center,
                  //   color: Colors.white,
                  //   size: 40,
                  // ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
