import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/app_text_style.dart';

class ExercisePlayerPage extends StatefulWidget {
  const ExercisePlayerPage({
    super.key,
    required this.exerciseName,
    required this.totalSets,
    required this.repsText,
    required this.restSeconds,
  });

  final String exerciseName;
  final int totalSets;
  final String repsText;
  final int restSeconds;

  @override
  State<ExercisePlayerPage> createState() => _ExercisePlayerPageState();
}

class _ExercisePlayerPageState extends State<ExercisePlayerPage> {
  int _currentSet = 0;
  bool _inRest = false;
  int _remaining = 0;
  Timer? _timer;
  bool _paused = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startOrNext() {
    if (_inRest) return; // ignore presses during rest
    if (_currentSet >= widget.totalSets) return;
    setState(() => _currentSet++);
    // After completing a set, start rest except after last set
    if (_currentSet < widget.totalSets) {
      _startRest();
    }
  }

  void _startRest() {
    setState(() {
      _inRest = true;
      _remaining = widget.restSeconds;
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

  @override
  Widget build(BuildContext context) {
    final done = _currentSet >= widget.totalSets && !_inRest;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Player'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exerciseName, style: AppTextStyle.boldText(size: 24, color: Colors.black)),
            const SizedBox(height: 8),
            Text('Sets: ${widget.totalSets}   Reps: ${widget.repsText}', style: AppTextStyle.regularText(size: 14, color: Colors.grey[700])),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text('Current Set', style: AppTextStyle.regularText(size: 14, color: Colors.grey[700])),
                const SizedBox(height: 6),
                Text('$_currentSet / ${widget.totalSets}', style: AppTextStyle.boldText(size: 32, color: Colors.black)),
                const SizedBox(height: 16),
                if (_inRest)
                  Column(children: [
                    Text('Rest', style: AppTextStyle.semiBoldText(size: 16, color: const Color(0xFF4CAF50))),
                    const SizedBox(height: 6),
                    Text('$_remaining s', style: AppTextStyle.boldText(size: 28, color: Colors.black)),
                  ])
                else if (done)
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56)
                else
                  Text('Do ${widget.repsText} reps', style: AppTextStyle.semiBoldText(size: 18, color: Colors.black)),
              ]),
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
                    label: Text(_paused ? 'Resume' : 'Pause', style: AppTextStyle.mediumText(size: 14, color: Colors.black)),
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
                onPressed: done ? () => Navigator.pop(context) : _startOrNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(done ? 'Finish' : (_inRest ? 'Resting...' : (_currentSet == 0 ? 'Start' : 'Next Set'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


