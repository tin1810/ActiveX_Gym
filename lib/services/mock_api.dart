import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/er_models.dart';
import 'auth.dart';

class MockApiService {
  const MockApiService();

  // Cache ER data in memory so we can add to it during the session
  static Map<String, dynamic>? _erCache;

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

  // ====== ER diagram related mock endpoints (previously ERMockApiService) ======
  Future<Map<String, dynamic>> _readErData() async {
    if (_erCache != null) return _erCache!;
    final jsonString = await rootBundle.loadString('assets/mock/er_data.json');
    _erCache = jsonDecode(jsonString) as Map<String, dynamic>;
    // Merge any users saved locally from previous runs
    final extras = await _loadSavedUsers();
    if (extras.isNotEmpty) {
      final list = (_erCache!['users'] as List<dynamic>);
      // avoid duplicates by email (case-insensitive)
      final existingEmails = list.map((e) => ((e as Map<String, dynamic>)['email'] as String).toLowerCase()).toSet();
      for (final u in extras) {
        final email = (u['email'] as String? ?? '').toLowerCase();
        if (!existingEmails.contains(email)) {
          list.add(u);
          existingEmails.add(email); // Update set to prevent duplicates in same merge
        }
      }
    }
    // Merge saved exercises
    await _mergeSavedExercises();
    return _erCache!;
  }

