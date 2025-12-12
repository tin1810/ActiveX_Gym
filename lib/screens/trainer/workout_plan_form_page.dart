import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/er_models.dart';
import '../../models/exercise.dart';
import '../../services/network_service.dart';
import '../../services/auth.dart';

class WorkoutPlanFormPage extends StatefulWidget {
  const WorkoutPlanFormPage({super.key, this.workoutPlan});

  final WorkoutPlanModel? workoutPlan; // If provided, we're editing

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

  List<_DayPlan> _days = [];

  @override
  void initState() {
    super.initState();
    if (widget.workoutPlan != null) {
      // Load existing workout plan data for editing
      _loadWorkoutPlanData(widget.workoutPlan!);
      // Load workout schedule asynchronously
      _loadWorkoutSchedule(widget.workoutPlan!.workouts);
    } else {
      // Create mode - start with one day
      _days = [
        _DayPlan(dayName: 'Monday', exercises: [
          _ExerciseRow(showHeader: false, key: GlobalKey<_ExerciseRowState>()),
        ]),
      ];
    }
  }

  void _loadWorkoutPlanData(WorkoutPlanModel plan) {
    _nameCtrl.text = plan.name;
    _descCtrl.text = plan.description;
    _difficulty = plan.difficulty;
    if (plan.durationMinutes != null) {
      _durationMinutesCtrl.text = plan.durationMinutes.toString();
    }
    if (plan.kcal != null) {
      _kcalCtrl.text = plan.kcal.toString();
    }
    if (plan.equipment != null) {
      _equipmentCtrl.text = plan.equipment!;
    }
    if (plan.tags != null) {
      _tags.addAll(plan.tags!);
    }
    // Load selected user/client ID
    if (plan.userId != null && plan.userId!.isNotEmpty) {
      _clientId = plan.userId;
    }
    // Load existing image - handle both base64 data URI and regular URLs
    if (plan.imageUrl != null && plan.imageUrl!.isNotEmpty) {
      if (plan.imageUrl!.startsWith('data:image')) {
        // Load existing base64 image - extract base64 part
        try {
          final parts = plan.imageUrl!.split(',');
          if (parts.length > 1) {
            _imageBase64 = parts[1];
          }
        } catch (e) {
          // If parsing fails, leave it null
          print('Error parsing base64 image: $e');
        }
      } else {
        // It's a regular URL - we'll display it using Image.network in the UI
        // Store the URL in _imageBase64 as a marker, or create a separate variable
        // For now, we'll handle it in the display logic
        _imageBase64 = plan.imageUrl; // Store URL temporarily
      }
    }
  }

