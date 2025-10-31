import 'package:flutter/material.dart';
import '../models/er_models.dart';
import '../services/mock_api.dart';
import '../services/auth.dart';

class NutritionPlanFormPage extends StatefulWidget {
  const NutritionPlanFormPage({super.key});

  @override
  State<NutritionPlanFormPage> createState() => _NutritionPlanFormPageState();
}

class _NutritionPlanFormPageState extends State<NutritionPlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController(text: '2000');
  int _durationWeeks = 4;
  String? _clientId;
  String _dietType = 'Balanced';

  final List<_MealDayPlan> _days = [
    _MealDayPlan(dayName: 'Monday', meals: [
      _MealRow(),
    ]),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final trainer = MockAuthService.instance.currentUser;
    final plan = NutritionPlanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trainerId: trainer.id,
      name: _nameCtrl.text.trim(),
      description: _goalCtrl.text.trim(),
      dailyCaloriesTarget: int.tryParse(_kcalCtrl.text.trim()) ?? 1800,
      meals: const [],
    );
    await const MockApiService().addNutritionPlan(plan);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _addDay() {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final idx = _days.length % names.length;
    setState(() {
      _days.add(_MealDayPlan(dayName: names[idx], meals: [_MealRow()]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Meal Plan'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      backgroundColor: const Color(0xFFF7F7F7),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Basic Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Plan Name *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g., High Protein Diet'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Assign to Client *'),
                  const SizedBox(height: 6),
                  FutureBuilder<List<UserModel>>(
                    future: const MockApiService().fetchUsers(),
                    builder: (context, snapshot) {
                      final users = (snapshot.data ?? []).where((u) => u.role == 'user').toList();
                      return DropdownButtonFormField<String>(
                        value: _clientId,
                        items: users
                            .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _clientId = v),
                        decoration: const InputDecoration(hintText: 'Select client'),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Duration (weeks)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: '$_durationWeeks',
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _durationWeeks = int.tryParse(v) ?? 4,
                          ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Daily Calories'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _kcalCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('Diet Type'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _dietType,
                    items: const [
                      DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
                      DropdownMenuItem(value: 'Keto', child: Text('Keto')),
                      DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
                    ],
                    onChanged: (v) => setState(() => _dietType = v ?? 'Balanced'),
                  ),
                  const SizedBox(height: 16),
                  _label('Nutrition Goal *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _goalCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'e.g., Muscle gain, weight loss, maintenance'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Meal Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: const Color(0xFFFFA726),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._days.map((d) => _MealDayCard(
                  day: d,
                  onAddMeal: () => setState(() => d.meals.add(_MealRow())),
                  onRemove: () => setState(() => _days.remove(d)),
                  onRemoveMeal: (idx) => setState(() => d.meals.removeAt(idx)),
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.lock),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save Meal Plan'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600));

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MealDayPlan {
  _MealDayPlan({required this.dayName, required this.meals});
  String dayName;
  List<_MealRow> meals;
}

class _MealDayCard extends StatelessWidget {
  const _MealDayCard({required this.day, required this.onAddMeal, required this.onRemove, required this.onRemoveMeal});
  final _MealDayPlan day;
  final VoidCallback onAddMeal;
  final VoidCallback onRemove;
  final void Function(int index) onRemoveMeal;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
        ]),
        const SizedBox(height: 8),
        for (int i = 0; i < day.meals.length; i++) ...[
          Row(children: [
            Text('Meal ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => onRemoveMeal(i), icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
          ]),
          const SizedBox(height: 6),
          day.meals[i],
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: onAddMeal,
          icon: const Icon(Icons.add),
          label: const Text('Add Meal'),
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )
      ]),
    );
  }
}

class _MealRow extends StatefulWidget {
  @override
  State<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<_MealRow> {
  String _type = 'Breakfast';
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatsCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(
          value: _type,
          items: const [
            DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
            DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
            DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
            DropdownMenuItem(value: 'Snack', child: Text('Snack')),
          ],
          onChanged: (v) => setState(() => _type = v ?? 'Breakfast'),
        ),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Meal name')),
        const SizedBox(height: 8),
        TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Description / ingredients')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _kcalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _proteinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _carbsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _fatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fats (g)'))),
        ]),
      ]),
    );
  }
}


