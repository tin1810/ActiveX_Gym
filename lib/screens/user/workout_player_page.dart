import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../utils/app_text_style.dart';

class WorkoutPlayerPage extends StatefulWidget {
  const WorkoutPlayerPage({
    super.key,
    required this.workout,
  });

  final WorkoutModel workout;

  @override
  State<WorkoutPlayerPage> createState() => _WorkoutPlayerPageState();
}

class _WorkoutPlayerPageState extends State<WorkoutPlayerPage> {
  int _currentExerciseIndex = 0;
  bool _workoutStarted = false;
  bool _workoutCompleted = false;
  int _totalElapsedSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWorkout() {
    setState(() {
      _workoutStarted = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _totalElapsedSeconds++;
        });
      }
    });
  }

  void _completeExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      _timer?.cancel();
      setState(() {
        _workoutCompleted = true;
      });
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_workoutStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Start Workout'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workout.title,
                style: AppTextStyle.boldText(size: 28, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.workout.exercises.length} exercises • ${widget.workout.durationMinutes} min',
                style: AppTextStyle.regularText(size: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercises',
                      style: AppTextStyle.semiBoldText(size: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    ...widget.workout.exercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                exercise.title,
                                style: AppTextStyle.mediumText(size: 14, color: Colors.black),
                              ),
                            ),
                            Text(
                              '${exercise.sets} sets',
                              style: AppTextStyle.regularText(size: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Start Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

    if (_workoutCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Workout Complete'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Great Job!',
                style: AppTextStyle.boldText(size: 28, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed ${widget.workout.title}',
                style: AppTextStyle.regularText(size: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.timer,
                          label: 'Time',
                          value: _formatTime(_totalElapsedSeconds),
                        ),
                        _StatItem(
                          icon: Icons.fitness_center,
                          label: 'Exercises',
                          value: '${widget.workout.exercises.length}',
                        ),
                        _StatItem(
                          icon: Icons.local_fire_department,
                          label: 'Calories',
                          value: '~${widget.workout.kcal}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Finish',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!mounted) return;
        final navigator = Navigator.of(context);
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Workout?'),
            content: const Text('Are you sure you want to exit? Your progress will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Exercise ${_currentExerciseIndex + 1} of ${widget.workout.exercises.length}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formatTime(_totalElapsedSeconds),
                  style: AppTextStyle.semiBoldText(size: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        body: _ExercisePlayerWrapper(
          exercise: currentExercise,
          onComplete: _completeExercise,
          isLastExercise: _currentExerciseIndex == widget.workout.exercises.length - 1,
        ),
      ),
    );
  }
}

class _ExercisePlayerWrapper extends StatefulWidget {
  const _ExercisePlayerWrapper({
    required this.exercise,
    required this.onComplete,
    required this.isLastExercise,
  });

  final ExerciseModel exercise;
  final VoidCallback onComplete;
  final bool isLastExercise;

  @override
  State<_ExercisePlayerWrapper> createState() => _ExercisePlayerWrapperState();
}

class _ExercisePlayerWrapperState extends State<_ExercisePlayerWrapper> {
  int _currentSet = 0;
  bool _inRest = false;
  int _remaining = 0;
  Timer? _timer;
  bool _paused = false;
  bool _done = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startOrNext() {
    if (_inRest) return;
    if (_currentSet >= widget.exercise.sets) return;
    setState(() => _currentSet++);
    if (_currentSet < widget.exercise.sets) {
      _startRest();
    } else {
      setState(() => _done = true);
    }
  }

  void _startRest() {
    setState(() {
      _inRest = true;
      _remaining = widget.exercise.restSeconds;
      _paused = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _inRest = false;
          _remaining = 0;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
  }

  void _finishExercise() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.title,
            style: AppTextStyle.boldText(size: 24, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Sets: ${widget.exercise.sets}   Reps: ${widget.exercise.reps}',
            style: AppTextStyle.regularText(size: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Current Set',
                  style: AppTextStyle.regularText(size: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_currentSet / ${widget.exercise.sets}',
                  style: AppTextStyle.boldText(size: 32, color: Colors.black),
                ),
                const SizedBox(height: 16),
                if (_done)
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56)
                else if (_inRest)
                  Column(
                    children: [
                      Text(
                        'Rest',
                        style: AppTextStyle.semiBoldText(size: 16, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_remaining s',
                        style: AppTextStyle.boldText(size: 28, color: Colors.black),
                      ),
                    ],
                  )
                else
                  Text(
                    'Do ${widget.exercise.reps} reps',
                    style: AppTextStyle.semiBoldText(size: 18, color: Colors.black),
                  ),
              ],
            ),
          ),
          const Spacer(),
          if (_inRest)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: Colors.black),
                  label: Text(
                    _paused ? 'Resume' : 'Pause',
                    style: AppTextStyle.mediumText(size: 14, color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _done
                  ? _finishExercise
                  : (_inRest ? null : _startOrNext),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                _done
                    ? (widget.isLastExercise ? 'Complete Workout' : 'Next Exercise')
                    : (_inRest
                        ? 'Resting...'
                        : (_currentSet == 0 ? 'Start' : 'Next Set')),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyle.boldText(size: 18, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyle.regularText(size: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

