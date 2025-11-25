import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/er_models.dart';
import '../../services/mock_api.dart';
import '../../services/auth.dart';

class WorkoutPlanFormPage extends StatefulWidget {
  const WorkoutPlanFormPage({super.key});

  @override
  State<WorkoutPlanFormPage> createState() => _WorkoutPlanFormPageState();
}

class _WorkoutPlanFormPageState extends State<WorkoutPlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _durationMinutesCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();
  final _tagInputCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String _difficulty = 'beginner';
  String? _clientId;
  int _durationWeeks = 4;
  final List<String> _tags = [];
  XFile? _selectedImage;
  String? _imageBase64;

  final List<_DayPlan> _days = [
    _DayPlan(dayName: 'Monday', exercises: [
      _ExerciseRow(showHeader: false),
    ]),
  ];

  void _addDay() {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final idx = _days.length % names.length;
    setState(() {
      _days.add(_DayPlan(dayName: names[idx], exercises: [_ExerciseRow()]));
    });
  }

  void _addTag() {
    final tag = _tagInputCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputCtrl.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        // Convert image to base64 for storage
        final bytes = await image.readAsBytes();
        _imageBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _goalCtrl.dispose();
    _durationMinutesCtrl.dispose();
    _kcalCtrl.dispose();
    _equipmentCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final trainer = MockAuthService.instance.currentUser;
    // Calculate exercises count from all days
    int totalExercises = 0;
    for (final day in _days) {
      totalExercises += day.exercises.length;
    }

    final plan = WorkoutPlanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trainerId: trainer.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      difficulty: _difficulty,
      workouts: const [],
      durationMinutes: int.tryParse(_durationMinutesCtrl.text),
      kcal: int.tryParse(_kcalCtrl.text),
      exercisesCount: totalExercises > 0 ? totalExercises : null,
      tags: _tags.isNotEmpty ? _tags : null,
      equipment: _equipmentCtrl.text.trim().isEmpty ? null : _equipmentCtrl.text.trim(),
      imageUrl: _imageBase64 != null ? 'data:image/jpeg;base64,$_imageBase64' : null,
    );
    await const MockApiService().addWorkoutPlan(plan);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout Plan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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
                  _labeled('Plan Name *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g., Beginner Full Body'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _labeled('Assign to Client *'),
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
                        decoration: const InputDecoration(hintText: 'Select client'),
                        onChanged: (v) => setState(() => _clientId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled('Duration (weeks)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: '$_durationWeeks',
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _durationWeeks = int.tryParse(v) ?? 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled('Difficulty'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _difficulty,
                              items: const [
                                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                              ],
                              onChanged: (v) => setState(() => _difficulty = v ?? 'beginner'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _labeled('Fitness Goal *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _goalCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'e.g., Build muscle, lose weight, improve endurance'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled('Duration (min)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _durationMinutesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g., 25'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled('Calories (kcal)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _kcalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g., 300'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _labeled('Tags'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagInputCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Add tag (e.g., Cardio, Full Body)',
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add_circle),
                        color: Colors.green,
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _labeled('Equipment'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _equipmentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g., None, Dumbbells, Gym',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _labeled('Workout Image'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_selectedImage!.path),
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select image from gallery',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Workout Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: const Color(0xFFEAF7D5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._days.map((d) => _DayCard(
                  day: d,
                  onAddExercise: () => setState(() => d.exercises.add(_ExerciseRow(showHeader: false))),
                  onRemove: () => setState(() => _days.remove(d)),
                  onRemoveExercise: (idx) => setState(() => d.exercises.removeAt(idx)),
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
                child: Text('Save Workout Plan'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ED957),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _labeled(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600));

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _DayPlan {
  _DayPlan({required this.dayName, required this.exercises});
  String dayName;
  List<_ExerciseRow> exercises;
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.onAddExercise, required this.onRemove, required this.onRemoveExercise});
  final _DayPlan day;
  final VoidCallback onAddExercise;
  final VoidCallback onRemove;
  final void Function(int index) onRemoveExercise;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18)),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < day.exercises.length; i++) ...[
          Row(
            children: [
              Text('Exercise ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: () => onRemoveExercise(i),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Delete Exercise',
              ),
            ],
          ),
          const SizedBox(height: 6),
          day.exercises[i],
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddExercise,
          icon: const Icon(Icons.add),
          label: const Text('Add Exercise'),
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )
      ]),
    );
  }
}

class _ExerciseRow extends StatefulWidget {
  const _ExerciseRow({Key? key, this.index, this.onDelete, this.showHeader = true}) : super(key: key);
  final int? index;
  final VoidCallback? onDelete;
  final bool showHeader;
  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  final nameCtrl = TextEditingController();
  final setsCtrl = TextEditingController(text: '3');
  final repsCtrl = TextEditingController(text: '10');
  final restCtrl = TextEditingController(text: '60');
  @override
  void dispose() {
    nameCtrl.dispose();
    setsCtrl.dispose();
    repsCtrl.dispose();
    restCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.showHeader)
          Row(
            children: [
              Text('Exercise ${widget.index ?? 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (widget.onDelete != null)
                IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
            ],
          ),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Exercise name'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: setsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: repsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: restCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rest (s)'),
              ),
            ),
          ],
        )
      ]),
    );
  }
}


