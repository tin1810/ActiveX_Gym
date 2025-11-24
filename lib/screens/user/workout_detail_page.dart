import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/mock_api.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import 'exercise_detail_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({
    super.key,
    this.title = 'Free Hand Exercises',
    this.level = 'Intermediate',
    this.durationMinutes = 120,
    this.kcal = 450,
    this.numExercises = 6,
    this.headerImageUrl =
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1200&auto=format&fit=crop',
    this.workoutId,
  });

  final String title;
  final String level;
  final int durationMinutes;
  final int kcal;
  final int numExercises;
  final String headerImageUrl;
  final String? workoutId;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  int _selectedTab = 0; // 0: Overview, 1: Exercises, 2: Details
  final MockApiService _api = const MockApiService();
  Future<WorkoutModel?>? _futureWorkout;

  @override
  void initState() {
    super.initState();
    if (widget.workoutId != null) {
      _futureWorkout = _api.fetchWorkoutById(widget.workoutId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderMedia(context),
              const SizedBox(height: 20),
              _buildTitleRow(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildActionButtons(context),
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 16),
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMedia(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: widget.headerImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: const Color(0xFF222222)),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF222222),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white70,
                  size: 72,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${widget.numExercises} Exercises',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.level,
            style: const TextStyle(
              color: Color(0xFF9AA300),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(
          icon: Icons.access_time,
          label: 'min',
          value: widget.durationMinutes.toString(),
        ),
        _StatItem(
          icon: Icons.local_fire_department,
          label: 'kcal',
          value: widget.kcal.toString(),
          color: const Color(0xFFFFAB40),
        ),
        _StatItem(
          icon: Icons.list_alt,
          label: 'Exercises',
          value: widget.numExercises.toString(),
          color: const Color(0xFF4A90E2),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('View Exercises'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Workout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Overview',
            selected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 6),
          _SegmentButton(
            label: 'Exercises',
            selected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          const SizedBox(width: 6),
          _SegmentButton(
            label: 'Details',
            selected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        if (_futureWorkout != null) {
          return FutureBuilder<WorkoutModel?>(
            future: _futureWorkout,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final workout = snapshot.data;
              if (workout == null) {
                return const Center(child: Text('No exercises'));
              }
              return _ExercisesSection(exercises: workout.exercises);
            },
          );
        }
        return _ExercisesSection(
          exercises: [
            ExerciseModel(
              id: 'pushups',
              title: 'Push-ups',
              difficulty: 'Beginner',
              sets: 3,
              reps: '10-15',
              restSeconds: 60,
              targetMuscles: const ['Chest', 'Shoulders', 'Triceps'],
              imageUrl: _exerciseImageFor('Push-ups'),
            ),
            ExerciseModel(
              id: 'squats',
              title: 'Squats',
              difficulty: 'Beginner',
              sets: 3,
              reps: '12-20',
              restSeconds: 45,
              targetMuscles: const ['Quadriceps', 'Glutes', 'Hamstrings'],
              imageUrl: _exerciseImageFor('Squats'),
            ),
          ],
        );
      case 2:
        return _OverviewSection(
          durationMinutes: widget.durationMinutes,
          kcal: widget.kcal,
          level: widget.level,
          numExercises: widget.numExercises,
        );
      case 0:
      default:
        return _DetailsSection(
          level: widget.level,
          numExercises: widget.numExercises,
        );
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? const Color(0xFFFFC107);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: effectiveColor, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip(
    this.text, {
    this.bg = const Color(0xFFF2F2F7),
    this.textColor = const Color(0xFF3A3A3C),
  });

  final String text;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.durationMinutes,
    required this.kcal,
    required this.level,
    required this.numExercises,
  });

  final int durationMinutes;
  final int kcal;
  final String level;
  final int numExercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workout Summary',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryRow(
                      title: 'Total Time:',
                      value: '${durationMinutes}min',
                    ),
                  ),
                  Expanded(
                    child: _SummaryRow(
                      title: 'Estimated Calories:',
                      value: '${kcal}kcal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: _SummaryRow(
                      title: 'Difficulty:',
                      value: 'Intermediate',
                    ),
                  ),
                  Expanded(
                    child: _SummaryRow(
                      title: 'Exercise Count:',
                      value: '$numExercises exercises',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Tips for Success',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              _TipRow('Warm up for 5-10 minutes before starting'),
              _TipRow('Focus on proper form rather than speed'),
              _TipRow('Stay hydrated throughout the workout'),
              _TipRow('Cool down and stretch after completing'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}

class _ExercisesSection extends StatelessWidget {
  const _ExercisesSection({required this.exercises});
  final List<ExerciseModel> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < exercises.length; i++) ...[
          _ExerciseCard(
            title: exercises[i].title,
            difficulty: exercises[i].difficulty,
            sets: '${exercises[i].sets} sets',
            reps: '${exercises[i].reps} reps',
            rest: '${exercises[i].restSeconds}s',
            muscles: [
              ...exercises[i].targetMuscles,
              if (exercises[i].targetMuscles.length > 3) '+1',
            ],
          ),
          if (i != exercises.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.title,
    required this.difficulty,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.muscles,
  });

  final String title;
  final String difficulty;
  final String sets;
  final String reps;
  final String rest;
  final List<String> muscles;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final setsNum = int.tryParse(sets.split(' ').first) ?? 3;
        final repsStr = reps.replaceAll(' reps', '').replaceAll('rep', '');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseDetailPage(
              exerciseName: title,
              level: difficulty,
              sets: setsNum,
              reps: repsStr,
              restTime: rest,
              targetMuscles: muscles.where((m) => !m.startsWith('+')).toList(),
              equipment: 'None',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CachedNetworkImage(
                      imageUrl: _exerciseImageFor(title),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: const Color(0xFF222222)),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF222222),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, color: Colors.white60),
                      ),
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
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F8EC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              difficulty,
                              style: const TextStyle(
                                color: Color(0xFF34C759),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(sets, style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(width: 8),
                          Text(reps, style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(rest, style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles
                  .map(
                    (m) => _PillChip(
                      m,
                      bg: const Color(0xFFEFFAF2),
                      textColor: const Color(0xFF2C8B53),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap for detailed instructions, tips, and variations',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

String _exerciseImageFor(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('push')) {
    return 'https://images.unsplash.com/photo-1517963628607-235ccdd5476b?q=80&w=600&auto=format&fit=crop';
  }
  if (lower.contains('squat')) {
    return 'https://images.unsplash.com/photo-1546483875-ad9014c88eba?q=80&w=600&auto=format&fit=crop';
  }
  return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=600&auto=format&fit=crop';
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.level, required this.numExercises});
  final String level;
  final int numExercises;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Description'),
        const SizedBox(height: 8),
        const Text(
          'This comprehensive free-hand workout is designed to improve your core strength, flexibility, and overall endurance using only your body weight.',
          style: TextStyle(color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Target Muscles'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _PillChip('Core'),
            _PillChip('Upper Body'),
            _PillChip('Lower Body'),
            _PillChip('Cardiovascular'),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Equipment Needed'),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.no_accounts, color: Color(0xFF8E44FF), size: 18),
            SizedBox(width: 8),
            _PillChip(
              'None - Bodyweight Only',
              bg: Color(0xFFF2E9FF),
              textColor: Color(0xFF6E49B5),
            ),
          ],
        ),
      ],
    );
  }
}
