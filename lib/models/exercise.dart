class ExerciseModel {
  ExerciseModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.targetMuscles,
    required this.videoUrl,
    this.instructions,
  });

  final String id;
  final String title;
  final String difficulty; // Beginner | Intermediate | Advanced
  final int sets;
  final String reps; // e.g. "10-15"
  final int restSeconds; // 60
  final List<String> targetMuscles; // ["Chest", "Triceps"]
  final String videoUrl;
  final List<String>? instructions;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] as String,
        title: json['title'] as String,
        difficulty: json['difficulty'] as String,
        sets: (json['sets'] as num).toInt(),
        reps: json['reps'] as String,
        restSeconds: (json['restSeconds'] as num).toInt(),
        targetMuscles: (json['targetMuscles'] as List<dynamic>).cast<String>(),
        videoUrl: json['videoUrl'] as String? ?? json['imageUrl'] as String? ?? '', // Support both for backward compatibility
        instructions: (json['instructions'] as List<dynamic>?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'difficulty': difficulty,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
        'targetMuscles': targetMuscles,
        'videoUrl': videoUrl,
        if (instructions != null) 'instructions': instructions,
      };
}


