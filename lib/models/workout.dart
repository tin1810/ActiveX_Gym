import 'exercise.dart';

class WorkoutModel {
  WorkoutModel({
    required this.id,
    required this.title,
    required this.level,
    required this.durationMinutes,
    required this.kcal,
    required this.exercisesCount,
    required this.tags,
    required this.equipment,
    required this.imageUrl,
    required this.exercises,
  });

  final String id;
  final String title;
  final String level; // Beginner | Intermediate | Advanced
  final int durationMinutes;
  final int kcal;
  final int exercisesCount;
  final List<String> tags;
  final String equipment;
  final String imageUrl;
  final List<ExerciseModel> exercises;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) => WorkoutModel(
        id: json['id'] as String,
        title: json['title'] as String,
        level: json['level'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        kcal: (json['kcal'] as num).toInt(),
        exercisesCount: (json['exercisesCount'] as num).toInt(),
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        equipment: json['equipment'] as String,
        imageUrl: json['imageUrl'] as String,
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'level': level,
        'durationMinutes': durationMinutes,
        'kcal': kcal,
        'exercisesCount': exercisesCount,
        'tags': tags,
        'equipment': equipment,
        'imageUrl': imageUrl,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}


