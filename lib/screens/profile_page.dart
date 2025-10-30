import 'package:flutter/material.dart';
import '../utils/app_text_style.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Profile Info
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7ED957), Color(0xFF6BCF56)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture and Name
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'William Johnson',
                                style: AppTextStyle.boldText(
                                  size: 24,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fitness Enthusiast',
                                style: AppTextStyle.regularText(
                                  size: 14,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Premium Member',
                                  style: AppTextStyle.mediumText(
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('47', 'Workouts'),
                        _buildStat('12.4K', 'Calories'),
                        _buildStat('7 days', 'Streak'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Actions',
                  style: AppTextStyle.boldText(
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.emoji_events_outlined,
                        title: 'My Goals',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.favorite_outline,
                        title: 'Welcome',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Account Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Account',
                  style: AppTextStyle.boldText(
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Account Items
              ..._buildAccountItems(),

              const SizedBox(height: 24),

              // Sign Out Button
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle sign out
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: AppTextStyle.mediumText(
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Version Info
              Center(
                child: Text(
                  'ActiveXtra v2.1.0',
                  style: AppTextStyle.regularText(
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyle.boldText(
            size: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyle.regularText(
            size: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyle.mediumText(
              size: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccountItems() {
    final items = [
      _AccountItem(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'App preferences',
      ),
      _AccountItem(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Manage alerts',
      ),
      _AccountItem(
        icon: Icons.favorite_outline,
        title: 'Health Data',
        subtitle: 'Connect devices',
      ),
      _AccountItem(
        icon: Icons.emoji_events_outlined,
        title: 'Achievements',
        subtitle: 'View all badges',
      ),
      _AccountItem(
        icon: Icons.people_outline,
        title: 'Friends',
        subtitle: 'Invite & connect',
      ),
      _AccountItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'Get assistance',
      ),
    ];

    return items.map((item) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildAccountItemWidget(item),
      );
    }).toList();
  }

  Widget _buildAccountItemWidget(_AccountItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyle.semiBoldText(
                    size: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: AppTextStyle.regularText(
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _AccountItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _AccountItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
