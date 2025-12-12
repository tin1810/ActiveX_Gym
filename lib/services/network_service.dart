import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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

  Future<List<UserModel>> fetchUsers({String? role}) async {
    // Fetch users from API instead of SQLite
    try {
      final apiResponse = await activeXGymApiService.getUsers(
        role: role,
        limit: 100, // Fetch more users, adjust as needed
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items;
      } else {
        // If API fails, return empty list or fallback to SQLite
        print('Failed to fetch users from API: ${apiResponse.message}');
        // Fallback to SQLite for now
        await _ensureMigrated();
        final allUsers = await DatabaseHelper.instance.getAllUsers();
        if (role != null) {
          return allUsers.where((u) => u.role == role).toList();
        }
        return allUsers;
      }
    } catch (e) {
      print('Error fetching users: $e');
      // Fallback to SQLite
      await _ensureMigrated();
      final allUsers = await DatabaseHelper.instance.getAllUsers();
      if (role != null) {
        return allUsers.where((u) => u.role == role).toList();
      }
      return allUsers;
    }
  }

  Future<void> deleteUser(String userId) async {
    // Call API to delete user
    final apiResponse = await activeXGymApiService.deleteUser(userId);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to delete user';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) => e.message)
            .where((m) => m.isNotEmpty)
            .toList();
        
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }
      
      throw Exception(errorMessage);
    }
    
    // User deleted successfully via API
    // No need to delete from SQLite as we're using API only
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
    // Call API to create trainer
    final request = TrainerCreateRequest(
      name: name,
      email: email,
      password: password,
    );
    
    final apiResponse = await activeXGymApiService.createTrainer(request);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to create trainer';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) {
              if (e.field.isNotEmpty) {
                return '${e.field}: ${e.message}';
              }
              return e.message;
            })
            .where((m) => m.isNotEmpty)
            .toList();
        
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }
      
      throw Exception(errorMessage);
    }
    
    // Trainer created successfully via API
    // No need to save to SQLite as we're using API only
  }

  Future<List<WorkoutPlanModel>> fetchWorkoutPlans({int? limit}) async {
    // Fetch workout plans from API
    try {
      final apiResponse = await activeXGymApiService.getWorkoutPlans(
        limit: limit ?? 20,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items;
      } else {
        // If API fails, return empty list or fallback to SQLite
        print('Failed to fetch workout plans from API: ${apiResponse.message}');
        // Fallback to SQLite for now
        await _ensureMigrated();
        return await DatabaseHelper.instance.getAllWorkoutPlans();
      }
    } catch (e) {
      print('Error fetching workout plans: $e');
      // Fallback to SQLite
      await _ensureMigrated();
      return await DatabaseHelper.instance.getAllWorkoutPlans();
    }
  }

  Future<List<NutritionPlanModel>> fetchNutritionPlans({String? userId, String? trainerId, int? limit}) async {
    try {
      final apiResponse = await activeXGymApiService.getNutritionPlans(
        userId: userId,
        trainerId: trainerId,
        limit: limit ?? 20,
      );
      
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to fetch nutrition plans';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
      
      return apiResponse.data?.items ?? [];
    } catch (e) {
      String errorMessage = 'Failed to fetch nutrition plans';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<CommunityChallengeModel>> fetchChallenges({int? limit}) async {
    try {
      final apiResponse = await activeXGymApiService.getChallenges(
        limit: limit ?? 20,
      );
      
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to fetch challenges';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
      
      return apiResponse.data?.items ?? [];
    } catch (e) {
      // Fallback to SQLite if API fails
      await _ensureMigrated();
      return await DatabaseHelper.instance.getAllChallenges();
    }
  }

  Future<List<ProgressLogModel>> fetchProgressLogs(String userId) async {
    try {
      final apiResponse = await activeXGymApiService.getProgressLogs(userId: userId);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to fetch progress logs';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
      
      // Return the list of logs from the response
      return apiResponse.data ?? [];
    } catch (e) {
      String errorMessage = 'Failed to fetch progress logs';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> addProgressLog(ProgressLogModel log) async {
    try {
      final request = ProgressLogRequest(
        userId: log.userId,
        date: log.date,
        weightKg: log.weightKg,
        caloriesBurned: log.caloriesBurned,
        bodyFatPercentage: log.bodyFatPercentage,
        muscleMass: log.muscleMass,
        notes: log.notes,
      );
      
      final apiResponse = await activeXGymApiService.createOrUpdateProgressLog(request);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to create progress log';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to create progress log';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> updateProgressLog(ProgressLogModel log) async {
    if (log.id == null || log.id!.isEmpty) {
      throw Exception('Progress log ID is required for update');
    }
    
    try {
      final request = ProgressLogRequest(
        userId: log.userId,
        date: log.date,
        weightKg: log.weightKg,
        caloriesBurned: log.caloriesBurned,
        bodyFatPercentage: log.bodyFatPercentage,
        muscleMass: log.muscleMass,
        notes: log.notes,
      );
      
      final apiResponse = await activeXGymApiService.updateProgressLog(log.id!, request);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to update progress log';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to update progress log';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteProgressLog(String id) async {
    try {
      final apiResponse = await activeXGymApiService.deleteProgressLog(id);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to delete progress log';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to delete progress log';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> addChallenge(CommunityChallengeModel challenge) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can create challenges');
    }
    
    try {
      // Format dates as YYYY-MM-DD
      String formatDate(String dateString) {
        try {
          final date = DateTime.parse(dateString);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          // If already in YYYY-MM-DD format, return as is
          return dateString;
        }
      }
      
      final request = ChallengeRequest(
        title: challenge.title,
        description: challenge.description,
        startDate: formatDate(challenge.startDate),
        endDate: formatDate(challenge.endDate),
        participants: challenge.participants?.map((p) => {
          'userId': p.userId,
          'progress': p.progress,
        }).toList(),
      );
      
      final apiResponse = await activeXGymApiService.createChallenge(request);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to create challenge';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to create challenge';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> updateChallenge({required String id, String? title, String? description, String? startDate, String? endDate}) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update challenges');
    }
    
    try {
      // Format date as YYYY-MM-DD for API
      String formatDate(String dateString) {
        try {
          final date = DateTime.parse(dateString);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          // If already in YYYY-MM-DD format, return as is
          return dateString;
        }
      }
      
      // Build partial data map with only provided fields
      final partialData = <String, dynamic>{};
      if (title != null && title.isNotEmpty) {
        partialData['title'] = title;
      }
      if (description != null && description.isNotEmpty) {
        partialData['description'] = description;
      }
      if (startDate != null && startDate.isNotEmpty) {
        partialData['startDate'] = formatDate(startDate);
      }
      if (endDate != null && endDate.isNotEmpty) {
        partialData['endDate'] = formatDate(endDate);
      }
      
      // Validate that at least one field is provided
      if (partialData.isEmpty) {
        throw Exception('At least one field must be provided for update');
      }
      
      final apiResponse = await activeXGymApiService.patchChallenge(id, partialData);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to update challenge';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to update challenge';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteChallenge(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete challenges');
    }

    try {
      final apiResponse = await activeXGymApiService.deleteChallenge(id);

      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to delete challenge';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to delete challenge';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> joinChallenge(String challengeId, {int progress = 0}) async {
    try {
      final userId = MockAuthService.instance.currentUser.id;
      final apiResponse = await activeXGymApiService.joinChallenge(
        challengeId,
        userId,
        progress,
      );

      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to join challenge';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to join challenge';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> leaveChallenge(String challengeId) async {
    try {
      final userId = MockAuthService.instance.currentUser.id;
      final apiResponse = await activeXGymApiService.leaveChallenge(challengeId, userId);

      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to leave challenge';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to leave challenge';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
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
    
    // Convert PlanWorkoutModel to PlanWorkoutSchedule for API
    final workouts = plan.workouts.map((w) => PlanWorkoutSchedule(
      workoutId: w.workoutId,
      dayOfWeek: w.dayOfWeek, // API expects 1-7 (Monday=1)
      sets: w.sets,
      reps: w.reps,
    )).toList();
    
    // Call API to create workout plan
    final request = WorkoutPlanRequest(
      name: plan.name,
      description: plan.description,
      difficulty: plan.difficulty,
      durationMinutes: plan.durationMinutes,
      kcal: plan.kcal,
      exercisesCount: plan.exercisesCount,
      tags: plan.tags,
      equipment: plan.equipment,
      imageUrl: plan.imageUrl,
      workouts: workouts.isNotEmpty ? workouts : null,
      selectedUserId: plan.userId, // Pass selected user ID from plan
    );
    
    final apiResponse = await activeXGymApiService.createWorkoutPlan(request);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to create workout plan';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) {
              if (e.field.isNotEmpty) {
                return '${e.field}: ${e.message}';
              }
              return e.message;
            })
            .where((m) => m.isNotEmpty)
            .toList();
        
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }
      
      throw Exception(errorMessage);
    }
    
    // Workout plan created successfully via API
    // No need to save to SQLite as we're using API only
  }

  Future<void> addNutritionPlan({
    required String trainerId,
    required String selectedUserId,
    required NutritionPlanRequest request,
  }) async {
    if (!MockAuthService.instance.isTrainer) {
      throw Exception('Only trainers can create nutrition plans');
    }
    
    try {
      final apiResponse = await activeXGymApiService.createNutritionPlan(
        request,
        trainerId: trainerId,
        selectedUserId: selectedUserId,
      );

      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to create nutrition plan';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();

          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to create nutrition plan';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteWorkoutPlan(String id) async {
    if (!MockAuthService.instance.isTrainer) throw Exception('Only trainers can delete');
    await _ensureMigrated();
    await DatabaseHelper.instance.deleteWorkoutPlan(id);
  }

  Future<void> deleteNutritionPlan(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete nutrition plans');
    }
    
    try {
      final apiResponse = await activeXGymApiService.deleteNutritionPlan(id);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to delete nutrition plan';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to delete nutrition plan';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
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
    
    // Convert PlanWorkoutModel to PlanWorkoutSchedule for API
    final workouts = plan.workouts.map((w) => PlanWorkoutSchedule(
      workoutId: w.workoutId,
      dayOfWeek: w.dayOfWeek, // API expects 1-7 (Monday=1)
      sets: w.sets,
      reps: w.reps,
    )).toList();
    
    // Call API to update workout plan
    final request = WorkoutPlanRequest(
      name: plan.name,
      description: plan.description,
      difficulty: plan.difficulty,
      durationMinutes: plan.durationMinutes,
      kcal: plan.kcal,
      exercisesCount: plan.exercisesCount,
      tags: plan.tags,
      equipment: plan.equipment,
      imageUrl: plan.imageUrl,
      workouts: workouts.isNotEmpty ? workouts : null,
      selectedUserId: plan.userId, // Pass selected user ID from plan
    );
    
    final apiResponse = await activeXGymApiService.updateWorkoutPlan(plan.id, request);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to update workout plan';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) {
              if (e.field.isNotEmpty) {
                return '${e.field}: ${e.message}';
              }
              return e.message;
            })
            .join('\n');
        errorMessage = '$errorMessage\n\n$errorMessages';
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> updateNutritionPlan({required String id, String? name, String? description, int? dailyCaloriesTarget}) async {
    if (!MockAuthService.instance.isTrainer) {
      throw Exception('Only trainers can update nutrition plans');
    }
    
    try {
      // Build partial data map with only provided fields
      final partialData = <String, dynamic>{};
      if (name != null && name.isNotEmpty) {
        partialData['name'] = name;
      }
      if (description != null && description.isNotEmpty) {
        partialData['description'] = description;
      }
      if (dailyCaloriesTarget != null) {
        partialData['dailyCaloriesTarget'] = dailyCaloriesTarget;
      }
      
      // Validate that at least one field is provided
      if (partialData.isEmpty) {
        throw Exception('At least one field must be provided for update');
      }
      
      final apiResponse = await activeXGymApiService.patchNutritionPlan(id, partialData);
      
      // Check if the response indicates success
      if (!apiResponse.success) {
        String errorMessage = apiResponse.message ?? 'Failed to update nutrition plan';
        if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
          final errorMessages = apiResponse.errors!
              .map((e) {
                if (e.field.isNotEmpty) {
                  return '${e.field}: ${e.message}';
                }
                return e.message;
              })
              .where((m) => m.isNotEmpty)
              .toList();
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Failed to update nutrition plan';
      if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(12);
        } else if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring(10);
        }
      }
      throw Exception(errorMessage);
    }
  }

  // ===== Exercise Management (Trainer only) =====
  Future<List<ExerciseModel>> fetchExercises({int? limit}) async {
    // Fetch exercises from API instead of SQLite
    try {
      final apiResponse = await activeXGymApiService.getExercises(
        limit: limit ?? 100, // Fetch more exercises, adjust as needed
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items;
      } else {
        // If API fails, return empty list or fallback to SQLite
        print('Failed to fetch exercises from API: ${apiResponse.message}');
        // Fallback to SQLite for now
        await _ensureMigrated();
        return await DatabaseHelper.instance.getAllExercises();
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      // Fallback to SQLite
      await _ensureMigrated();
      return await DatabaseHelper.instance.getAllExercises();
    }
  }

  Future<void> addExercise(ExerciseModel exercise) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can create exercises');
    }
    
    // Call API to create exercise
    final request = ExerciseRequest(
      title: exercise.title,
      difficulty: exercise.difficulty,
      sets: exercise.sets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      targetMuscles: exercise.targetMuscles,
      videoUrl: exercise.videoUrl.isNotEmpty ? exercise.videoUrl : null,
      instructions: exercise.instructions,
    );
    
    final apiResponse = await activeXGymApiService.createExercise(request);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to create exercise';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) {
              if (e.field.isNotEmpty) {
                return '${e.field}: ${e.message}';
              }
              return e.message;
            })
            .where((m) => m.isNotEmpty)
            .toList();
        
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }
      
      throw Exception(errorMessage);
    }
    
    // Exercise created successfully via API
    // No need to save to SQLite as we're using API only
  }


  Future<void> updateExercise(ExerciseModel exercise) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can update exercises');
    }
    
    // Call API to update exercise
    final request = ExerciseRequest(
      title: exercise.title,
      difficulty: exercise.difficulty,
      sets: exercise.sets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      targetMuscles: exercise.targetMuscles,
      videoUrl: exercise.videoUrl.isNotEmpty ? exercise.videoUrl : null,
      instructions: exercise.instructions,
    );
    
    final apiResponse = await activeXGymApiService.updateExercise(exercise.id, request);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to update exercise';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) {
              if (e.field.isNotEmpty) {
                return '${e.field}: ${e.message}';
              }
              return e.message;
            })
            .where((m) => m.isNotEmpty)
            .toList();
        
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }
      
      throw Exception(errorMessage);
    }
    
    // Exercise updated successfully via API
    // No need to update SQLite as we're using API only
  }


  Future<void> deleteExercise(String id) async {
    if (!MockAuthService.instance.isTrainer && !MockAuthService.instance.isAdmin) {
      throw Exception('Only trainers/admins can delete exercises');
    }
    
    // Call API to delete exercise
    final apiResponse = await activeXGymApiService.deleteExercise(id);
    
    if (!apiResponse.success) {
      // Build error message
      String errorMessage = apiResponse.message ?? 'Failed to delete exercise';
      
      if (apiResponse.errors != null && apiResponse.errors!.isNotEmpty) {
        final errorMessages = apiResponse.errors!
            .map((e) => e.message)
            .where((m) => m.isNotEmpty)
            .toList();
        
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }
      
      throw Exception(errorMessage);
    }
    
    // Exercise deleted successfully via API
    // No need to delete from SQLite as we're using API only
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
  final String? selectedUserId;

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
    this.selectedUserId,
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
    NutritionPlanRequest request, {
    String? trainerId,
    String? selectedUserId,
  });

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

  /// POST /challenges/{challengeId}/join
  /// Auth required
  Future<ApiResponse<void>> joinChallenge(
    String challengeId,
    String userId,
    int progress,
  );

  /// POST /challenges/{challengeId}/leave
  /// Auth required
  Future<ApiResponse<void>> leaveChallenge(String challengeId, String userId);

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

  /// PATCH /progress-logs/{id}
  /// Auth required
  Future<ApiResponse<ProgressLogModel>> updateProgressLog(
    String id,
    ProgressLogRequest request,
  );

  /// DELETE /progress-logs/{id}
  /// Auth required
  Future<ApiResponse<void>> deleteProgressLog(String id);

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

