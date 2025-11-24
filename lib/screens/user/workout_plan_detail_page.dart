import 'package:flutter/material.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';
import '../../services/auth.dart';

class WorkoutPlanDetailPage extends StatefulWidget {
  const WorkoutPlanDetailPage({super.key, required this.plan});
  final WorkoutPlanModel plan;

  @override
  State<WorkoutPlanDetailPage> createState() => _WorkoutPlanDetailPageState();
}

class _WorkoutPlanDetailPageState extends State<WorkoutPlanDetailPage> {
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
                          _buildAbout(),
                          const SizedBox(height: 24),
                          _buildSchedule(),
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
          const Text('Workout Plan Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(0)),
          child: Center(
            child: Icon(Icons.fitness_center, size: 90, color: Colors.white.withOpacity(0.35)),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20)),
            child: Text(widget.plan.difficulty, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.plan.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text('Trainer: ${MockAuthService.instance.currentUser.name}', style: AppTextStyle.regularText(size: 12, color: Colors.grey[800])),
        ]),
      ],
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.timeline,
            iconColor: const Color(0xFF4A90E2),
            bg: const Color(0xFFEFF5FF),
            title: 'Difficulty',
            value: widget.plan.difficulty,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.event,
            iconColor: const Color(0xFF2E7D32),
            bg: const Color(0xFFE8F5E9),
            title: 'Workouts',
            value: '${widget.plan.workouts.length}',
          ),
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(widget.plan.description, style: AppTextStyle.regularText(size: 14, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildSchedule() {
    final items = widget.plan.workouts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Text('This plan has no scheduled workouts yet.', style: AppTextStyle.regularText(size: 13, color: Colors.grey[700])),
          )
        else
          ...items.asMap().entries.map((e) {
            final idx = e.key;
            final w = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Color(0xFF64B5F6), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Day ${w.dayOfWeek + 1}: Workout ${w.workoutId}', style: AppTextStyle.semiBoldText(size: 14, color: Colors.black)),
                    const SizedBox(height: 6),
                    Text('${w.sets} sets • ${w.reps}', style: AppTextStyle.regularText(size: 12, color: Colors.grey[700])),
                  ]),
                ),
              ]),
            );
          }).toList(),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.iconColor, required this.bg, required this.title, required this.value});
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    );
  }
}