  Future<List<Map<String, dynamic>>> _loadSavedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('extra_users');
    if (s == null || s.isEmpty) return [];
    try {
      final List<dynamic> arr = jsonDecode(s) as List<dynamic>;
      return arr.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveUserExtra(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadSavedUsers();
    // prevent duplicates by email (case-insensitive)
    final newEmail = (userJson['email'] as String? ?? '').toLowerCase();
    if (current.any((e) => (e['email'] as String? ?? '').toLowerCase() == newEmail)) return;
    current.add(userJson);
    await prefs.setString('extra_users', jsonEncode(current));
  }

  Future<List<UserModel>> fetchUsers() async {
    final m = await _readErData();
    return (m['users'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteUser(String userId) async {
    final m = await _readErData();
    final users = (m['users'] as List<dynamic>);
    users.removeWhere((e) => (e as Map<String, dynamic>)['id'] == userId);
    // also update persisted extras
    final current = await _loadSavedUsers();
    current.removeWhere((e) => e['id'] == userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extra_users', jsonEncode(current));
  }

  Future<void> addUser(UserModel user) async {
    final m = await _readErData();
    final users = (m['users'] as List<dynamic>);
    // prevent duplicates by email (case-insensitive)
    final emailLower = user.email.toLowerCase().trim();
    if (users.any((e) => ((e as Map<String, dynamic>)['email'] as String).toLowerCase().trim() == emailLower)) return;
    final json = {
      'id': user.id,
      'name': user.name,
      'email': user.email.trim(),
      'role': user.role,
      if (user.goal != null) 'goal': user.goal,
    };
    users.add(json);
    await _saveUserExtra(json);
  }

  Future<void> addTrainer({required String name, required String email, required String password}) async {
    final m = await _readErData();
    final users = (m['users'] as List<dynamic>);
    // Check for duplicates case-insensitively
    final emailLower = email.toLowerCase().trim();
    if (users.any((e) => ((e as Map<String, dynamic>)['email'] as String).toLowerCase().trim() == emailLower)) return;
    final json = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email.trim(),
      'role': 'trainer',
      'password': password,
    };
    users.add(json);
    await _saveUserExtra(json);
  }

  Future<List<WorkoutPlanModel>> fetchWorkoutPlans() async {
    final m = await _readErData();
    return (m['workout_plans'] as List<dynamic>)
        .map((e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NutritionPlanModel>> fetchNutritionPlans() async {
    final m = await _readErData();
    return (m['nutrition_plans'] as List<dynamic>)
        .map((e) => NutritionPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityChallengeModel>> fetchChallenges() async {
    final m = await _readErData();
    return (m['community_challenges'] as List<dynamic>)
        .map((e) => CommunityChallengeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProgressLogModel>> fetchProgressLogs(String userId) async {
    final m = await _readErData();
    return (m['progress_logs'] as List<dynamic>)
        .map((e) => ProgressLogModel.fromJson(e as Map<String, dynamic>))
        .where((e) => e.userId == userId)
        .toList();
  }

  Future<void> addChallenge(CommunityChallengeModel challenge) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can create challenges');
    }
    final m = await _readErData();
    (m['community_challenges'] as List<dynamic>).add({
      'id': challenge.id,
      'title': challenge.title,
      'description': challenge.description,
      'startDate': challenge.startDate,
      'endDate': challenge.endDate,
      'createdBy': MockAuthService.instance.currentUser?.id,
      'participants': challenge.participants
          .map((p) => {
                'userId': p.userId,
                'progress': p.progress,
              })
          .toList(),
    });
  }

  Future<void> updateChallenge({required String id, String? title, String? description, String? startDate, String? endDate}) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update challenges');
    }
    final m = await _readErData();
    final list = (m['community_challenges'] as List<dynamic>);
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      if (map['id'] == id) {
        if (title != null) map['title'] = title;
        if (description != null) map['description'] = description;
        if (startDate != null) map['startDate'] = startDate;
        if (endDate != null) map['endDate'] = endDate;
        break;
      }
    }
  }

  Future<void> deleteChallenge(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete challenges');
    }
    final m = await _readErData();
    final list = (m['community_challenges'] as List<dynamic>);
    list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
  }

  // ===== Trainer Profile =====
  Future<TrainerProfileModel> fetchTrainerProfile() async {
    final m = await _readErData();
    Map<String, dynamic>? mp = m['trainer_profile'] as Map<String, dynamic>?;
    
    // Get logged-in trainer's name from auth service
    final loggedInTrainer = MockAuthService.instance.currentUser;
    final trainerName = loggedInTrainer.role.toLowerCase() == 'trainer' 
        ? loggedInTrainer.name 
        : 'Coach Jason Miller';
    
    mp ??= {
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
    
    // Update name and email with logged-in trainer's info if trainer is logged in
    if (loggedInTrainer.role.toLowerCase() == 'trainer') {
      mp['name'] = trainerName;
      mp['email'] = loggedInTrainer.email;
    }
    
    m['trainer_profile'] = mp;
    return TrainerProfileModel.fromJson(mp);
  }

  Future<void> updateTrainerProfile(TrainerProfileModel profile) async {
    final m = await _readErData();
    m['trainer_profile'] = profile.toJson();
  }

  // Mutations - only for trainers (demo)
  Future<void> addWorkoutPlan(WorkoutPlanModel plan) async {
    if (!MockAuthService.instance.isTrainer) {
      throw Exception('Only trainers can create workout plans');
    }
    final m = await _readErData();
    final list = (m['workout_plans'] as List<dynamic>);
    final planJson = {
      'id': plan.id,
      'trainerId': plan.trainerId,
      'name': plan.name,
      'description': plan.description,
      'difficulty': plan.difficulty,
      'workouts': plan.workouts
          .map((w) => {
                'workoutId': w.workoutId,
                'dayOfWeek': w.dayOfWeek,
                'sets': w.sets,
                'reps': w.reps,
              })
          .toList(),
    };
    if (plan.durationMinutes != null) planJson['durationMinutes'] = plan.durationMinutes??"";
    if (plan.kcal != null) planJson['kcal'] = plan.kcal??"";
    if (plan.exercisesCount != null) planJson['exercisesCount'] = plan.exercisesCount??"";
    if (plan.tags != null && plan.tags!.isNotEmpty) planJson['tags'] = plan.tags??"";
    if (plan.equipment != null) planJson['equipment'] = plan.equipment??"";
    if (plan.imageUrl != null) planJson['imageUrl'] = plan.imageUrl??"";
    list.add(planJson);
  }

  Future<void> addNutritionPlan(NutritionPlanModel plan) async {
    if (!MockAuthService.instance.isTrainer) {
      throw Exception('Only trainers can create nutrition plans');
    }
    final m = await _readErData();
    final list = (m['nutrition_plans'] as List<dynamic>);
    list.add({
      'id': plan.id,
      'trainerId': plan.trainerId,
      'name': plan.name,
      'description': plan.description,
      'dailyCaloriesTarget': plan.dailyCaloriesTarget,
      'meals': plan.meals
          .map((meal) => {
                'name': meal.name,
                'timeOfDay': meal.timeOfDay,
              })
          .toList(),
    });
  }

  Future<void> deleteWorkoutPlan(String id) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can delete');
    final m = await _readErData();
    final list = (m['workout_plans'] as List<dynamic>);
    list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
  }

  Future<void> deleteNutritionPlan(String id) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can delete');
    final m = await _readErData();
    final list = (m['nutrition_plans'] as List<dynamic>);
    list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
  }

  Future<void> updateWorkoutPlan({required String id, String? name, String? description, String? difficulty}) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can update');
    final m = await _readErData();
    final list = (m['workout_plans'] as List<dynamic>);
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      if (map['id'] == id) {
        if (name != null) map['name'] = name;
        if (description != null) map['description'] = description;
        if (difficulty != null) map['difficulty'] = difficulty;
        break;
      }
    }
  }

  Future<void> updateNutritionPlan({required String id, String? name, String? description, int? dailyCaloriesTarget}) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can update');
    final m = await _readErData();
    final list = (m['nutrition_plans'] as List<dynamic>);
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      if (map['id'] == id) {
        if (name != null) map['name'] = name;
        if (description != null) map['description'] = description;
        if (dailyCaloriesTarget != null) map['dailyCaloriesTarget'] = dailyCaloriesTarget;
        break;
      }
    }
  }