// ============================================================================
// Concrete API Service Implementation
// ============================================================================

class ActiveXGymApiServiceImpl extends ActiveXGymApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1'; 
  String? _authToken;

  // Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Get authentication token
  String? get authToken => _authToken;

  // Helper method to make HTTP requests
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      ...?headers,
    };

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Check HTTP status code
      if (response.statusCode >= 400) {
        // Handle error responses
        String errorMessage = 'Request failed with status ${response.statusCode}';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            if (errorData is Map<String, dynamic>) {
              errorMessage = errorData['message'] as String? ?? 
                            errorData['error'] as String? ?? 
                            errorMessage;
            }
          }
        } catch (_) {
          // If parsing fails, use default message
        }
        throw Exception(errorMessage);
      }

      // Parse response body
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }

      final responseData = jsonDecode(response.body);
      if (responseData is Map<String, dynamic>) {
        return responseData;
      } else {
        throw Exception('Invalid response format from server');
      }
    } catch (e) {
      // Handle network errors and parsing errors
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  // Helper method to parse API response
  ApiResponse<T> _parseResponse<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? dataParser,
  ) {
    final success = json['success'] as bool? ?? false;
    final message = json['message'] as String?;
    
    // Handle errors - Laravel can return errors as Map or List
    List<ApiError>? apiErrors;
    final errors = json['errors'];
    
    if (errors != null) {
      apiErrors = [];
      
      if (errors is Map<String, dynamic>) {
        // Laravel validation errors format: {"email": ["The email field is required."]}
        errors.forEach((field, value) {
          if (value is List) {
            for (final errorMsg in value) {
              apiErrors!.add(ApiError(
                field: field,
                message: errorMsg.toString(),
              ));
            }
          } else {
            apiErrors!.add(ApiError(
              field: field,
              message: value.toString(),
            ));
          }
        });
      } else if (errors is List) {
        // Array format: [{"field": "email", "message": "..."}]
        apiErrors = errors.map((e) {
          if (e is Map<String, dynamic>) {
            return ApiError(
              field: e['field'] as String? ?? '',
              message: e['message'] as String? ?? e.toString(),
            );
          } else if (e is String) {
            return ApiError(field: '', message: e);
          }
          return ApiError(field: '', message: e.toString());
        }).toList();
      } else if (errors is String) {
        // Single string error
        apiErrors = [ApiError(field: '', message: errors)];
      }
    }

    T? data;
    if (json['data'] != null && dataParser != null) {
      try {
        final dataValue = json['data'];
        if (dataValue is Map<String, dynamic>) {
          data = dataParser(dataValue);
        } else {
          throw Exception('Expected data to be a Map, got ${dataValue.runtimeType}');
        }
      } catch (e) {
        // Re-throw with more context
        throw Exception('Failed to parse response data: $e');
      }
    }

    return ApiResponse<T>(
      success: success,
      message: message,
      data: data,
      errors: apiErrors,
    );
  }

  @override
  Future<ApiResponse<AuthResponseData>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      return _parseResponse<AuthResponseData>(
        response,
        (data) {
          try {
            final userJson = data['user'] as Map<String, dynamic>?;
            final token = data['token'] as String?;
            
            if (userJson == null) {
              throw Exception('User data is missing in response');
            }
            
            if (token == null || token.isEmpty) {
              throw Exception('Authentication token is missing in response');
            }
            
            // Store token for future requests
            setAuthToken(token);

            return AuthResponseData(
              user: UserModel.fromJson(userJson),
              token: token,
            );
          } catch (e) {
            throw Exception('Failed to parse registration response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<AuthResponseData>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<AuthResponseData>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      return _parseResponse<AuthResponseData>(
        response,
        (data) {
          try {
            final userJson = data['user'] as Map<String, dynamic>?;
            final token = data['token'] as String?;
            
            if (userJson == null) {
              throw Exception('User data is missing in response');
            }
            
            if (token == null || token.isEmpty) {
              throw Exception('Authentication token is missing in response');
            }
            
            // Store token for future requests
            setAuthToken(token);

            return AuthResponseData(
              user: UserModel.fromJson(userJson),
              token: token,
            );
          } catch (e) {
            throw Exception('Failed to parse login response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<AuthResponseData>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/logout',
      );

      // Clear the stored token after successful logout
      setAuthToken(null);

      return _parseResponse<void>(
        response,
        null, // No data to parse for logout
      );
    } catch (e) {
      // Even if API call fails, clear the local token
      setAuthToken(null);
      
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
        errors: [ApiError(field: '', message: e.toString())],
      );
    }
  }

  // Placeholder implementations for other methods
  // These can be implemented as needed
  @override
  Future<ApiResponse<PaginatedResponse<UserModel>>> getUsers({
    String? role,
    int? page,
    int? limit,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      String endpoint = '/users';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _makeRequest('GET', endpoint);

      return _parseResponse<PaginatedResponse<UserModel>>(
        response,
        (data) {
          try {
            // Handle different response formats
            List<UserModel> items = [];
            Map<String, dynamic>? pagination;
            
            // Check for data.users structure (API format: data.users and data.pagination)
            if (data.containsKey('users') && data['users'] is List) {
              final usersList = data['users'] as List<dynamic>;
              items = usersList
                  .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?;
            }
            // Check if data contains 'data' key with list
            else if (data.containsKey('data') && data['data'] is List) {
              final dataList = data['data'] as List<dynamic>;
              items = dataList
                  .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>? 
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            // Check if data contains 'items' key
            else if (data.containsKey('items') && data['items'] is List) {
              final itemsList = data['items'] as List<dynamic>;
              items = itemsList
                  .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>? 
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            // If data itself might be a list (handle as dynamic to avoid type issues)
            else {
              final dynamicData = data as dynamic;
              if (dynamicData is List) {
                final dataList = dynamicData as List<dynamic>;
                items = dataList
                    .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
                    .toList();
              }
            }
            
            // Handle pagination
            final paginationMeta = pagination != null
                ? PaginationMeta(
                    currentPage: (pagination['current_page'] as num?)?.toInt() ?? 1,
                    perPage: (pagination['per_page'] as num?)?.toInt() ?? items.length,
                    total: (pagination['total'] as num?)?.toInt() ?? items.length,
                    totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
                  )
                : PaginationMeta(
                    currentPage: 1,
                    perPage: items.length,
                    total: items.length,
                    totalPages: 1,
                  );

            return PaginatedResponse<UserModel>(
              items: items,
              pagination: paginationMeta,
            );
          } catch (e) {
            print('Error parsing users response: $e');
            print('Response data: $data');
            throw Exception('Failed to parse users response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to fetch users';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<PaginatedResponse<UserModel>>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<UserModel>> getUserById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<UserModel>> getUserByEmail(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<UserModel>> createTrainer(TrainerCreateRequest request) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/users/trainers',
        body: {
          'name': request.name,
          'email': request.email.trim(),
          'password': request.password,
        },
      );

      return _parseResponse<UserModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.trainer or direct data
            Map<String, dynamic> trainerData;
            if (data.containsKey('trainer') && data['trainer'] is Map<String, dynamic>) {
              // Nested structure: data.trainer
              trainerData = data['trainer'] as Map<String, dynamic>;
            } else {
              // Direct structure: data is the trainer
              trainerData = data;
            }
            
            // Ensure role is set to 'trainer' if not provided
            if (trainerData['role'] == null) {
              trainerData['role'] = 'trainer';
            }
            
            // UserModel.fromJson now handles null values safely
            return UserModel.fromJson(trainerData);
          } catch (e) {
            print('Error parsing trainer response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse trainer response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to create trainer';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<UserModel>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<UserModel>> updateUser(String id, UserRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> deleteUser(String id) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/users/$id',
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for delete
      );
    } catch (e) {
      String errorMessage = 'Failed to delete user';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<void>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<PaginatedResponse<ExerciseModel>>> getExercises({
    int? page,
    int? limit,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      String endpoint = '/exercises';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _makeRequest('GET', endpoint);

      return _parseResponse<PaginatedResponse<ExerciseModel>>(
        response,
        (data) {
          try {
            // Handle different response formats
            List<ExerciseModel> items = [];
            Map<String, dynamic>? pagination;
            
            // Check for data.exercises structure (API format: data.exercises and data.pagination)
            if (data.containsKey('exercises') && data['exercises'] is List) {
              final exercisesList = data['exercises'] as List<dynamic>;
              items = exercisesList
                  .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?;
            }
            // Check if data contains 'data' key with list
            else if (data.containsKey('data') && data['data'] is List) {
              final dataList = data['data'] as List<dynamic>;
              items = dataList
                  .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>? 
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            // Check if data contains 'items' key
            else if (data.containsKey('items') && data['items'] is List) {
              final itemsList = data['items'] as List<dynamic>;
              items = itemsList
                  .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>? 
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            
            // Handle pagination
            final paginationMeta = pagination != null
                ? PaginationMeta(
                    currentPage: (pagination['current_page'] as num?)?.toInt() ?? 1,
                    perPage: (pagination['per_page'] as num?)?.toInt() ?? items.length,
                    total: (pagination['total'] as num?)?.toInt() ?? items.length,
                    totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
                  )
                : PaginationMeta(
                    currentPage: 1,
                    perPage: items.length,
                    total: items.length,
                    totalPages: 1,
                  );

            return PaginatedResponse<ExerciseModel>(
              items: items,
              pagination: paginationMeta,
            );
          } catch (e) {
            print('Error parsing exercises response: $e');
            print('Response data: $data');
            throw Exception('Failed to parse exercises response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to fetch exercises';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<PaginatedResponse<ExerciseModel>>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<ExerciseModel>> getExerciseById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ExerciseModel>> createExercise(ExerciseRequest request) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/exercises',
        body: {
          'title': request.title,
          'difficulty': request.difficulty,
          'sets': request.sets,
          'reps': request.reps,
          'restSeconds': request.restSeconds,
          'targetMuscles': request.targetMuscles,
          if (request.videoUrl != null && request.videoUrl!.isNotEmpty) 'videoUrl': request.videoUrl,
          if (request.instructions != null && request.instructions!.isNotEmpty) 'instructions': request.instructions,
        },
      );

      return _parseResponse<ExerciseModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.exercise or direct data
            Map<String, dynamic> exerciseData;
            if (data.containsKey('exercise') && data['exercise'] is Map<String, dynamic>) {
              // Nested structure: data.exercise
              exerciseData = data['exercise'] as Map<String, dynamic>;
            } else {
              // Direct structure: data is the exercise
              exerciseData = data;
            }
            
            // ExerciseModel.fromJson now handles null values safely
            return ExerciseModel.fromJson(exerciseData);
          } catch (e) {
            print('Error parsing exercise response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse exercise response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to create exercise';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<ExerciseModel>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<ExerciseModel>> updateExercise(
    String id,
    ExerciseRequest request,
  ) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '/exercises/$id',
        body: {
          'title': request.title,
          'difficulty': request.difficulty,
          'sets': request.sets,
          'reps': request.reps,
          'restSeconds': request.restSeconds,
          'targetMuscles': request.targetMuscles,
          if (request.videoUrl != null && request.videoUrl!.isNotEmpty) 'videoUrl': request.videoUrl,
          if (request.instructions != null && request.instructions!.isNotEmpty) 'instructions': request.instructions,
        },
      );

      return _parseResponse<ExerciseModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.exercise or direct data
            Map<String, dynamic> exerciseData;
            if (data.containsKey('exercise') && data['exercise'] is Map<String, dynamic>) {
              // Nested structure: data.exercise
              exerciseData = data['exercise'] as Map<String, dynamic>;
            } else {
              // Direct structure: data is the exercise
              exerciseData = data;
            }
            
            // ExerciseModel.fromJson now handles null values safely
            return ExerciseModel.fromJson(exerciseData);
          } catch (e) {
            print('Error parsing exercise response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse exercise response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to update exercise';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<ExerciseModel>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteExercise(String id) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/exercises/$id',
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for delete
      );
    } catch (e) {
      String errorMessage = 'Failed to delete exercise';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<void>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<PaginatedResponse<WorkoutModel>>> getWorkouts({
    String? level,
    String? tag,
    int? page,
    int? limit,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<WorkoutModel>> getWorkoutById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<PaginatedResponse<WorkoutPlanModel>>> getWorkoutPlans({
    String? trainerId,
    String? userId,
    int? page,
    int? limit,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (trainerId != null) queryParams['trainer_id'] = trainerId;
      if (userId != null) queryParams['user_id'] = userId;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      String endpoint = '/workout-plans';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _makeRequest('GET', endpoint);

      return _parseResponse<PaginatedResponse<WorkoutPlanModel>>(
        response,
        (data) {
          try {
            // Handle different response formats
            List<WorkoutPlanModel> items = [];
            Map<String, dynamic>? pagination;
            
            // Check for data.plans structure (API format: data.plans and data.pagination)
            if (data.containsKey('plans') && data['plans'] is List) {
              final plansList = data['plans'] as List<dynamic>;
              items = plansList
                  .map((p) => WorkoutPlanModel.fromJson(p as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?;
            }
            // Check if data contains 'data' key with list
            else if (data.containsKey('data') && data['data'] is List) {
              final dataList = data['data'] as List<dynamic>;
              items = dataList
                  .map((p) => WorkoutPlanModel.fromJson(p as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>? 
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            // Check if data contains 'items' key
            else if (data.containsKey('items') && data['items'] is List) {
              final itemsList = data['items'] as List<dynamic>;
              items = itemsList
                  .map((p) => WorkoutPlanModel.fromJson(p as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>? 
                  ?? data['meta'] as Map<String, dynamic>?;
            }

            // Parse pagination
            PaginationMeta? paginationMeta;
            if (pagination != null) {
              paginationMeta = PaginationMeta(
                currentPage: pagination['current_page'] as int? ?? 1,
                perPage: pagination['per_page'] as int? ?? 20,
                total: pagination['total'] as int? ?? items.length,
                totalPages: pagination['total_pages'] as int? ?? 1,
              );
            } else {
              // Default pagination if not provided
              paginationMeta = PaginationMeta(
                currentPage: 1,
                perPage: items.length,
                total: items.length,
                totalPages: 1,
              );
            }

            return PaginatedResponse<WorkoutPlanModel>(
              items: items,
              pagination: paginationMeta,
            );
          } catch (e) {
            print('Error parsing workout plans response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse workout plans response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to fetch workout plans';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<PaginatedResponse<WorkoutPlanModel>>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<WorkoutPlanModel>> getWorkoutPlanById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<WorkoutPlanModel>> createWorkoutPlan(
    WorkoutPlanRequest request,
  ) async {
    try {
      // Convert workouts to API format
      // Note: Since we're using exercise IDs, the backend might expect 'exerciseId' instead of 'workoutId'
      final workoutsList = request.workouts?.map((w) => {
        'exercise_id': w.workoutId, // Use exerciseId since we're referencing exercises
        'dayOfWeek': w.dayOfWeek,
        'sets': w.sets ?? 3, // Default to 3 if null
        'reps': w.reps ?? '10-12', // Default if null
      }).toList();

      // Get trainer ID from current user
      final trainer = MockAuthService.instance.currentUser;
      if (trainer.id.isEmpty) {
        throw Exception('Trainer ID is required. Please login again.');
      }
      
      // Debug: Log the request body
      print('Creating workout plan with workouts:');
      if (workoutsList != null) {
        for (var w in workoutsList) {
          print('  workoutId: ${w['workoutId']}, dayOfWeek: ${w['dayOfWeek']}, sets: ${w['sets']}, reps: ${w['reps']}');
        }
      }
      
      final response = await _makeRequest(
        'POST',
        '/workout-plans',
        body: {
          'trainerId': trainer.id, // Required by API
          'name': request.name,
          'description': request.description,
          'difficulty': request.difficulty,
          if (request.durationMinutes != null) 'durationMinutes': request.durationMinutes,
          if (request.kcal != null) 'kcal': request.kcal,
          if (request.exercisesCount != null) 'exercisesCount': request.exercisesCount,
          if (request.tags != null && request.tags!.isNotEmpty) 'tags': request.tags,
          if (request.equipment != null && request.equipment!.isNotEmpty) 'equipment': request.equipment,
          if (request.imageUrl != null && request.imageUrl!.isNotEmpty) 'imageUrl': request.imageUrl,
          if (request.selectedUserId != null && request.selectedUserId!.isNotEmpty) 'selectedUserId': request.selectedUserId,
          if (workoutsList != null && workoutsList.isNotEmpty) 'workouts': workoutsList,
        },
      );

      return _parseResponse<WorkoutPlanModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.workoutPlan or direct data
            Map<String, dynamic> planData;
            if (data.containsKey('workoutPlan') && data['workoutPlan'] is Map<String, dynamic>) {
              // Nested structure: data.workoutPlan
              planData = data['workoutPlan'] as Map<String, dynamic>;
            } else {
              // Direct structure: data is the plan
              planData = data;
            }
            
            return WorkoutPlanModel.fromJson(planData);
          } catch (e) {
            print('Error parsing workout plan response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse workout plan response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to create workout plan';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<WorkoutPlanModel>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<WorkoutPlanModel>> updateWorkoutPlan(
    String id,
    WorkoutPlanRequest request,
  ) async {
    try {
      // Convert workouts to API format
      final workoutsList = request.workouts?.map((w) => {
        'exercise_id': w.workoutId, // Use exercise_id since we're referencing exercises
        'dayOfWeek': w.dayOfWeek,
        'sets': w.sets ?? 3, // Default to 3 if null
        'reps': w.reps ?? '10-12', // Default if null
      }).toList();

      // Get trainer ID from current user
      final trainer = MockAuthService.instance.currentUser;
      if (trainer.id.isEmpty) {
        throw Exception('Trainer ID is required. Please login again.');
      }
      
      // Debug: Log the request body
      print('Updating workout plan $id with workouts:');
      if (workoutsList != null) {
        for (var w in workoutsList) {
          print('  exercise_id: ${w['exercise_id']}, dayOfWeek: ${w['dayOfWeek']}, sets: ${w['sets']}, reps: ${w['reps']}');
        }
      }
      
      final response = await _makeRequest(
        'PUT',
        '/workout-plans/$id',
        body: {
          'trainerId': trainer.id, // Required by API
          'name': request.name,
          'description': request.description,
          'difficulty': request.difficulty,
          if (request.durationMinutes != null) 'durationMinutes': request.durationMinutes,
          if (request.kcal != null) 'kcal': request.kcal,
          if (request.exercisesCount != null) 'exercisesCount': request.exercisesCount,
          if (request.tags != null && request.tags!.isNotEmpty) 'tags': request.tags,
          if (request.equipment != null && request.equipment!.isNotEmpty) 'equipment': request.equipment,
          if (request.imageUrl != null && request.imageUrl!.isNotEmpty) 'imageUrl': request.imageUrl,
          if (request.selectedUserId != null && request.selectedUserId!.isNotEmpty) 'selectedUserId': request.selectedUserId,
          if (workoutsList != null && workoutsList.isNotEmpty) 'workouts': workoutsList,
        },
      );

      return _parseResponse<WorkoutPlanModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.workoutPlan or direct data
            Map<String, dynamic> planData;
            if (data.containsKey('workoutPlan') && data['workoutPlan'] is Map<String, dynamic>) {
              // Nested structure: data.workoutPlan
              planData = data['workoutPlan'] as Map<String, dynamic>;
            } else if (data.containsKey('plan') && data['plan'] is Map<String, dynamic>) {
              // Alternative nested structure: data.plan
              planData = data['plan'] as Map<String, dynamic>;
            } else {
              // Direct structure: data is the plan
              planData = data;
            }
            
            return WorkoutPlanModel.fromJson(planData);
          } catch (e) {
            print('Error parsing workout plan response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse workout plan response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to update workout plan';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      return ApiResponse<WorkoutPlanModel>(
        success: false,
        message: errorMessage,
        errors: [ApiError(field: '', message: errorMessage)],
      );
    }
  }

  @override
  Future<ApiResponse<WorkoutPlanModel>> patchWorkoutPlan(
    String id,
    Map<String, dynamic> partialData,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> deleteWorkoutPlan(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<PaginatedResponse<NutritionPlanModel>>> getNutritionPlans({
    String? trainerId,
    String? userId,
    int? page,
    int? limit,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (trainerId != null) queryParams['trainer_id'] = trainerId;
      if (userId != null) queryParams['user_id'] = userId;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      String endpoint = '/nutrition-plans';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _makeRequest('GET', endpoint);

      return _parseResponse<PaginatedResponse<NutritionPlanModel>>(
        response,
        (data) {
          try {
            // Handle different response formats
            List<NutritionPlanModel> items = [];
            Map<String, dynamic>? pagination;

            // Check for data.plans structure (API format: data.plans and data.pagination)
            if (data.containsKey('plans') && data['plans'] is List) {
              final plansList = data['plans'] as List<dynamic>;
              items = plansList
                  .map((p) => NutritionPlanModel.fromJson(p as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?;
            }
            // Check if data contains 'data' key with list
            else if (data.containsKey('data') && data['data'] is List) {
              final dataList = data['data'] as List<dynamic>;
              items = dataList
                  .map((p) => NutritionPlanModel.fromJson(p as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            // Check if data contains 'items' key
            else if (data.containsKey('items') && data['items'] is List) {
              final itemsList = data['items'] as List<dynamic>;
              items = itemsList
                  .map((p) => NutritionPlanModel.fromJson(p as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?
                  ?? data['meta'] as Map<String, dynamic>?;
            }

            // Parse pagination
            PaginationMeta? paginationMeta;
            if (pagination != null) {
              paginationMeta = PaginationMeta(
                currentPage: pagination['current_page'] as int? ?? 1,
                perPage: pagination['per_page'] as int? ?? 20,
                total: pagination['total'] as int? ?? items.length,
                totalPages: pagination['total_pages'] as int? ?? 1,
              );
            } else {
              // Default pagination if not provided
              paginationMeta = PaginationMeta(
                currentPage: 1,
                perPage: items.length,
                total: items.length,
                totalPages: 1,
              );
            }

            return PaginatedResponse<NutritionPlanModel>(
              items: items,
              pagination: paginationMeta,
            );
          } catch (e) {
            print('Error parsing nutrition plans response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse nutrition plans response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to fetch nutrition plans';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<NutritionPlanModel>> getNutritionPlanById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<NutritionPlanModel>> createNutritionPlan(
    NutritionPlanRequest request, {
    String? trainerId,
    String? selectedUserId,
  }) async {
    try {
      // Build meals list
      final mealsList = request.meals.map((m) => {
        'name': m.name,
        'timeOfDay': m.timeOfDay,
      }).toList();

      final body = <String, dynamic>{
        'name': request.name,
        'description': request.description,
        'dailyCaloriesTarget': request.dailyCaloriesTarget,
        'meals': mealsList,
      };
      
      // Add trainerId and selectedUserId if provided
      if (trainerId != null && trainerId.isNotEmpty) {
        body['trainerId'] = trainerId;
      }
      if (selectedUserId != null && selectedUserId.isNotEmpty) {
        body['selectedUserId'] = selectedUserId;
      }

      final response = await _makeRequest(
        'POST',
        '/nutrition-plans',
        body: body,
      );

      return _parseResponse<NutritionPlanModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.plan or direct data
            Map<String, dynamic> planData;
            if (data.containsKey('plan') && data['plan'] is Map<String, dynamic>) {
              planData = data['plan'] as Map<String, dynamic>;
            } else {
              planData = data;
            }
            
            return NutritionPlanModel.fromJson(planData);
          } catch (e) {
            print('Error parsing nutrition plan response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse nutrition plan response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to create nutrition plan';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<NutritionPlanModel>> patchNutritionPlan(
    String id,
    Map<String, dynamic> partialData,
  ) async {
    try {
      final response = await _makeRequest(
        'PATCH',
        '/nutrition-plans/$id',
        body: partialData,
      );

      return _parseResponse<NutritionPlanModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.plan or direct data
            Map<String, dynamic> planData;
            if (data.containsKey('plan') && data['plan'] is Map<String, dynamic>) {
              planData = data['plan'] as Map<String, dynamic>;
            } else {
              planData = data;
            }
            
            return NutritionPlanModel.fromJson(planData);
          } catch (e) {
            print('Error parsing nutrition plan response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse nutrition plan response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to update nutrition plan';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<void>> deleteNutritionPlan(String id) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/nutrition-plans/$id',
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for DELETE requests
      );
    } catch (e) {
      String errorMessage = 'Failed to delete nutrition plan';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<PaginatedResponse<CommunityChallengeModel>>> getChallenges({
    int? page,
    int? limit,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      String endpoint = '/challenges';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _makeRequest('GET', endpoint);

      return _parseResponse<PaginatedResponse<CommunityChallengeModel>>(
        response,
        (data) {
          try {
            // Handle different response formats
            List<CommunityChallengeModel> items = [];
            Map<String, dynamic>? pagination;

            // Check for data.challenges structure (API format: data.challenges and data.pagination)
            if (data.containsKey('challenges') && data['challenges'] is List) {
              final challengesList = data['challenges'] as List<dynamic>;
              items = challengesList
                  .map((c) => CommunityChallengeModel.fromJson(c as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?;
            }
            // Check if data contains 'data' key with list
            else if (data.containsKey('data') && data['data'] is List) {
              final dataList = data['data'] as List<dynamic>;
              items = dataList
                  .map((c) => CommunityChallengeModel.fromJson(c as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?
                  ?? data['meta'] as Map<String, dynamic>?;
            }
            // Check if data contains 'items' key
            else if (data.containsKey('items') && data['items'] is List) {
              final itemsList = data['items'] as List<dynamic>;
              items = itemsList
                  .map((c) => CommunityChallengeModel.fromJson(c as Map<String, dynamic>))
                  .toList();
              pagination = data['pagination'] as Map<String, dynamic>?
                  ?? data['meta'] as Map<String, dynamic>?;
            }

            // Parse pagination
            PaginationMeta? paginationMeta;
            if (pagination != null) {
              paginationMeta = PaginationMeta(
                currentPage: pagination['current_page'] as int? ?? 1,
                perPage: pagination['per_page'] as int? ?? 20,
                total: pagination['total'] as int? ?? items.length,
                totalPages: pagination['total_pages'] as int? ?? 1,
              );
            } else {
              // Default pagination if not provided
              paginationMeta = PaginationMeta(
                currentPage: 1,
                perPage: items.length,
                total: items.length,
                totalPages: 1,
              );
            }

            return PaginatedResponse<CommunityChallengeModel>(
              items: items,
              pagination: paginationMeta,
            );
          } catch (e) {
            print('Error parsing challenges response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse challenges response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to fetch challenges';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<CommunityChallengeModel>> getChallengeById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<CommunityChallengeModel>> createChallenge(
    ChallengeRequest request,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/challenges',
        body: {
          'title': request.title,
          'description': request.description,
          'startDate': request.startDate,
          'endDate': request.endDate,
          if (request.participants != null && request.participants!.isNotEmpty) 'participants': request.participants,
        },
      );

      return _parseResponse<CommunityChallengeModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.challenge or direct data
            Map<String, dynamic> challengeData;
            if (data.containsKey('challenge') && data['challenge'] is Map<String, dynamic>) {
              challengeData = data['challenge'] as Map<String, dynamic>;
            } else {
              challengeData = data;
            }
            
            return CommunityChallengeModel.fromJson(challengeData);
          } catch (e) {
            print('Error parsing challenge response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse challenge response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to create challenge';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<CommunityChallengeModel>> patchChallenge(
    String id,
    Map<String, dynamic> partialData,
  ) async {
    try {
      final response = await _makeRequest(
        'PATCH',
        '/challenges/$id',
        body: partialData,
      );

      return _parseResponse<CommunityChallengeModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.challenge or direct data
            Map<String, dynamic> challengeData;
            if (data.containsKey('challenge') && data['challenge'] is Map<String, dynamic>) {
              challengeData = data['challenge'] as Map<String, dynamic>;
            } else {
              challengeData = data;
            }
            
            return CommunityChallengeModel.fromJson(challengeData);
          } catch (e) {
            print('Error parsing challenge response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse challenge response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to update challenge';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<void>> deleteChallenge(String id) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/challenges/$id',
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for DELETE requests
      );
    } catch (e) {
      String errorMessage = 'Failed to delete challenge';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<void>> joinChallenge(
    String challengeId,
    String userId,
    int progress,
  ) async {
    try {
      // Generate UUID v4 format for the id field if backend requires it
      // Format: 8-4-4-4-12 (e.g., 019b11f5-9692-71bc-99a1-0806e2ea9d68)
      String generateUuid() {
        final now = DateTime.now();
        final timestamp = now.millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
        final microseconds = now.microsecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
        final random = (now.millisecondsSinceEpoch % 1000000).toRadixString(16).padLeft(6, '0');
        
        // Combine to get 32 hex characters total (8-4-4-4-12)
        final combined = (timestamp + microseconds + random).padRight(32, '0').substring(0, 32);
        
        // Format: 8-4-4-4-12
        return '${combined.substring(0, 8)}-${combined.substring(8, 12)}-${combined.substring(12, 16)}-${combined.substring(16, 20)}-${combined.substring(20, 32)}';
      }
      
      final response = await _makeRequest(
        'POST',
        '/challenges/$challengeId/join',
        body: {
          'id': generateUuid(), // Generate ID if backend requires it
          'userId': userId,
         
        },
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for join requests
      );
    } catch (e) {
      String errorMessage = 'Failed to join challenge';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<void>> leaveChallenge(String challengeId, String userId) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/challenges/$challengeId/leave',
        body: {
          'userId': userId,
        },
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for leave requests
      );
    } catch (e) {
      String errorMessage = 'Failed to leave challenge';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<List<ProgressLogModel>>> getProgressLogs({
    required String userId,
  }) async {
    try {
      // Build query parameters - API uses user_id
      final queryParams = <String, String>{
        'user_id': userId,
      };

      String endpoint = '/progress-logs';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _makeRequest('GET', endpoint);

      return _parseResponse<List<ProgressLogModel>>(
        response,
        (data) {
          try {
            // Handle nested structure: data.logs
            List<ProgressLogModel> logs = [];
            
            if (data is Map<String, dynamic> && data.containsKey('logs') && data['logs'] is List) {
              final logsList = data['logs'] as List<dynamic>;
              logs = logsList
                  .map((log) => ProgressLogModel.fromJson(log as Map<String, dynamic>))
                  .toList();
            } else if (data is List) {
              // Fallback: if data is directly a list
              final dataList = data as List<dynamic>;
              logs = dataList
                  .map((log) => ProgressLogModel.fromJson(log as Map<String, dynamic>))
                  .toList();
            }
            
            return logs;
          } catch (e) {
            print('Error parsing progress logs response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse progress logs response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to fetch progress logs';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<ProgressLogModel>> createOrUpdateProgressLog(
    ProgressLogRequest request,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/progress-logs',
        body: {
          'userId': request.userId,
          'date': request.date,
          if (request.weightKg != null) 'weightKg': request.weightKg,
          if (request.caloriesBurned != null) 'caloriesBurned': request.caloriesBurned,
          if (request.bodyFatPercentage != null) 'bodyFatPercentage': request.bodyFatPercentage,
          if (request.muscleMass != null) 'muscleMass': request.muscleMass,
          if (request.notes != null && request.notes!.isNotEmpty) 'notes': request.notes,
        },
      );

      return _parseResponse<ProgressLogModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.log or direct data
            Map<String, dynamic> logData;
            if (data.containsKey('log') && data['log'] is Map<String, dynamic>) {
              logData = data['log'] as Map<String, dynamic>;
            } else {
              logData = data;
            }
            
            return ProgressLogModel.fromJson(logData);
          } catch (e) {
            print('Error parsing progress log response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse progress log response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to create progress log';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<ProgressLogModel>> updateProgressLog(
    String id,
    ProgressLogRequest request,
  ) async {
    try {
      final response = await _makeRequest(
        'PATCH',
        '/progress-logs/$id',
        body: {
          'userId': request.userId,
          'date': request.date,
          if (request.weightKg != null) 'weightKg': request.weightKg,
          if (request.caloriesBurned != null) 'caloriesBurned': request.caloriesBurned,
          if (request.bodyFatPercentage != null) 'bodyFatPercentage': request.bodyFatPercentage,
          if (request.muscleMass != null) 'muscleMass': request.muscleMass,
          if (request.notes != null && request.notes!.isNotEmpty) 'notes': request.notes,
        },
      );

      return _parseResponse<ProgressLogModel>(
        response,
        (data) {
          try {
            // Handle nested structure: data.log or direct data
            Map<String, dynamic> logData;
            if (data.containsKey('log') && data['log'] is Map<String, dynamic>) {
              logData = data['log'] as Map<String, dynamic>;
            } else {
              logData = data;
            }
            
            return ProgressLogModel.fromJson(logData);
          } catch (e) {
            print('Error parsing progress log response: $e');
            print('Response data was: $data');
            throw Exception('Failed to parse progress log response: $e');
          }
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to update progress log';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<void>> deleteProgressLog(String id) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/progress-logs/$id',
      );

      return _parseResponse<void>(
        response,
        null, // No data to parse for DELETE requests
      );
    } catch (e) {
      String errorMessage = 'Failed to delete progress log';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ApiResponse<FavoriteExercisesResponse>> getFavoriteExercises(
    String userId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<FavoriteToggleResponse>> toggleFavoriteExercise(
    String userId,
    String exerciseId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<UserPlanAssignmentModel>> createPlanAssignment(
    PlanAssignmentRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<UserPlanAssignmentModel>>> getPlanAssignments({
    required String userId,
    String? planType,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ImageUploadResponse>> uploadImage(
    List<int> imageBytes,
    String fileName,
  ) async {
    throw UnimplementedError();
  }
}

// Global instance of the API service
final activeXGymApiService = ActiveXGymApiServiceImpl();

