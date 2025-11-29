import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/er_models.dart';
import 'auth.dart';
import 'database_helper.dart';

class ApiServiceFor {
  const ApiServiceFor();
  
  static bool _migrated = false;

  Future<List<WorkoutModel>> fetchWorkouts() async {
    final jsonString = await rootBundle.loadString('assets/mock/workouts.json');
    final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
    await Future.delayed(const Duration(milliseconds: 300));
    return data
        .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutModel?> fetchWorkoutById(String id) async {
    final list = await fetchWorkouts();
    try {
      return list.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // ====== Database Migration ======
  Future<void> _ensureMigrated() async {
    if (_migrated) return;
    
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('db_migrated') ?? false;
    
    if (!migrated) {
      // Load initial data from JSON
      final jsonString = await rootBundle.loadString('assets/mock/er_data.json');
      final erData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Migrate to database
      await DatabaseHelper.instance.migrateFromJson(erData);
      
      // Mark as migrated
      await prefs.setBool('db_migrated', true);
    }
    
    _migrated = true;
  }

  Future<List<UserModel>> fetchUsers() async {
    await _ensureMigrated();
    return await DatabaseHelper.instance.getAllUsers();
  }

  Future<void> deleteUser(String userId) async {
    await _ensureMigrated();
    await DatabaseHelper.instance.deleteUser(userId);
  }

  Future<void> addUser(UserModel user) async {
    await _ensureMigrated();
    // Check if user exists by email
    final existing = await DatabaseHelper.instance.getUserByEmail(user.email.trim());
    if (existing != null) {
      return; // User already exists
    }
    await DatabaseHelper.instance.insertUser(user);
  }

  Future<void> addTrainer({required String name, required String email, required String password}) async {
    await _ensureMigrated();
    // Check for duplicates case-insensitively
    final existing = await DatabaseHelper.instance.getUserByEmail(email.trim());
    if (existing != null) {
      throw Exception('Email already exists. Please use a different email address.');
    }
    
    final trainer = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email.trim(),
      password: password,
      role: 'trainer',
    );
    await DatabaseHelper.instance.insertUser(trainer);
  }

  Future<List<WorkoutPlanModel>> fetchWorkoutPlans() async {
    await _ensureMigrated();
    return await DatabaseHelper.instance.getAllWorkoutPlans();
  }

  Future<List<NutritionPlanModel>> fetchNutritionPlans() async {
    await _ensureMigrated();
    return await DatabaseHelper.instance.getAllNutritionPlans();
  }

  Future<List<CommunityChallengeModel>> fetchChallenges() async {
    await _ensureMigrated();
    return await DatabaseHelper.instance.getAllChallenges();
  }

  Future<List<ProgressLogModel>> fetchProgressLogs(String userId) async {
    await _ensureMigrated();
    return await DatabaseHelper.instance.getProgressLogs(userId);
  }

  Future<void> addProgressLog(ProgressLogModel log) async {
    await _ensureMigrated();
    await DatabaseHelper.instance.insertProgressLog(log);
  }

  Future<void> addChallenge(CommunityChallengeModel challenge) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can create challenges');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.insertChallenge(challenge);
  }

  Future<void> updateChallenge({required String id, String? title, String? description, String? startDate, String? endDate}) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update challenges');
    }
    await _ensureMigrated();
    // For now, challenges are read-only after creation. Can be enhanced later.
    // This method is kept for API compatibility but doesn't modify database yet.
  }

  Future<void> deleteChallenge(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete challenges');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.deleteChallenge(id);
  }

  // ===== Trainer Profile =====
  Future<TrainerProfileModel> fetchTrainerProfile() async {
    // Get logged-in trainer's name from auth service
    final loggedInTrainer = MockAuthService.instance.currentUser;
    final trainerName = loggedInTrainer.role.toLowerCase() == 'trainer' 
        ? loggedInTrainer.name 
        : 'Coach Jason Miller';
    
    final mp = {
      'name': trainerName,
      'title': 'Certified Personal Trainer',
      'bio': 'Passionate fitness coach specializing in strength training and nutrition. Helping clients transform their lives for 8+ years.',
      'email': loggedInTrainer.role.toLowerCase() == 'trainer' ? loggedInTrainer.email : 'jason.miller@activextra.com',
      'phone': '+1 (555) 123-4567',
      'location': 'Los Angeles, CA',
      'clients': 24,
      'plans': 33,
      'rating': 4.9,
      'avatarUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300&h=300&fit=crop',
    };
    
    return TrainerProfileModel.fromJson(mp);
  }

  Future<void> updateTrainerProfile(TrainerProfileModel profile) async {
    // Trainer profile updates can be stored in SharedPreferences or database if needed
    // For now, it's a simple in-memory operation
  }

  // Mutations - only for trainers (demo)
  Future<void> addWorkoutPlan(WorkoutPlanModel plan) async {
    if (!MockAuthService.instance.isTrainer) {
      throw Exception('Only trainers can create workout plans');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.insertWorkoutPlan(plan);
  }

  Future<void> addNutritionPlan(NutritionPlanModel plan) async {
    if (!MockAuthService.instance.isTrainer) {
      throw Exception('Only trainers can create nutrition plans');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.insertNutritionPlan(plan);
  }

  Future<void> deleteWorkoutPlan(String id) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can delete');
    await _ensureMigrated();
    await DatabaseHelper.instance.deleteWorkoutPlan(id);
  }

  Future<void> deleteNutritionPlan(String id) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can delete');
    await _ensureMigrated();
    await DatabaseHelper.instance.deleteNutritionPlan(id);
  }

  Future<void> updateWorkoutPlan({required String id, String? name, String? description, String? difficulty}) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can update');
    await _ensureMigrated();
    final plan = await DatabaseHelper.instance.getWorkoutPlanById(id);
    if (plan == null) throw Exception('Workout plan not found');
    
    final updatedPlan = WorkoutPlanModel(
      id: plan.id,
      trainerId: plan.trainerId,
      name: name ?? plan.name,
      description: description ?? plan.description,
      difficulty: difficulty ?? plan.difficulty,
      workouts: plan.workouts,
      durationMinutes: plan.durationMinutes,
      kcal: plan.kcal,
      exercisesCount: plan.exercisesCount,
      tags: plan.tags,
      equipment: plan.equipment,
      imageUrl: plan.imageUrl,
    );
    await DatabaseHelper.instance.updateWorkoutPlan(updatedPlan);
  }

  Future<void> updateWorkoutPlanFull(WorkoutPlanModel plan) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update workout plans');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.updateWorkoutPlan(plan);
  }

  Future<void> updateNutritionPlan({required String id, String? name, String? description, int? dailyCaloriesTarget}) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can update');
    await _ensureMigrated();
    // For now, nutrition plan updates are not fully implemented in database
    // This method is kept for API compatibility
  }

  // ===== Exercise Management (Trainer only) =====
  Future<List<ExerciseModel>> fetchExercises() async {
    await _ensureMigrated();
    return await DatabaseHelper.instance.getAllExercises();
  }

  Future<void> addExercise(ExerciseModel exercise) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can create exercises');
    }
    await _ensureMigrated();
    // Check for duplicates by id
    final existing = await DatabaseHelper.instance.getExerciseById(exercise.id);
    if (existing != null) {
      throw Exception('Exercise with this ID already exists');
    }
    await DatabaseHelper.instance.insertExercise(exercise);
  }


  Future<void> updateExercise(ExerciseModel exercise) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update exercises');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.updateExercise(exercise);
  }


  Future<void> deleteExercise(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete exercises');
    }
    await _ensureMigrated();
    await DatabaseHelper.instance.deleteExercise(id);
  }

}

