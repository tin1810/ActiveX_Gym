import '../trainer/nutrition_plan_form_page.dart';
import 'package:flutter/material.dart';
import '../../services/network_service.dart';
import '../../models/er_models.dart';
import '../../utils/app_text_style.dart';
import '../../services/auth.dart';

class NutritionPlansPage extends StatefulWidget {
  const NutritionPlansPage({super.key});

  @override
  State<NutritionPlansPage> createState() => _NutritionPlansPageState();
}

class _NutritionPlansPageState extends State<NutritionPlansPage> {
  final api = const ApiServiceFor();

  Future<void> _delete(String id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Nutrition Plan'),
          content: const Text('Are you sure you want to delete this nutrition plan? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await api.deleteNutritionPlan(id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrition plan deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(12);
      } else if (errorMessage.startsWith('Exception:')) {
        errorMessage = errorMessage.substring(10);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _editDialog(NutritionPlanModel p) async {
    final nameCtrl = TextEditingController(text: p.name);
    final descCtrl = TextEditingController(text: p.description);
    final kcalCtrl = TextEditingController(text: p.dailyCaloriesTarget.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Nutrition Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kcalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily Calories Target *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate fields
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name is required'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                if (descCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Description is required'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                if (kcalCtrl.text.trim().isEmpty || int.tryParse(kcalCtrl.text.trim()) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Valid daily calories target is required'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      try {
        await api.updateNutritionPlan(
          id: p.id,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          dailyCaloriesTarget: int.tryParse(kcalCtrl.text.trim()),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition plan updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nutrition Plans'),
            Text(
              MockAuthService.instance.currentUser.name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: null,
      body: FutureBuilder<List<NutritionPlanModel>>(
        future: api.fetchNutritionPlans(limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading nutrition plans',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No nutrition plans found'));
          }
          final plans = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AdminStatsRowN(total: plans.length), const SizedBox(height: 12),
              if (MockAuthService.instance.isTrainer || MockAuthService.instance.isAdmin)
                _CreateButtonN(onTap: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const NutritionPlanFormPage()),
                  );
                  if (created == true) setState(() {});
                }),
              const SizedBox(height: 12),
              _FilterChipsN(),
            const SizedBox(height: 12),
              ...List.generate(plans.length, (i) {
                final p = plans[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.restaurant_menu, color: Color(0xFFFF9800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p.name, style: AppTextStyle.semiBoldText(size: 16, color: Colors.black))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                        child: Text('${p.dailyCaloriesTarget} kcal', style: AppTextStyle.mediumText(size: 11, color: const Color(0xFFFF9800))),
                      ),
                      const SizedBox(width: 6),
                      if (MockAuthService.instance.isTrainer || MockAuthService.instance.isAdmin)
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              _editDialog(p);
                            } else if (v == 'delete') {
                              _delete(p.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                    ]),
                    const SizedBox(height: 8),
                    // Badges row
                    Row(children: [
                      _pill('Balanced', const Color(0xFFEAF2FF), const Color(0xFF2F6BFF)),
                      const SizedBox(width: 8),
                      _pill(_statusLabel(i), const Color(0xFFFFF7E6), const Color(0xFFEF6C00)),
                    ]),
                    const SizedBox(height: 10),
                    // Weeks and kcal/day
                    Row(children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('${_weeks(i)} weeks', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                      const SizedBox(width: 18),
                      const Icon(Icons.local_fire_department, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('${p.dailyCaloriesTarget} kcal/day', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Started: ${_startDate(i)}', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Text('Progress', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                      const Spacer(),
                      Text('${(_progress(i) * 100).round()}%', style: AppTextStyle.mediumText(size: 12, color: Colors.grey[800])),
                    ]),
                    const SizedBox(height: 6),
                    _ProgressBarN(value: _progress(i)),
                  ]),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AdminStatsRowN extends StatelessWidget {
  const _AdminStatsRowN({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) {
    Widget card(String title, String value, {Color bg = const Color(0xFFFFF7E6)}) {
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

    return Row(children: [
      card('Active', (total ~/ 2).toString()),
      const SizedBox(width: 12),
      card('Completed', (total ~/ 3).toString(), bg: const Color(0xFFE8F5E9)),
      const SizedBox(width: 12),
      card('Drafts', (total ~/ 5).toString(), bg: const Color(0xFFF8F9FA)),
    ]);
  }
}

class _CreateButtonN extends StatelessWidget {
  const _CreateButtonN({required this.onTap});
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
          child: Text('Create New Meal Plan'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA726),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _FilterChipsN extends StatelessWidget {
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

class _ProgressBarN extends StatelessWidget {
  const _ProgressBarN({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFA726)),
      ),
    );
  }
}

Widget _pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );

String _statusLabel(int i) {
  const statuses = ['Active', 'Completed', 'Draft'];
  return statuses[i % statuses.length];
}

int _weeks(int i) => [4, 6, 8, 10, 12][i % 5];
String _startDate(int i) {
  final d = DateTime.now().subtract(Duration(days: 7 * (i + 1)));
  const mm = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${mm[d.month - 1]} ${d.day}, ${d.year}';
}

double _progress(int i) => (0.25 + (i % 8) * 0.09).clamp(0.0, 1.0);


