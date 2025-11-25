import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/er_models.dart';
import 'auth.dart';
import 'database_helper.dart';

class MockApiService {
  const MockApiService();
  
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
    if (existing != null) return;
    
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


