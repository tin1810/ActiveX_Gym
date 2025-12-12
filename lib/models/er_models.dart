class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.goal,
    this.password,
  });
  final String id;
  final String name;
  final String email;
  final String role; // user | trainer | admin
  final String? goal;
  final String? password; // only used for trainer/admin in mock
  factory UserModel.fromJson(Map<String, dynamic> j) {
    // Safely extract string values with null handling
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }
    
    return UserModel(
      id: safeString(j['id']),
      name: safeString(j['name']),
      email: safeString(j['email']),
      role: safeString(j['role'], 'user'),
      goal: j['goal'] != null ? safeString(j['goal']) : null,
      password: j['password'] != null ? safeString(j['password']) : null,
    );
  }
}

class WorkoutPlanModel {
  WorkoutPlanModel({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.workouts,
    this.durationMinutes,
    this.kcal,
    this.exercisesCount,
    this.tags,
    this.equipment,
    this.imageUrl,
    this.userId,
  });
  final String id;
  final String trainerId;
  final String name;
  final String description;
  final String difficulty;
  final List<PlanWorkoutModel> workouts;
  final int? durationMinutes;
  final int? kcal;
  final int? exercisesCount;
  final List<String>? tags;
  final String? equipment;
  final String? imageUrl;
  final String? userId;
  factory WorkoutPlanModel.fromJson(Map<String, dynamic> j) {
    // Safely extract string values with null handling
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }
    
    int? safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }
    
    List<String>? safeStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => safeString(e)).toList();
      }
      return null;
    }
    
    List<PlanWorkoutModel> safeWorkoutsList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value
            .map((e) => PlanWorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    
    // Handle both 'userId' and 'selectedUserId' from API
    final userIdValue = j['userId'] ?? j['selectedUserId'];
    return WorkoutPlanModel(
      id: safeString(j['id']),
      trainerId: safeString(j['trainerId']),
      name: safeString(j['name']),
      description: safeString(j['description']),
      difficulty: safeString(j['difficulty'], 'beginner'),
      workouts: safeWorkoutsList(j['workouts']),
      durationMinutes: safeInt(j['durationMinutes']),
      kcal: safeInt(j['kcal']),
      exercisesCount: safeInt(j['exercisesCount']),
      tags: safeStringList(j['tags']),
      equipment: j['equipment'] != null ? safeString(j['equipment']) : null,
      imageUrl: j['imageUrl'] != null ? safeString(j['imageUrl']) : null,
      userId: userIdValue != null ? safeString(userIdValue) : null,
    );
  }
}

class PlanWorkoutModel {
  PlanWorkoutModel({
    required this.workoutId,
    required this.dayOfWeek,
    required this.sets,
    required this.reps,
  });
  final String workoutId;
  final int dayOfWeek;
  final int sets;
  final String reps;
  factory PlanWorkoutModel.fromJson(Map<String, dynamic> j) {
    // Safely extract values with null handling
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
    
    // Handle both 'workoutId' and 'exercise_id' (API returns exercise_id)
    final workoutId = j['workoutId'] ?? j['exercise_id'] ?? j['exerciseId'];
    return PlanWorkoutModel(
      workoutId: safeString(workoutId),
      dayOfWeek: safeInt(j['dayOfWeek'], 1),
      sets: safeInt(j['sets'], 3),
      reps: safeString(j['reps']),
    );
  }
}

class CommunityChallengeModel {
  CommunityChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.participants,
    this.createdBy,
  });
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final List<ChallengeUserModel> participants;
  final String? createdBy; // trainer id
  factory CommunityChallengeModel.fromJson(Map<String, dynamic> j) => CommunityChallengeModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        startDate: j['startDate'] as String,
        endDate: j['endDate'] as String,
        participants: (j['participants'] as List<dynamic>? ?? [])
            .map((e) => ChallengeUserModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdBy: j['createdBy'] as String?,
      );
}