// ============================================================================
// Abstract API Binding Interface
// This abstract class defines the API contract for Laravel backend integration
// Based on: ActiveX Gym API (Laravel) Documentation
// Base URL: http://localhost:8000/api/v1 (Development)
//          https://your-domain.com/api/v1 (Production)
// Authentication: Bearer JWT Token
// ============================================================================

/// Response envelope structure used by all API endpoints
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<ApiError>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });
}

/// Pagination metadata structure
class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;

  PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });
}

/// Paginated response structure
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });
}

/// Validation error structure
class ApiError {
  final String field;
  final String message;

  ApiError({required this.field, required this.message});
}

/// Authentication response data
class AuthResponseData {
  final UserModel user;
  final String token;

  AuthResponseData({required this.user, required this.token});
}

/// Workout plan create/update request body
class WorkoutPlanRequest {
  final String name;
  final String description;
  final String difficulty; // beginner | intermediate | advanced
  final int? durationMinutes;
  final int? kcal;
  final int? exercisesCount;
  final List<String>? tags;
  final String? equipment;
  final String? imageUrl; // Base64 data URL or URL string
  final List<PlanWorkoutSchedule>? workouts;

  WorkoutPlanRequest({
    required this.name,
    required this.description,
    required this.difficulty,
    this.durationMinutes,
    this.kcal,
    this.exercisesCount,
    this.tags,
    this.equipment,
    this.imageUrl,
    this.workouts,
  });
}

