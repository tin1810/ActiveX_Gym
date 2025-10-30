class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.goal,
  });
  final String id;
  final String name;
  final String email;
  final String role; // user | trainer | admin
  final String? goal;
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        goal: j['goal'] as String?,
      );
}

class WorkoutPlanModel {
  WorkoutPlanModel({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.workouts,
  });
  final String id;
  final String trainerId;
  final String name;
  final String description;
  final String difficulty;
  final List<PlanWorkoutModel> workouts;
  factory WorkoutPlanModel.fromJson(Map<String, dynamic> j) => WorkoutPlanModel(
        id: j['id'] as String,
        trainerId: j['trainerId'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        difficulty: j['difficulty'] as String,
        workouts: (j['workouts'] as List<dynamic>)
            .map((e) => PlanWorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
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
  factory PlanWorkoutModel.fromJson(Map<String, dynamic> j) => PlanWorkoutModel(
        workoutId: j['workoutId'] as String,
        dayOfWeek: (j['dayOfWeek'] as num).toInt(),
        sets: (j['sets'] as num).toInt(),
        reps: j['reps'] as String,
      );
}

class CommunityChallengeModel {
  CommunityChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.participants,
  });
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final List<ChallengeUserModel> participants;
  factory CommunityChallengeModel.fromJson(Map<String, dynamic> j) => CommunityChallengeModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        startDate: j['startDate'] as String,
        endDate: j['endDate'] as String,
        participants: (j['participants'] as List<dynamic>)
            .map((e) => ChallengeUserModel.fromJson(e as Map<String, dynamic>))
            .toList(),
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
    required this.userId,
    required this.date,
    required this.weightKg,
    required this.caloriesBurned,
    this.notes,
  });
  final String userId;
  final String date;
  final double weightKg;
  final int caloriesBurned;
  final String? notes;
  factory ProgressLogModel.fromJson(Map<String, dynamic> j) => ProgressLogModel(
        userId: j['userId'] as String,
        date: j['date'] as String,
        weightKg: (j['weightKg'] as num).toDouble(),
        caloriesBurned: (j['caloriesBurned'] as num).toInt(),
        notes: j['notes'] as String?,
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


