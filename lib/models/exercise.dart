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

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    // Safely extract string values with null handling
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }
    
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? defaultValue;
    }
    
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => safeString(e)).toList();
      }
      return [];
    }
    
    return ExerciseModel(
      id: safeString(json['id']),
      title: safeString(json['title']),
      difficulty: safeString(json['difficulty'], 'Beginner'),
      sets: safeInt(json['sets'], 3),
      reps: safeString(json['reps']),
      restSeconds: safeInt(json['restSeconds'], 60),
      targetMuscles: safeStringList(json['targetMuscles']),
      videoUrl: safeString(json['videoUrl'] ?? json['imageUrl']), // Support both for backward compatibility
      instructions: json['instructions'] != null ? safeStringList(json['instructions']) : null,
    );
  }

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


