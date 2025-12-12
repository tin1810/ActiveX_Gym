import 'package:flutter/material.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';
import '../../services/auth.dart';
import '../../services/network_service.dart';
import '../../services/database_helper.dart';

class NutritionPlanDetailPage extends StatefulWidget {
  const NutritionPlanDetailPage({super.key, required this.plan});
  final NutritionPlanModel plan;

  @override
  State<NutritionPlanDetailPage> createState() => _NutritionPlanDetailPageState();
}

class _NutritionPlanDetailPageState extends State<NutritionPlanDetailPage> {
  final api = const ApiServiceFor();
  String? _trainerName;

  @override
  void initState() {
    super.initState();
    _loadTrainerName();
  }

  Future<void> _loadTrainerName() async {
    try {
      final trainer = await DatabaseHelper.instance.getUserById(widget.plan.trainerId);
      if (trainer != null && mounted) {
        setState(() {
          _trainerName = trainer.name;
        });
      } else if (mounted) {
        setState(() {
          _trainerName = 'Trainer';
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
                          _buildDescription(),
                          const SizedBox(height: 24),
                          _buildMealsSchedule(),
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
          const Text('Nutrition Plan Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF9800).withValues(alpha: 0.8),
                const Color(0xFFFFA726).withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Center(
            child: Icon(
              Icons.restaurant_menu,
              size: 90,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.plan.name,
          style: AppTextStyle.boldText(size: 24, color: Colors.black),
        ),
        if (_trainerName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'By $_trainerName',
                style: AppTextStyle.mediumText(size: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.local_fire_department,
            label: 'Daily Calories',
            value: '${widget.plan.dailyCaloriesTarget} kcal',
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.restaurant,
            label: 'Total Meals',
            value: '${widget.plan.meals.length}',
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyle.boldText(size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyle.regularText(size: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Plan',
          style: AppTextStyle.semiBoldText(size: 18, color: Colors.black),
        ),
        const SizedBox(height: 12),
        Text(
          widget.plan.description,
          style: AppTextStyle.regularText(size: 14, color: Colors.grey[800],),
        ),
      ],
    );
  }

  Widget _buildMealsSchedule() {
    if (widget.plan.meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No meals scheduled',
                style: AppTextStyle.mediumText(size: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Schedule',
          style: AppTextStyle.semiBoldText(size: 18, color: Colors.black),
        ),
        const SizedBox(height: 16),
        ...widget.plan.meals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: index < widget.plan.meals.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: AppTextStyle.semiBoldText(size: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            meal.timeOfDay,
                            style: AppTextStyle.mediumText(size: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
