import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/mock_api.dart';
import '../models/workout.dart';
import '../models/er_models.dart';
import 'workout_plans_page.dart';
import 'challenges_page.dart';
import 'nutrition_plans_page.dart';
import 'progress_logs_page.dart';
import '../utils/app_text_style.dart';
import 'workout_detail_page.dart';
import '../services/auth.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Strength', 'Cardio', 'Flexibility'];
  final TextEditingController _searchController = TextEditingController();
  final MockApiService _api = const MockApiService();
  late Future<List<WorkoutModel>> _futureWorkouts;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _futureWorkouts = _api.fetchWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search workouts...',
                    hintStyle: AppTextStyle.regularText(
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter Buttons
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = index;
                        });
                      },
                      selectedColor: const Color(0xFF7ED957),
                      backgroundColor: Colors.white,
                      labelStyle: AppTextStyle.mediumText(
                        size: 14,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF7ED957)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child: FutureBuilder<List<WorkoutModel>>(
                future: _futureWorkouts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Failed to load workouts', style: AppTextStyle.mediumText(size: 14, color: Colors.red)),
                    );
                  }
                  final workouts = snapshot.data ?? [];
                  final mapped = workouts.map((w) => _WorkoutData(
                        id: w.id,
                        title: w.title,
                        difficulty: w.level,
                        difficultyColor: _levelColor(w.level),
                        time: '${w.durationMinutes} min',
                        calories: '${w.kcal} kcal',
                        exercises: '${w.exercisesCount} exercises',
                        imageColor: Colors.grey.shade200,
                        imageUrl: w.imageUrl,
                        tags: w.tags,
                        equipment: w.equipment,
                      ));
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured Today Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Featured Today',
                            style: AppTextStyle.semiBoldText(
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeaturedCard(),
                        const SizedBox(height: 24),
                        // Trainer Assigned Workout section (user role only)
                        if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin)
                          FutureBuilder<List<WorkoutPlanModel>>(
                            future: _api.fetchWorkoutPlans(),
                            builder: (context, snapPlans) {
                              if (!snapPlans.hasData) return const SizedBox.shrink();
                              final plans = snapPlans.data!;
                              if (plans.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Trainer Assigned Workout', style: AppTextStyle.semiBoldText(size: 20, color: Colors.black)),
                                  ),
                                  const SizedBox(height: 12),
                                  ...plans.take(4).map((p) => Container(
                                        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                                        child: Row(children: [
                                          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEAF7D5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.rule_folder, color: Color(0xFF7ED957))),
                                          const SizedBox(width: 10),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(p.name, style: AppTextStyle.semiBoldText(size: 15, color: Colors.black)),
                                            const SizedBox(height: 4),
                                            Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.regularText(size: 12, color: Colors.grey[700])),
                                          ])),
                                          const SizedBox(width: 8),
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Text(p.difficulty, style: AppTextStyle.mediumText(size: 11, color: Colors.grey[800]!))),
                                        ]),
                                      )),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: TextButton(
                                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutPlansPage())),
                                      child: const Text('View all plans'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                        // All Workouts Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'All Workouts',
                            style: AppTextStyle.semiBoldText(
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...mapped
                            .map((wd) => Container(
                                  margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                  child: _buildWorkoutCard(wd),
                                ))
                            .toList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutDetailPage(
              title: 'Full Body Challenge',
              level: 'Intermediate',
              durationMinutes: 30,
              kcal: 500,
              numExercises: 15,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Premium',
                      style: AppTextStyle.mediumText(
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Full Body Challenge',
                    style: AppTextStyle.boldText(size: 22, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '30-day transformation program with guided workouts',
                    style: AppTextStyle.regularText(
                      size: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '17',
                            style: AppTextStyle.boldText(
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '500+ kcal',
                            style: AppTextStyle.boldText(
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.yellow,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWorkoutCards() {
    final workouts = [
      _WorkoutData(
        title: 'Morning Yoga Flow',
        difficulty: 'Beginner',
        difficultyColor: const Color(0xFF7ED957),
        time: '30 min',
        calories: '150 kcal',
        exercises: '8 exercises',
        imageColor: const Color(0xFFD4E9F7),
        imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=600&auto=format&fit=crop',
        tags: ['Flexibility', 'Core'],
        equipment: 'Yoga Mat', id: '',
      ),
      _WorkoutData(
        title: 'HIIT Cardio Blast',
        difficulty: 'Intermediate',
        difficultyColor: Colors.orange,
        time: '25 min',
        calories: '300 kcal',
        exercises: '6 exercises',
        imageColor: const Color(0xFFE8F5E9),
        imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=600&auto=format&fit=crop',
        tags: ['Cardio', 'Full Body'],
        equipment: 'None', id: '',
      ),
      _WorkoutData(
        title: 'Full Body Strength',
        difficulty: 'Advanced',
        difficultyColor: Colors.red,
        time: '45 min',
        calories: '450 kcal',
        exercises: '10 exercises',
        imageColor: const Color(0xFFFFF3E0),
        imageUrl: 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
        tags: ['Strength', 'Upper Body', 'Lower Body'],
        equipment: 'Dumbbells', id: '',
      ),
      _WorkoutData(
        title: 'Abs & Core Power',
        difficulty: 'Intermediate',
        difficultyColor: Colors.orange,
        time: '20 min',
        calories: '200 kcal',
        exercises: '7 exercises',
        imageColor: const Color(0xFFFFE0E0),
        imageUrl: 'https://images.unsplash.com/photo-1548690312-e3b507d8c110?q=80&w=600&auto=format&fit=crop',
        tags: ['Core', 'Strength'],
        equipment: 'Mat', id: '',
      ),
    ];

    return workouts.map((workout) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: _buildWorkoutCard(workout),
      );
    }).toList();
  }

  Widget _buildWorkoutCard(_WorkoutData workout) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailPage(
              workoutId: workout.id,
              title: workout.title,
              level: workout.difficulty,
              durationMinutes: int.parse(workout.time.split(' ')[0]),
              kcal: int.parse(workout.calories.split(' ')[0]),
              numExercises: int.parse(workout.exercises.split(' ')[0]),
              headerImageUrl: workout.imageUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CachedNetworkImage(
                      imageUrl: workout.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: workout.imageColor),
                      errorWidget: (context, url, error) => Container(
                        color: workout.imageColor,
                        child: const Icon(Icons.image_not_supported, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workout.title,
                              style: AppTextStyle.mediumText(
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: workout.difficultyColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              workout.difficulty,
                              style: AppTextStyle.mediumText(
                                size: 11,
                                color: workout.difficultyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatItem(
                            icon: Icons.access_time,
                            value: workout.time.split(' ').first,
                            label: 'min',
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            icon: Icons.local_fire_department,
                            value: workout.calories.split(' ').first,
                            label: 'kcal',
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            icon: Icons.adjust,
                            value: workout.exercises.split(' ').first,
                            label: 'exercises',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...workout.tags.take(2).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyle.mediumText(
                                  size: 12,
                                  color: const Color(0xFF2F6BFF),
                                ),
                              ),
                            );
                          }),
                          if (workout.tags.length > 2)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${workout.tags.length - 2}',
                                style: AppTextStyle.mediumText(
                                  size: 12,
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.sports_gymnastics,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            workout.equipment,
                            style: AppTextStyle.regularText(
                              size: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyle.regularText(size: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyle.semiBoldText(size: 13, color: Colors.black),
            ),
            Text(
              label,
              style: AppTextStyle.mediumText(size: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkoutData {
  final String id;
  final String title;
  final String difficulty;
  final Color difficultyColor;
  final String time;
  final String calories;
  final String exercises;
  final Color imageColor;
  final String imageUrl;
  final List<String> tags;
  final String equipment;

  _WorkoutData({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.difficultyColor,
    required this.time,
    required this.calories,
    required this.exercises,
    required this.imageColor,
    required this.imageUrl,
    required this.tags,
    required this.equipment,
  });
}

Color _levelColor(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return const Color(0xFF7ED957);
    case 'advanced':
      return Colors.red;
    case 'intermediate':
    default:
      return Colors.orange;
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
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
      ),
    );
  }
}
