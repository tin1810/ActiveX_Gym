import 'package:flutter/material.dart';
import '../utils/app_text_style.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Your Progress Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your Progress',
                  style: AppTextStyle.boldText(
                    size: 24,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Progress Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressCard(
                            icon: Icons.track_changes,
                            value: '47',
                            title: 'Total Workouts',
                            change: '+8 this week',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressCard(
                            icon: Icons.show_chart,
                            value: '12.4K',
                            title: 'Calories Burned',
                            change: '+1.2K this week',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressCard(
                            icon: Icons.calendar_today,
                            value: '23',
                            title: 'Active Days',
                            change: '+5 this week',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressCard(
                            icon: Icons.emoji_events,
                            value: '7',
                            title: 'Current Streak',
                            change: '+2 this week',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // This Week Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'This Week',
                  style: AppTextStyle.boldText(
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Weekly Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildWeeklyChart(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '5 out of 7 days completed • 1,650 calories burned',
                  style: AppTextStyle.regularText(
                    size: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Achievements Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Achievements',
                      style: AppTextStyle.boldText(
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '8/12 Unlocked',
                        style: AppTextStyle.mediumText(
                          size: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Achievement Cards
              ..._buildAchievementCards(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String value,
    required String title,
    required String change,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF7ED957),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyle.boldText(
              size: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyle.regularText(
              size: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: AppTextStyle.mediumText(
              size: 11,
              color: const Color(0xFF7ED957),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const heights = [70.0, 50.0, 25.0, 85.0, 60.0, 25.0, 95.0];
    const colors = [
      Color(0xFF7ED957),
      Color(0xFF7ED957),
      Colors.grey,
      Color(0xFF7ED957),
      Color(0xFF7ED957),
      Colors.grey,
      Color(0xFF7ED957),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: heights[index],
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: AppTextStyle.regularText(
                        size: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAchievementCards() {
    return [
      _buildAchievementCard(
        icon: Icons.local_fire_department,
        iconColor: Colors.orange,
        iconBgColor: const Color(0xFFE8F5E9),
        title: '7-Day Streak',
        subtitle: 'Unlocked on Dec 15',
        isUnlocked: true,
      ),
      const SizedBox(height: 12),
      _buildAchievementCard(
        icon: Icons.directions_run,
        iconColor: Colors.blue,
        iconBgColor: const Color(0xFFE8F5E9),
        title: 'First 5K Run',
        subtitle: 'Unlocked on Dec 12',
        isUnlocked: true,
      ),
      const SizedBox(height: 12),
      _buildAchievementCard(
        icon: Icons.fitness_center,
        iconColor: Colors.purple,
        iconBgColor: Colors.grey[200]!,
        title: 'Strength Master',
        subtitle: 'Continue lifting heavy',
        isUnlocked: false,
        progress: 0.8,
      ),
      const SizedBox(height: 12),
      _buildAchievementCard(
        icon: Icons.self_improvement,
        iconColor: Colors.green,
        iconBgColor: Colors.grey[200]!,
        title: 'Yoga Warrior',
        subtitle: 'Keep your zen mode',
        isUnlocked: false,
        progress: 0.45,
      ),
    ];
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isUnlocked,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.semiBoldText(
                    size: 16,
                    color: Colors.black,
                  ),
                ),
                if (isUnlocked)
                  Text(
                    subtitle,
                    style: AppTextStyle.regularText(
                      size: 12,
                      color: const Color(0xFF7ED957),
                    ),
                  )
                else if (progress != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF7ED957),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (isUnlocked)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF7ED957),
                size: 20,
              ),
            )
          else if (progress != null)
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyle.semiBoldText(
                size: 14,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
