import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/workout.dart';
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
    return _erCache!;
  }

  Future<List<UserModel>> fetchUsers() async {
    final m = await _readErData();
    return (m['users'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
    mp ??= {
      'name': 'Coach Jason Miller',
      'title': 'Certified Personal Trainer',
      'bio': 'Passionate fitness coach specializing in strength training and nutrition. Helping clients transform their lives for 8+ years.',
      'email': 'jason.miller@activextra.com',
      'phone': '+1 (555) 123-4567',
      'location': 'Los Angeles, CA',
      'clients': 24,
      'plans': 33,
      'rating': 4.9,
      'avatarUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300&h=300&fit=crop',
    };
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
    list.add({
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
    });
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
}