  // ===== Exercise Management (Trainer only) =====
  Future<List<ExerciseModel>> fetchExercises() async {
    final m = await _readErData();
    if (!m.containsKey('exercises')) {
      m['exercises'] = <dynamic>[];
    }
    final list = (m['exercises'] as List<dynamic>);
    return list.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addExercise(ExerciseModel exercise) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can create exercises');
    }
    final m = await _readErData();
    if (!m.containsKey('exercises')) {
      m['exercises'] = <dynamic>[];
    }
    final list = (m['exercises'] as List<dynamic>);
    // Check for duplicates by id
    if (list.any((e) => (e as Map<String, dynamic>)['id'] == exercise.id)) {
      throw Exception('Exercise with this ID already exists');
    }
    list.add(exercise.toJson());
    // Also save to SharedPreferences for persistence
    await _saveExerciseExtra(exercise.toJson());
  }

  Future<void> _saveExerciseExtra(Map<String, dynamic> exerciseJson) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadSavedExercises();
    // prevent duplicates by id
    if (current.any((e) => e['id'] == exerciseJson['id'])) return;
    current.add(exerciseJson);
    await prefs.setString('extra_exercises', jsonEncode(current));
  }

  Future<List<Map<String, dynamic>>> _loadSavedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('extra_exercises');
    if (s == null || s.isEmpty) return [];
    try {
      final List<dynamic> arr = jsonDecode(s) as List<dynamic>;
      return arr.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateExercise(ExerciseModel exercise) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update exercises');
    }
    final m = await _readErData();
    if (!m.containsKey('exercises')) {
      m['exercises'] = <dynamic>[];
    }
    final list = (m['exercises'] as List<dynamic>);
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      if (map['id'] == exercise.id) {
        map['title'] = exercise.title;
        map['difficulty'] = exercise.difficulty;
        map['sets'] = exercise.sets;
        map['reps'] = exercise.reps;
        map['restSeconds'] = exercise.restSeconds;
        map['targetMuscles'] = exercise.targetMuscles;
        map['videoUrl'] = exercise.videoUrl;
        if (exercise.instructions != null) {
          map['instructions'] = exercise.instructions;
        } else {
          map.remove('instructions');
        }
        break;
      }
    }
    // Update in saved exercises too
    await _updateExerciseExtra(exercise.toJson());
  }

  Future<void> _updateExerciseExtra(Map<String, dynamic> exerciseJson) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadSavedExercises();
    final index = current.indexWhere((e) => e['id'] == exerciseJson['id']);
    if (index != -1) {
      current[index] = exerciseJson;
      await prefs.setString('extra_exercises', jsonEncode(current));
    }
  }

  Future<void> deleteExercise(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete exercises');
    }
    final m = await _readErData();
    if (!m.containsKey('exercises')) {
      m['exercises'] = <dynamic>[];
    }
    final list = (m['exercises'] as List<dynamic>);
    list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
    // Also remove from saved exercises
    final current = await _loadSavedExercises();
    current.removeWhere((e) => e['id'] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extra_exercises', jsonEncode(current));
  }

  // Merge saved exercises with ER data on load
  Future<void> _mergeSavedExercises() async {
    if (_erCache == null) return;
    if (!_erCache!.containsKey('exercises')) {
      _erCache!['exercises'] = <dynamic>[];
    }
    final saved = await _loadSavedExercises();
    if (saved.isNotEmpty) {
      final list = (_erCache!['exercises'] as List<dynamic>);
      final existingIds = list.map((e) => (e as Map<String, dynamic>)['id'] as String).toSet();
      for (final ex in saved) {
        if (!existingIds.contains(ex['id'] as String)) {
          list.add(ex);
          existingIds.add(ex['id'] as String);
        }
      }
    }
  }
}