  Future<void> _loadWorkoutSchedule(List<PlanWorkoutModel> workouts) async {
    // Day names mapping (1 = Monday, 7 = Sunday)
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // Group workouts by dayOfWeek
    final workoutsByDay = <int, List<PlanWorkoutModel>>{};
    for (var workout in workouts) {
      final day = workout.dayOfWeek;
      if (day >= 1 && day <= 7) {
        workoutsByDay.putIfAbsent(day, () => []).add(workout);
      }
    }
    
    // Fetch all exercises to match by ID
    final exercisesList = await const ApiServiceFor().fetchExercises(limit: 100);
    final exercisesMap = {for (var e in exercisesList) e.id: e};
    
    // Create day plans with exercises
    final List<_DayPlan> loadedDays = [];
    
    // If no workouts, start with one empty day
    if (workoutsByDay.isEmpty) {
      loadedDays.add(_DayPlan(
        dayName: 'Monday',
        exercises: [_ExerciseRow(showHeader: false, key: GlobalKey<_ExerciseRowState>())],
      ));
    } else {
      // Create days for each dayOfWeek that has workouts
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        if (workoutsByDay.containsKey(dayOfWeek)) {
          final dayWorkouts = workoutsByDay[dayOfWeek]!;
          final dayName = dayNames[dayOfWeek - 1];
          
          // Create exercise rows for each workout
          final List<_ExerciseRow> exerciseRows = [];
          for (var workout in dayWorkouts) {
            final exerciseKey = GlobalKey<_ExerciseRowState>();
            final exerciseRow = _ExerciseRow(showHeader: false, key: exerciseKey);
            exerciseRows.add(exerciseRow);
            
            // Set the exercise after the widget is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final exercise = exercisesMap[workout.workoutId];
              if (exercise != null && exerciseKey.currentState != null) {
                exerciseKey.currentState!.setExercise(exercise, sets: workout.sets, reps: workout.reps);
              }
            });
          }
          
          loadedDays.add(_DayPlan(dayName: dayName, exercises: exerciseRows));
        }
      }
    }
    
    setState(() {
      _days = loadedDays;
    });
  }

  void _addDay() {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final idx = _days.length % names.length;
    setState(() {
      _days.add(_DayPlan(dayName: names[idx], exercises: [_ExerciseRow(key: GlobalKey<_ExerciseRowState>())]));
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
        // Convert image to base64 for storage
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        // Update state with both selected image and base64
        setState(() {
          _selectedImage = image;
          _imageBase64 = base64String;
        });
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

  Widget _buildImagePreview() {
    // Priority 1: Show newly selected image from gallery
    if (_selectedImage != null) {
      return Stack(
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
      );
    }
    
    // Priority 2: Show existing base64 image (from API or previously converted)
    if (_imageBase64 != null) {
      // Check if it's a base64 data URI or a regular URL
      if (_imageBase64!.startsWith('data:image')) {
        // Extract base64 part from data URI
        try {
          final parts = _imageBase64!.split(',');
          if (parts.length > 1) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(parts[1]),
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
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
            );
          }
        } catch (e) {
          print('Error decoding base64 image: $e');
          return _buildPlaceholder();
        }
      } else if (_imageBase64!.startsWith('http://') || _imageBase64!.startsWith('https://')) {
        // It's a regular URL - display using Image.network
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _imageBase64!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
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
        );
      } else {
        // Try to decode as pure base64 string (without data URI prefix)
        try {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_imageBase64!),
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
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
          );
        } catch (e) {
          print('Error decoding base64 string: $e');
          return _buildPlaceholder();
        }
      }
    }
    
    // Priority 3: Show existing image from workout plan (if editing)
    if (widget.workoutPlan?.imageUrl != null && widget.workoutPlan!.imageUrl!.isNotEmpty) {
      final imageUrl = widget.workoutPlan!.imageUrl!;
      if (imageUrl.startsWith('data:image')) {
        // Base64 data URI
        try {
          final parts = imageUrl.split(',');
          if (parts.length > 1) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(parts[1]),
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
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
            );
          }
        } catch (e) {
          print('Error decoding existing base64 image: $e');
          return _buildPlaceholder();
        }
      } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        // Regular URL
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
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
        );
      }
    }
    
    // Priority 4: Show placeholder if no image
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap to select image from gallery',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
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
    
    // Validate description is not empty
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final trainer = MockAuthService.instance.currentUser;
    
    // Build workouts list from days and exercises
    final List<PlanWorkoutModel> workouts = [];
    final List<String> invalidExerciseIds = [];
    
    for (int dayIndex = 0; dayIndex < _days.length; dayIndex++) {
      final day = _days[dayIndex];
      for (final exerciseRow in day.exercises) {
        final key = exerciseRow.key;
        if (key != null && key is GlobalKey<_ExerciseRowState>) {
          final state = key.currentState;
          if (state != null && state.selectedExercise != null) {
            final exercise = state.selectedExercise!;
            final sets = int.tryParse(state.sets) ?? 3;
            final reps = state.reps.trim();
            
            // Validate exercise ID is not empty and looks like a valid UUID
            if (reps.isNotEmpty && exercise.id.isNotEmpty) {
              // Check if ID looks like a UUID (basic validation)
              final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
              if (!uuidPattern.hasMatch(exercise.id)) {
                invalidExerciseIds.add('${exercise.title} (ID: ${exercise.id})');
                continue;
              }
              
              workouts.add(PlanWorkoutModel(
                workoutId: exercise.id,
                dayOfWeek: dayIndex + 1, // API expects 1-7 (Monday=1, Sunday=7)
                sets: sets,
                reps: reps,
              ));
            } else if (reps.isEmpty) {
              invalidExerciseIds.add('${exercise.title} (missing reps)');
            } else if (exercise.id.isEmpty) {
              invalidExerciseIds.add('${exercise.title} (invalid ID)');
            }
          }
        }
      }
    }
    
    // Validate that at least one workout is added
    if (workouts.isEmpty) {
      String errorMsg = 'Please add at least one exercise to the workout plan';
      if (invalidExerciseIds.isNotEmpty) {
        errorMsg += '\n\nInvalid exercises:\n${invalidExerciseIds.join('\n')}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // Warn about invalid exercises but continue if we have at least one valid
    if (invalidExerciseIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Some exercises were skipped due to invalid IDs:\n${invalidExerciseIds.join('\n')}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    
    // Calculate exercises count from all days
    int totalExercises = 0;
    for (final day in _days) {
      totalExercises += day.exercises.length;
    }

    final plan = WorkoutPlanModel(
      id: widget.workoutPlan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      trainerId: trainer.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      difficulty: _difficulty,
      workouts: workouts,
      durationMinutes: int.tryParse(_durationMinutesCtrl.text),
      kcal: int.tryParse(_kcalCtrl.text),
      exercisesCount: totalExercises > 0 ? totalExercises : null,
      tags: _tags.isNotEmpty ? _tags : null,
      equipment: _equipmentCtrl.text.trim().isEmpty ? null : _equipmentCtrl.text.trim(),
      imageUrl: _imageBase64 != null 
          ? 'data:image/jpeg;base64,$_imageBase64' 
          : widget.workoutPlan?.imageUrl, // Keep existing image if not changed
      userId: _clientId, // Selected user/client ID from dropdown
    );

    // Debug: Print workout IDs being sent
    print('Submitting workout plan with ${workouts.length} workouts:');
    for (var w in workouts) {
      print('  - workoutId: ${w.workoutId}, dayOfWeek: ${w.dayOfWeek}, sets: ${w.sets}, reps: ${w.reps}');
    }
    
    try {
      if (widget.workoutPlan != null) {
        // Update existing plan
        await const ApiServiceFor().updateWorkoutPlanFull(plan);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Create new plan
        await const ApiServiceFor().addWorkoutPlan(plan);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
        
        // Check if error mentions invalid workoutId
        if (errorMessage.contains('workoutId') && errorMessage.contains('invalid')) {
          errorMessage = 'One or more exercise IDs are invalid. Please ensure:\n'
              '1. Exercises are created in the backend first\n'
              '2. You are using exercises from the API (not local/mock data)\n'
              '3. Exercise IDs are valid UUIDs\n\n'
              'Original error: $errorMessage';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutPlan == null ? 'Create Workout Plan' : 'Edit Workout Plan'),
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
                    future: const ApiServiceFor().fetchUsers(),
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
                  _labeled('Description *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Describe the workout plan (e.g., A 4-week plan for beginners)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
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
                      child: _buildImagePreview(),
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
                  onAddExercise: () => setState(() => d.exercises.add(_ExerciseRow(showHeader: false, key: GlobalKey<_ExerciseRowState>()))),
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
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(widget.workoutPlan == null ? 'Create Workout Plan' : 'Update Workout Plan'),
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
  final setsCtrl = TextEditingController(text: '3');
  final repsCtrl = TextEditingController(text: '10');
  final restCtrl = TextEditingController(text: '60');
  ExerciseModel? _selectedExercise;
  late Future<List<ExerciseModel>> _exercisesFuture;
  
  // Public getters to access exercise data
  ExerciseModel? get selectedExercise => _selectedExercise;
  String get sets => setsCtrl.text;
  String get reps => repsCtrl.text;

  // Method to set exercise programmatically (for loading existing data)
  void setExercise(ExerciseModel? exercise, {int? sets, String? reps}) {
    if (exercise != null) {
      setState(() {
        _selectedExercise = exercise;
        if (sets != null) setsCtrl.text = sets.toString();
        if (reps != null) repsCtrl.text = reps;
        // Auto-fill rest from selected exercise if not already set
        if (restCtrl.text == '60') {
          restCtrl.text = exercise.restSeconds.toString();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch exercises from API with limit 20
    _exercisesFuture = const ApiServiceFor().fetchExercises(limit: 20);
  }

  void _onExerciseSelected(ExerciseModel? exercise) {
    if (exercise != null) {
      setState(() {
        _selectedExercise = exercise;
        // Auto-fill sets, reps, and rest from selected exercise
        setsCtrl.text = exercise.sets.toString();
        repsCtrl.text = exercise.reps;
        restCtrl.text = exercise.restSeconds.toString();
      });
    }
  }

  @override
  void dispose() {
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
        FutureBuilder<List<ExerciseModel>>(
          future: _exercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error loading exercises: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No exercises available. Create exercises first.',
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final exercises = snapshot.data!;
            return DropdownButtonFormField<ExerciseModel>(
              value: _selectedExercise,
              decoration: const InputDecoration(
                labelText: 'Exercise name *',
                border: OutlineInputBorder(),
                hintText: 'Select an exercise',
              ),
              items: exercises.map((exercise) {
                return DropdownMenuItem<ExerciseModel>(
                  value: exercise,
                  child: Text(exercise.title),
                );
              }).toList(),
              onChanged: _onExerciseSelected,
              validator: (value) => value == null ? 'Please select an exercise' : null,
            );
          },
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


