import 'package:activex_gym_app/widgets/trainer_fab.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/mock_api.dart';
import '../models/er_models.dart';
import '../utils/app_text_style.dart';
import '../services/auth.dart';
import 'workout_plan_form_page.dart';

class WorkoutPlansPage extends StatefulWidget {
  const WorkoutPlansPage({super.key});

  @override
  State<WorkoutPlansPage> createState() => _WorkoutPlansPageState();
}

class _WorkoutPlansPageState extends State<WorkoutPlansPage> {
  final api = const MockApiService();

  Future<void> _delete(String id) async {
    await api.deleteWorkoutPlan(id);
    setState(() {});
  }

  Future<void> _editDialog(WorkoutPlanModel p) async {
    final nameCtrl = TextEditingController(text: p.name);
    final descCtrl = TextEditingController(text: p.description);
    String difficulty = p.difficulty;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Plan'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                  ],
                  onChanged: (v) => difficulty = v ?? p.difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );
    if (saved == true) {
      await api.updateWorkoutPlan(id: p.id, name: nameCtrl.text, description: descCtrl.text, difficulty: difficulty);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                )
              ],
            ),
          )
        ],
      ),
     // floatingActionButton: TrainerFab(page: 'workout'),
      body: FutureBuilder<List<WorkoutPlanModel>>(
        future: api.fetchWorkoutPlans(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AdminStatsRow(total: plans.length),
              const SizedBox(height: 12),
              
              _CreateButton(onTap: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const WorkoutPlanFormPage()),
                );
                if (created == true) setState(() {});
              }),
               const SizedBox(height: 12),
              _FilterChips(),
          const SizedBox(height: 12),
              ...List.generate(plans.length, (i) {
                final p = plans[i];
              final heroImage = _planHeroImage(p.name);
                return InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: CachedNetworkImage(
                            imageUrl: heroImage,
                            fit: BoxFit.cover,
                            placeholder: (c, _) => Container(color: Colors.grey[200]),
                            errorWidget: (c, _, __) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
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
                                  child: Text(p.name, style: AppTextStyle.semiBoldText(size: 16, color: Colors.black)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p.difficulty,
                                    style: AppTextStyle.mediumText(size: 11, color: const Color(0xFF2E7D32)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editDialog(p);
                                    } else if (value == 'delete') {
                                      _delete(p.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Coach Amy', style: AppTextStyle.regularText(size: 12, color: Colors.grey[800])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyle.regularText(size: 13, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            // Badges row (difficulty + status)
                            Row(
                              children: [
                                _chip(text: _difficultyLabel(p.difficulty), bg: const Color(0xFFE8F5E9), fg: const Color(0xFF2E7D32)),
                                const SizedBox(width: 8),
                                _chip(text: _statusLabel(i), bg: const Color(0xFFF1F8E9), fg: const Color(0xFF558B2F)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Weeks and sessions per week
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('${_weeks(i)} weeks', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                                const SizedBox(width: 18),
                                const Icon(Icons.sensors, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('${_sessionsPerWeek(i)}x per week', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.event, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Started: ${_startDate(i)}', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text('Progress', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                                const Spacer(),
                                Text('${(_progress(i) * 100).round()}%', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _ProgressBar(value: _progress(i)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
              }),
            ],
          );
        },
      ),
    );
  }
}

String _planHeroImage(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('strength')) {
    return 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('cardio')) {
    return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=800&auto=format&fit=crop';
  }
  return 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=800&auto=format&fit=crop';
}

class _AdminStatsRow extends StatelessWidget {
  const _AdminStatsRow({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) {
    Widget card(String title, String value, {Color bg = const Color(0xFFF5FBEF)}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[800])),
          ]),
        ),
      );
    }

    return Row(
      children: [
        card('Active', (total ~/ 2).toString()),
        const SizedBox(width: 12),
        card('Completed', (total ~/ 3).toString(), bg: const Color(0xFFF1F8E9)),
        const SizedBox(width: 12),
        card('Drafts', (total ~/ 5).toString(), bg: const Color(0xFFF8F9FA)),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text('Create New Workout Plan'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7ED957),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filters = ['All Plans', 'Active', 'Completed', 'Drafts'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Chip(
            label: Text(filters[i]),
            backgroundColor: i == 0 ? Colors.black : Colors.grey[200],
            labelStyle: TextStyle(color: i == 0 ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation(Color(0xFF7ED957)),
      ),
    );
  }
}

// Helpers for labels and sample values (until backend provides these fields)
Widget _chip({required String text, required Color bg, required Color fg}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

String _difficultyLabel(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'advanced':
      return 'Advanced';
    case 'intermediate':
      return 'Intermediate';
    default:
      return 'Beginner';
  }
}

String _statusLabel(int i) {
  const statuses = ['Active', 'Completed', 'Draft'];
  return statuses[i % statuses.length];
}

int _weeks(int i) => [4, 6, 8, 10, 12][i % 5];
int _sessionsPerWeek(int i) => [2, 3, 4, 5, 6][i % 5];
String _startDate(int i) {
  final d = DateTime.now().subtract(Duration(days: 7 * (i + 1)));
  return '${_month(d.month)} ${d.day}, ${d.year}';
}

String _month(int m) {
  const mm = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return mm[m - 1];
}

double _progress(int i) => (0.2 + (i % 10) * 0.08).clamp(0.0, 1.0);