/// Workout schedule item for workout plan
class PlanWorkoutSchedule {
  final String workoutId;
  final int dayOfWeek; // 1 (Mon) to 7 (Sun)
  final int? sets;
  final String? reps;

  PlanWorkoutSchedule({
    required this.workoutId,
    required this.dayOfWeek,
    this.sets,
    this.reps,
  });
}

/// Nutrition plan meal request
class MealRequest {
  final String name;
  final String timeOfDay; // HH:mm format

  MealRequest({required this.name, required this.timeOfDay});
}

/// Nutrition plan create/update request
class NutritionPlanRequest {
  final String name;
  final String description;
  final int dailyCaloriesTarget;
  final List<MealRequest> meals;

  NutritionPlanRequest({
    required this.name,
    required this.description,
    required this.dailyCaloriesTarget,
    required this.meals,
  });
}

/// Challenge create/update request
class ChallengeRequest {
  final String title;
  final String description;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final List<Map<String, dynamic>>? participants;

  ChallengeRequest({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.participants,
  });
}

/// Progress log request
class ProgressLogRequest {
  final String userId;
  final String date; // YYYY-MM-DD
  final double? weightKg;
  final int? caloriesBurned;
  final double? bodyFatPercentage;
  final double? muscleMass;
  final String? notes;

  ProgressLogRequest({
    required this.userId,
    required this.date,
    this.weightKg,
    this.caloriesBurned,
    this.bodyFatPercentage,
    this.muscleMass,
    this.notes,
  });
}

/// Plan assignment request
class PlanAssignmentRequest {
  final String userId;
  final String planId;
  final String planType; // workout | nutrition
  final String assignedBy; // trainerId
  final String startDate; // YYYY-MM-DD

  PlanAssignmentRequest({
    required this.userId,
    required this.planId,
    required this.planType,
    required this.assignedBy,
    required this.startDate,
  });
}

/// Exercise create/update request
class ExerciseRequest {
  final String title;
  final String difficulty; // Beginner | Intermediate | Advanced
  final int sets;
  final String reps;
  final int restSeconds;
  final List<String> targetMuscles;
  final String? videoUrl;
  final List<String>? instructions;

  ExerciseRequest({
    required this.title,
    required this.difficulty,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.targetMuscles,
    this.videoUrl,
    this.instructions,
  });
}

/// User create/update request
class UserRequest {
  final String? name;
  final String? email;
  final String? password;
  final String? goal;

  UserRequest({
    this.name,
    this.email,
    this.password,
    this.goal,
  });
}

/// Trainer create request
class TrainerCreateRequest {
  final String name;
  final String email;
  final String password;

  TrainerCreateRequest({
    required this.name,
    required this.email,
    required this.password,
  });
}

/// Image upload response
class ImageUploadResponse {
  final String url;

  ImageUploadResponse({required this.url});
}

/// Favorite exercises response
class FavoriteExercisesResponse {
  final List<String> exerciseIds;

  FavoriteExercisesResponse({required this.exerciseIds});
}

/// Favorite toggle response
class FavoriteToggleResponse {
  final bool isFavorite;

