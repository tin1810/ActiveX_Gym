import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/mock_api.dart';
import '../../services/auth.dart';

class ExerciseFormPage extends StatefulWidget {
  const ExerciseFormPage({super.key, this.exercise});

  final ExerciseModel? exercise; // If provided, we're editing

  @override
  State<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends State<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _restSecondsCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  String _difficulty = 'Beginner';
  final List<String> _targetMuscles = [];
  final _muscleInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      final ex = widget.exercise!;
      _titleCtrl.text = ex.title;
      _setsCtrl.text = ex.sets.toString();
      _repsCtrl.text = ex.reps;
      _restSecondsCtrl.text = ex.restSeconds.toString();
      _videoUrlCtrl.text = ex.videoUrl;
      _difficulty = ex.difficulty;
      _targetMuscles.addAll(ex.targetMuscles);
      if (ex.instructions != null) {
        _instructionsCtrl.text = ex.instructions!.join('\n');
      }
    } else {
      _videoUrlCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _restSecondsCtrl.dispose();
    _videoUrlCtrl.dispose();
    _instructionsCtrl.dispose();
    _muscleInputCtrl.dispose();
    super.dispose();
  }

  void _addMuscle() {
    final muscle = _muscleInputCtrl.text.trim();
    if (muscle.isNotEmpty && !_targetMuscles.contains(muscle)) {
      setState(() {
        _targetMuscles.add(muscle);
        _muscleInputCtrl.clear();
      });
    }
  }

  void _removeMuscle(String muscle) {
    setState(() {
      _targetMuscles.remove(muscle);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one target muscle')),
      );
      return;
    }

    final instructions = _instructionsCtrl.text.trim().isEmpty
        ? null
        : _instructionsCtrl.text.trim().split('\n').where((s) => s.trim().isNotEmpty).toList();

    final exercise = ExerciseModel(
      id: widget.exercise?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      difficulty: _difficulty,
      sets: int.tryParse(_setsCtrl.text) ?? 3,
      reps: _repsCtrl.text.trim(),
      restSeconds: int.tryParse(_restSecondsCtrl.text) ?? 60,
      targetMuscles: _targetMuscles,
      videoUrl: _videoUrlCtrl.text.trim(),
      instructions: instructions,
    );

    try {
      if (widget.exercise != null) {
        await const MockApiService().updateExercise(exercise);
      } else {
        await const MockApiService().addExercise(exercise);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Trainer/Admin only')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? 'Create Exercise' : 'Edit Exercise'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Exercise Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 'Beginner'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sets *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Required';
                      if (int.tryParse(v!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reps * (e.g., 10-15)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _restSecondsCtrl,
              decoration: const InputDecoration(
                labelText: 'Rest Time (seconds) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Required';
                if (int.tryParse(v!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Video URL *',
                border: OutlineInputBorder(),
                hintText: 'YouTube URL or video link (e.g., https://www.youtube.com/watch?v=...)',
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Video URL is required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Target Muscles *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _muscleInputCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add muscle group',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Chest, Triceps',
                    ),
                    onSubmitted: (_) => _addMuscle(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMuscle,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.green,
                ),
              ],
            ),
            if (_targetMuscles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _targetMuscles.map((muscle) {
                  return Chip(
                    label: Text(muscle),
                    onDeleted: () => _removeMuscle(muscle),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Instructions (one per line)',
                border: OutlineInputBorder(),
                hintText: 'Enter instructions, one per line',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text('Save Exercise', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