class ChallengeUserModel {
  ChallengeUserModel({required this.userId, required this.progress});
  final String userId;
  final int progress; // percent
  factory ChallengeUserModel.fromJson(Map<String, dynamic> j) => ChallengeUserModel(
        userId: j['userId'] as String,
        progress: (j['progress'] as num).toInt(),
      );
}

class NutritionPlanModel {
  NutritionPlanModel({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.description,
    required this.dailyCaloriesTarget,
    required this.meals,
  });
  final String id;
  final String trainerId;
  final String name;
  final String description;
  final int dailyCaloriesTarget;
  final List<MealModel> meals;
  factory NutritionPlanModel.fromJson(Map<String, dynamic> j) => NutritionPlanModel(
        id: j['id'] as String,
        trainerId: j['trainerId'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        dailyCaloriesTarget: (j['dailyCaloriesTarget'] as num).toInt(),
        meals: (j['meals'] as List<dynamic>)
            .map((e) => MealModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MealModel {
  MealModel({required this.name, required this.timeOfDay});
  final String name; // Breakfast
  final String timeOfDay; // 08:00
  factory MealModel.fromJson(Map<String, dynamic> j) => MealModel(
        name: j['name'] as String,
        timeOfDay: j['timeOfDay'] as String,
      );
}

class ProgressLogModel {
  ProgressLogModel({
    this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
    required this.caloriesBurned,
    this.notes,
    this.bodyFatPercentage,
    this.muscleMass,
  });
  final String? id;
  final String userId;
  final String date;
  final double weightKg;
  final int caloriesBurned;
  final String? notes;
  final double? bodyFatPercentage;
  final double? muscleMass;
  factory ProgressLogModel.fromJson(Map<String, dynamic> j) => ProgressLogModel(
        id: j['id'] as String?,
        userId: j['userId'] as String,
        date: j['date'] as String,
        weightKg: (j['weightKg'] as num).toDouble(),
        caloriesBurned: (j['caloriesBurned'] as num).toInt(),
        notes: j['notes'] as String?,
        bodyFatPercentage: j['bodyFatPercentage'] != null ? (j['bodyFatPercentage'] as num).toDouble() : null,
        muscleMass: j['muscleMass'] != null ? (j['muscleMass'] as num).toDouble() : null,
      );
}

class UserPlanAssignmentModel {
  UserPlanAssignmentModel({
    required this.userId,
    required this.planId,
    required this.planType, // workout or nutrition
    required this.assignedBy,
    required this.startDate,
  });
  final String userId;
  final String planId;
  final String planType;
  final String assignedBy;
  final String startDate;
  factory UserPlanAssignmentModel.fromJson(Map<String, dynamic> j) => UserPlanAssignmentModel(
        userId: j['userId'] as String,
        planId: j['planId'] as String,
        planType: j['planType'] as String,
        assignedBy: j['assignedBy'] as String,
        startDate: j['startDate'] as String,
      );
}

class TrainerProfileModel {
  TrainerProfileModel({
    required this.name,
    required this.title,
    required this.bio,
    required this.email,
    required this.phone,
    required this.location,
    required this.clients,
    required this.plans,
    required this.rating,
    this.avatarUrl,
  });

  final String name;
  final String title;
  final String bio;
  final String email;
  final String phone;
  final String location;
  final int clients;
  final int plans;
  final double rating;
  final String? avatarUrl;

  factory TrainerProfileModel.fromJson(Map<String, dynamic> j) => TrainerProfileModel(
        name: j['name'] as String,
        title: j['title'] as String,
        bio: j['bio'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String,
        location: j['location'] as String,
        clients: (j['clients'] as num).toInt(),
        plans: (j['plans'] as num).toInt(),
        rating: (j['rating'] as num).toDouble(),
        avatarUrl: j['avatarUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'bio': bio,
        'email': email,
        'phone': phone,
        'location': location,
        'clients': clients,
        'plans': plans,
        'rating': rating,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
}