  FavoriteToggleResponse({required this.isFavorite});
}

/// Abstract API Service Interface
/// This defines the contract for all API endpoints based on Laravel backend
abstract class ActiveXGymApiService {
  // ============================================================================
  // 1. Authentication Endpoints
  // ============================================================================

  /// POST /auth/register
  /// Public endpoint
  Future<ApiResponse<AuthResponseData>> register({
    required String name,
    required String email,
    required String password,
  });

  /// POST /auth/login
  /// Public endpoint
  Future<ApiResponse<AuthResponseData>> login({
    required String email,
    required String password,
  });

  /// POST /auth/logout
  /// Auth required
  Future<ApiResponse<void>> logout();

  // ============================================================================
  // 2. Users Endpoints
  // ============================================================================

  /// GET /users
  /// Auth required, role: admin
  /// Query params: role (user|trainer|admin), page, limit
  Future<ApiResponse<PaginatedResponse<UserModel>>> getUsers({
    String? role,
    int? page,
    int? limit,
  });

  /// GET /users/{id}
  /// Auth required
  Future<ApiResponse<UserModel>> getUserById(String id);

  /// GET /users/email/{email}
  /// Auth required
  Future<ApiResponse<UserModel>> getUserByEmail(String email);

  /// POST /users/trainers
  /// Auth required, role: admin
  Future<ApiResponse<UserModel>> createTrainer(TrainerCreateRequest request);

  /// PUT /users/{id}
  /// Auth required; user can update self, or admin can update any
  Future<ApiResponse<UserModel>> updateUser(String id, UserRequest request);

  /// DELETE /users/{id}
  /// Auth required, role: admin
  Future<ApiResponse<void>> deleteUser(String id);

  // ============================================================================
  // 3. Exercises Endpoints
  // ============================================================================

  /// GET /exercises
  /// Auth required
  /// Query params: page, limit
  Future<ApiResponse<PaginatedResponse<ExerciseModel>>> getExercises({
    int? page,
    int? limit,
  });

  /// GET /exercises/{id}
  /// Auth required
  Future<ApiResponse<ExerciseModel>> getExerciseById(String id);

  /// POST /exercises
  /// Auth required, role: trainer|admin
  Future<ApiResponse<ExerciseModel>> createExercise(ExerciseRequest request);

  /// PUT /exercises/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<ExerciseModel>> updateExercise(
    String id,
    ExerciseRequest request,
  );

  /// DELETE /exercises/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<void>> deleteExercise(String id);

  // ============================================================================
  // 4. Workouts Endpoints
  // ============================================================================

  /// GET /workouts
  /// Auth required
  /// Query params: level (Beginner|Intermediate|Advanced), tag, page, limit
  Future<ApiResponse<PaginatedResponse<WorkoutModel>>> getWorkouts({
    String? level,
    String? tag,
    int? page,
    int? limit,
  });

  /// GET /workouts/{id}
  /// Auth required
  Future<ApiResponse<WorkoutModel>> getWorkoutById(String id);

  // ============================================================================
  // 5. Workout Plans Endpoints
  // ============================================================================

  /// GET /workout-plans
  /// Auth required
  /// Query params: trainer_id, user_id, page, limit
  Future<ApiResponse<PaginatedResponse<WorkoutPlanModel>>> getWorkoutPlans({
    String? trainerId,
    String? userId,
    int? page,
    int? limit,
  });

  /// GET /workout-plans/{id}
  /// Auth required
  Future<ApiResponse<WorkoutPlanModel>> getWorkoutPlanById(String id);

  /// POST /workout-plans
  /// Auth required, role: trainer|admin
  Future<ApiResponse<WorkoutPlanModel>> createWorkoutPlan(
    WorkoutPlanRequest request,
  );

  /// PUT /workout-plans/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<WorkoutPlanModel>> updateWorkoutPlan(
    String id,
    WorkoutPlanRequest request,
  );

  /// PATCH /workout-plans/{id}
  /// Auth required, role: trainer|admin
  /// Partial update (e.g., name, description, difficulty)
  Future<ApiResponse<WorkoutPlanModel>> patchWorkoutPlan(
    String id,
    Map<String, dynamic> partialData,
  );

  /// DELETE /workout-plans/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<void>> deleteWorkoutPlan(String id);

  // ============================================================================
  // 6. Nutrition Plans Endpoints
  // ============================================================================

  /// GET /nutrition-plans
  /// Auth required
  /// Query params: trainer_id, user_id, page, limit
  Future<ApiResponse<PaginatedResponse<NutritionPlanModel>>> getNutritionPlans({
    String? trainerId,
    String? userId,
    int? page,
    int? limit,
  });

  /// GET /nutrition-plans/{id}
  /// Auth required
  Future<ApiResponse<NutritionPlanModel>> getNutritionPlanById(String id);

  /// POST /nutrition-plans
  /// Auth required, role: trainer|admin
  Future<ApiResponse<NutritionPlanModel>> createNutritionPlan(
    NutritionPlanRequest request,
  );

  /// PATCH /nutrition-plans/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<NutritionPlanModel>> patchNutritionPlan(
    String id,
    Map<String, dynamic> partialData,
  );

  /// DELETE /nutrition-plans/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<void>> deleteNutritionPlan(String id);

  // ============================================================================
  // 7. Challenges Endpoints
  // ============================================================================

  /// GET /challenges
  /// Auth required
  /// Query params: page, limit
  Future<ApiResponse<PaginatedResponse<CommunityChallengeModel>>> getChallenges({
    int? page,
    int? limit,
  });

  /// GET /challenges/{id}
  /// Auth required
  Future<ApiResponse<CommunityChallengeModel>> getChallengeById(String id);

  /// POST /challenges
  /// Auth required, role: trainer|admin
  Future<ApiResponse<CommunityChallengeModel>> createChallenge(
    ChallengeRequest request,
  );

  /// PATCH /challenges/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<CommunityChallengeModel>> patchChallenge(
    String id,
    Map<String, dynamic> partialData,
  );

  /// DELETE /challenges/{id}
  /// Auth required, role: trainer|admin
  Future<ApiResponse<void>> deleteChallenge(String id);

  // ============================================================================
  // 8. Progress Logs Endpoints
  // ============================================================================

  /// GET /progress-logs
  /// Auth required
  /// Query params: user_id (required)
  Future<ApiResponse<List<ProgressLogModel>>> getProgressLogs({
    required String userId,
  });

  /// POST /progress-logs
  /// Auth required
  /// Upsert by (userId, date)
  Future<ApiResponse<ProgressLogModel>> createOrUpdateProgressLog(
    ProgressLogRequest request,
  );

  // ============================================================================
  // 9. Favorites Endpoints (Exercises)
  // ============================================================================

  /// GET /users/{userId}/favorites/exercises
  /// Auth required
  Future<ApiResponse<FavoriteExercisesResponse>> getFavoriteExercises(
    String userId,
  );

  /// POST /users/{userId}/favorites/exercises/{exerciseId}
  /// Auth required
  /// Toggle favorite on/off
  Future<ApiResponse<FavoriteToggleResponse>> toggleFavoriteExercise(
    String userId,
    String exerciseId,
  );

  // ============================================================================
  // 10. Plan Assignments Endpoints
  // ============================================================================

  /// POST /plan-assignments
  /// Auth required, role: trainer|admin
  Future<ApiResponse<UserPlanAssignmentModel>> createPlanAssignment(
    PlanAssignmentRequest request,
  );

  /// GET /plan-assignments
  /// Auth required
  /// Query params: user_id (required), plan_type (workout|nutrition, optional)
  Future<ApiResponse<List<UserPlanAssignmentModel>>> getPlanAssignments({
    required String userId,
    String? planType,
  });

  // ============================================================================
  // 11. Uploads Endpoints
  // ============================================================================

  /// POST /upload/image
  /// Auth required
  /// Multipart form-data: field 'image' (max 5MB)
  Future<ApiResponse<ImageUploadResponse>> uploadImage(
    List<int> imageBytes,
    String fileName,
  );
}

