import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/er_models.dart';
import '../models/exercise.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT,
        age INTEGER,
        gender TEXT,
        height REAL,
        weight REAL,
        fitness_goal TEXT,
        created_at TEXT
      )
    ''');

    // Exercises table
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps TEXT NOT NULL,
        rest_seconds INTEGER NOT NULL,
        target_muscles TEXT NOT NULL,
        video_url TEXT,
        instructions TEXT,
        created_at TEXT
      )
    ''');

    // Workout Plans table
    await db.execute('''
      CREATE TABLE workout_plans (
        id TEXT PRIMARY KEY,
        trainer_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        duration_minutes INTEGER,
        kcal INTEGER,
        exercises_count INTEGER,
        tags TEXT,
        equipment TEXT,
        image_url TEXT,
        created_at TEXT
      )
    ''');

    // Plan Workouts table (schedule)
    await db.execute('''
      CREATE TABLE plan_workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id TEXT NOT NULL,
        workout_id TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        sets INTEGER NOT NULL,
        reps TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
      )
    ''');

    // Nutrition Plans table
    await db.execute('''
      CREATE TABLE nutrition_plans (
        id TEXT PRIMARY KEY,
        trainer_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        daily_calories_target INTEGER NOT NULL,
        created_at TEXT
      )
    ''');

    // Nutrition Plan Meals table
    await db.execute('''
      CREATE TABLE nutrition_plan_meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id TEXT NOT NULL,
        name TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES nutrition_plans(id) ON DELETE CASCADE
      )
    ''');

    // Challenges table
    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        target TEXT NOT NULL,
        reward TEXT,
        created_at TEXT
      )
    ''');

    // Challenge Users table
    await db.execute('''
      CREATE TABLE challenge_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        progress REAL DEFAULT 0,
        FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(challenge_id, user_id)
      )
    ''');

    // Progress Logs table
    await db.execute('''
      CREATE TABLE progress_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        weight REAL,
        body_fat_percentage REAL,
        muscle_mass REAL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // User Plan Assignments table
    await db.execute('''
      CREATE TABLE user_plan_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        plan_id TEXT NOT NULL,
        plan_type TEXT NOT NULL,
        assigned_by TEXT NOT NULL,
        start_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Favorite Exercises table
    await db.execute('''
      CREATE TABLE favorite_exercises (
        user_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        PRIMARY KEY (user_id, exercise_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_plan_workouts_plan_id ON plan_workouts(plan_id)');
    await db.execute('CREATE INDEX idx_nutrition_plan_meals_plan_id ON nutrition_plan_meals(plan_id)');
  }

  // ========== Users ==========
  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((map) => UserModel.fromJson(map)).toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromJson(maps.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'LOWER(email) = ?', whereArgs: [email.toLowerCase()]);
    if (maps.isEmpty) return null;
    return UserModel.fromJson(maps.first);
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', _userToMap(user), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update('users', _userToMap(user), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _userToMap(UserModel user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'password': user.password ?? '',
      'role': user.role,
      'phone': null,
      'age': null,
      'gender': null,
      'height': null,
      'weight': null,
      'fitness_goal': user.goal,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  // ========== Exercises ==========
  Future<List<ExerciseModel>> getAllExercises() async {
    final db = await database;
    final maps = await db.query('exercises', orderBy: 'created_at DESC');
    return maps.map((map) => _exerciseFromMap(map)).toList();
  }

  Future<ExerciseModel?> getExerciseById(String id) async {
    final db = await database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _exerciseFromMap(maps.first);
  }

  Future<int> insertExercise(ExerciseModel exercise) async {
    final db = await database;
    return await db.insert('exercises', _exerciseToMap(exercise), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateExercise(ExerciseModel exercise) async {
    final db = await database;
    return await db.update('exercises', _exerciseToMap(exercise), where: 'id = ?', whereArgs: [exercise.id]);
  }

  Future<int> deleteExercise(String id) async {
    final db = await database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _exerciseToMap(ExerciseModel exercise) {
    return {
      'id': exercise.id,
      'title': exercise.title,
      'difficulty': exercise.difficulty,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'rest_seconds': exercise.restSeconds,
      'target_muscles': jsonEncode(exercise.targetMuscles),
      'video_url': exercise.videoUrl,
      'instructions': exercise.instructions != null ? jsonEncode(exercise.instructions) : null,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  ExerciseModel _exerciseFromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      title: map['title'] as String,
      difficulty: map['difficulty'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as String,
      restSeconds: map['rest_seconds'] as int,
      targetMuscles: (jsonDecode(map['target_muscles'] as String) as List<dynamic>).cast<String>(),
      videoUrl: map['video_url'] as String? ?? '',
      instructions: map['instructions'] != null 
          ? (jsonDecode(map['instructions'] as String) as List<dynamic>).cast<String>()
          : null,
    );
  }

  // ========== Workout Plans ==========
  Future<List<WorkoutPlanModel>> getAllWorkoutPlans() async {
    final db = await database;
    final maps = await db.query('workout_plans', orderBy: 'created_at DESC');
    final List<WorkoutPlanModel> plans = [];
    
    for (final map in maps) {
      final planId = map['id'] as String;
      final workouts = await getPlanWorkouts(planId);
      plans.add(_workoutPlanFromMap(map, workouts));
    }
    
    return plans;
  }

  Future<WorkoutPlanModel?> getWorkoutPlanById(String id) async {
    final db = await database;
    final maps = await db.query('workout_plans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    
    final workouts = await getPlanWorkouts(id);
    return _workoutPlanFromMap(maps.first, workouts);
  }

  Future<int> insertWorkoutPlan(WorkoutPlanModel plan) async {
    final db = await database;
    final batch = db.batch();
    
    batch.insert('workout_plans', _workoutPlanToMap(plan), conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Delete existing workouts for this plan
    batch.delete('plan_workouts', where: 'plan_id = ?', whereArgs: [plan.id]);
    
    // Insert new workouts
    for (final workout in plan.workouts) {
      batch.insert('plan_workouts', {
        'plan_id': plan.id,
        'workout_id': workout.workoutId,
        'day_of_week': workout.dayOfWeek,
        'sets': workout.sets,
        'reps': workout.reps,
      });
    }
    
    await batch.commit(noResult: true);
    return 1;
  }

  Future<int> updateWorkoutPlan(WorkoutPlanModel plan) async {
    return await insertWorkoutPlan(plan); // Same logic
  }

  Future<int> deleteWorkoutPlan(String id) async {
    final db = await database;
    return await db.delete('workout_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PlanWorkoutModel>> getPlanWorkouts(String planId) async {
    final db = await database;
    final maps = await db.query('plan_workouts', where: 'plan_id = ?', whereArgs: [planId], orderBy: 'day_of_week');
    return maps.map((map) => PlanWorkoutModel(
      workoutId: map['workout_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      sets: map['sets'] as int,
      reps: map['reps'] as String,
    )).toList();
  }

  Map<String, dynamic> _workoutPlanToMap(WorkoutPlanModel plan) {
    return {
      'id': plan.id,
      'trainer_id': plan.trainerId,
      'name': plan.name,
      'description': plan.description,
      'difficulty': plan.difficulty,
      'duration_minutes': plan.durationMinutes,
      'kcal': plan.kcal,
      'exercises_count': plan.exercisesCount,
      'tags': plan.tags != null ? jsonEncode(plan.tags) : null,
      'equipment': plan.equipment,
      'image_url': plan.imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  WorkoutPlanModel _workoutPlanFromMap(Map<String, dynamic> map, List<PlanWorkoutModel> workouts) {
    return WorkoutPlanModel(
      id: map['id'] as String,
      trainerId: map['trainer_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      difficulty: map['difficulty'] as String,
      workouts: workouts,
      durationMinutes: map['duration_minutes'] as int?,
      kcal: map['kcal'] as int?,
      exercisesCount: map['exercises_count'] as int?,
      tags: map['tags'] != null ? (jsonDecode(map['tags'] as String) as List<dynamic>).cast<String>() : null,
      equipment: map['equipment'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }

  // ========== Nutrition Plans ==========
  Future<List<NutritionPlanModel>> getAllNutritionPlans() async {
    final db = await database;
    final maps = await db.query('nutrition_plans', orderBy: 'created_at DESC');
    final List<NutritionPlanModel> plans = [];
    
    for (final map in maps) {
      final planId = map['id'] as String;
      final meals = await getNutritionPlanMeals(planId);
      plans.add(_nutritionPlanFromMap(map, meals));
    }
    
    return plans;
  }

  Future<int> insertNutritionPlan(NutritionPlanModel plan) async {
    final db = await database;
    final batch = db.batch();
    
    batch.insert('nutrition_plans', {
      'id': plan.id,
      'trainer_id': plan.trainerId,
      'name': plan.name,
      'description': plan.description,
      'daily_calories_target': plan.dailyCaloriesTarget,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    batch.delete('nutrition_plan_meals', where: 'plan_id = ?', whereArgs: [plan.id]);
    
    for (final meal in plan.meals) {
      batch.insert('nutrition_plan_meals', {
        'plan_id': plan.id,
        'name': meal.name,
        'time_of_day': meal.timeOfDay,
      });
    }
    
    await batch.commit(noResult: true);
    return 1;
  }

  Future<int> deleteNutritionPlan(String id) async {
    final db = await database;
    return await db.delete('nutrition_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealModel>> getNutritionPlanMeals(String planId) async {
    final db = await database;
    final maps = await db.query('nutrition_plan_meals', where: 'plan_id = ?', whereArgs: [planId]);
    return maps.map((map) => MealModel(
      name: map['name'] as String,
      timeOfDay: map['time_of_day'] as String,
    )).toList();
  }

  NutritionPlanModel _nutritionPlanFromMap(Map<String, dynamic> map, List<MealModel> meals) {
    return NutritionPlanModel(
      id: map['id'] as String,
      trainerId: map['trainer_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      dailyCaloriesTarget: map['daily_calories_target'] as int,
      meals: meals,
    );
  }

  // ========== Challenges ==========
  Future<List<CommunityChallengeModel>> getAllChallenges() async {
    final db = await database;
    final maps = await db.query('challenges', orderBy: 'created_at DESC');
    final List<CommunityChallengeModel> challenges = [];
    
    for (final map in maps) {
      final challengeId = map['id'] as String;
      final users = await getChallengeUsers(challengeId);
      challenges.add(_challengeFromMap(map, users));
    }
    
    return challenges;
  }

  Future<int> insertChallenge(CommunityChallengeModel challenge) async {
    final db = await database;
    final batch = db.batch();
    
    batch.insert('challenges', {
      'id': challenge.id,
      'name': challenge.title, // Store title as name in database
      'description': challenge.description,
      'start_date': challenge.startDate,
      'end_date': challenge.endDate,
      'target': '', // Challenge model doesn't have target field
      'reward': '', // Challenge model doesn't have reward field
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    batch.delete('challenge_users', where: 'challenge_id = ?', whereArgs: [challenge.id]);
    
    for (final user in challenge.participants) {
      batch.insert('challenge_users', {
        'challenge_id': challenge.id,
        'user_id': user.userId,
        'progress': user.progress,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
    return 1;
  }

  Future<int> deleteChallenge(String id) async {
    final db = await database;
    return await db.delete('challenges', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ChallengeUserModel>> getChallengeUsers(String challengeId) async {
    final db = await database;
    final maps = await db.query('challenge_users', where: 'challenge_id = ?', whereArgs: [challengeId]);
    return maps.map((map) => ChallengeUserModel(
      userId: map['user_id'] as String,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  CommunityChallengeModel _challengeFromMap(Map<String, dynamic> map, List<ChallengeUserModel> users) {
    // Support both 'name' and 'title' fields for backward compatibility
    final title = map['name'] as String? ?? map['title'] as String? ?? 'Challenge';
    return CommunityChallengeModel(
      id: map['id'] as String,
      title: title,
      description: map['description'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      participants: users,
      createdBy: null,
    );
  }

  // ========== Progress Logs ==========
  Future<List<ProgressLogModel>> getProgressLogs(String userId) async {
    final db = await database;
    final maps = await db.query('progress_logs', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
    return maps.map((map) => ProgressLogModel(
      userId: map['user_id'] as String,
      date: map['date'] as String,
      weightKg: (map['weight'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: 0, // Default value
    )).toList();
  }

  Future<int> insertProgressLog(ProgressLogModel log) async {
    final db = await database;
    return await db.insert('progress_logs', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': log.userId,
      'date': log.date,
      'weight': log.weightKg,
      'body_fat_percentage': null,
      'muscle_mass': null,
      'notes': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ========== Favorite Exercises ==========
  Future<Set<String>> getFavoriteExercises(String userId) async {
    final db = await database;
    final maps = await db.query('favorite_exercises', where: 'user_id = ?', whereArgs: [userId]);
    return maps.map((map) => map['exercise_id'] as String).toSet();
  }

  Future<void> toggleFavoriteExercise(String userId, String exerciseId) async {
    final db = await database;
    final existing = await db.query(
      'favorite_exercises',
      where: 'user_id = ? AND exercise_id = ?',
      whereArgs: [userId, exerciseId],
    );
    
    if (existing.isEmpty) {
      await db.insert('favorite_exercises', {
        'user_id': userId,
        'exercise_id': exerciseId,
      });
    } else {
      await db.delete(
        'favorite_exercises',
        where: 'user_id = ? AND exercise_id = ?',
        whereArgs: [userId, exerciseId],
      );
    }
  }

  // ========== Migration from JSON/SharedPreferences ==========
  Future<void> migrateFromJson(Map<String, dynamic> erData) async {
    final db = await database;
    final batch = db.batch();

    // Migrate users
    if (erData.containsKey('users')) {
      for (final userJson in erData['users'] as List<dynamic>) {
        try {
          final user = UserModel.fromJson(userJson as Map<String, dynamic>);
          batch.insert('users', _userToMap(user), conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          // Skip invalid users
        }
      }
    }

    // Migrate exercises
    if (erData.containsKey('exercises')) {
      for (final exJson in erData['exercises'] as List<dynamic>) {
        try {
          final exercise = ExerciseModel.fromJson(exJson as Map<String, dynamic>);
          batch.insert('exercises', _exerciseToMap(exercise), conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          // Skip invalid exercises
        }
      }
    }

    // Migrate workout plans
    if (erData.containsKey('workout_plans')) {
      for (final planJson in erData['workout_plans'] as List<dynamic>) {
        try {
          final plan = WorkoutPlanModel.fromJson(planJson as Map<String, dynamic>);
          batch.insert('workout_plans', _workoutPlanToMap(plan), conflictAlgorithm: ConflictAlgorithm.replace);
          
          for (final workout in plan.workouts) {
            batch.insert('plan_workouts', {
              'plan_id': plan.id,
              'workout_id': workout.workoutId,
              'day_of_week': workout.dayOfWeek,
              'sets': workout.sets,
              'reps': workout.reps,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        } catch (e) {
          // Skip invalid plans
        }
      }
    }

    // Migrate nutrition plans
    if (erData.containsKey('nutrition_plans')) {
      for (final planJson in erData['nutrition_plans'] as List<dynamic>) {
        try {
          final plan = NutritionPlanModel.fromJson(planJson as Map<String, dynamic>);
          batch.insert('nutrition_plans', {
            'id': plan.id,
            'trainer_id': plan.trainerId,
            'name': plan.name,
            'description': plan.description,
            'daily_calories_target': plan.dailyCaloriesTarget,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          
          for (final meal in plan.meals) {
            batch.insert('nutrition_plan_meals', {
              'plan_id': plan.id,
              'name': meal.name,
              'time_of_day': meal.timeOfDay,
            });
          }
        } catch (e) {
          // Skip invalid plans
        }
      }
    }

    // Migrate challenges
    if (erData.containsKey('challenges') || erData.containsKey('community_challenges')) {
      final challengesList = erData['challenges'] as List<dynamic>? ?? erData['community_challenges'] as List<dynamic>? ?? [];
      for (final challengeJson in challengesList) {
        try {
          final challenge = CommunityChallengeModel.fromJson(challengeJson as Map<String, dynamic>);
          batch.insert('challenges', {
            'id': challenge.id,
            'name': challenge.title, // Store title as name
            'description': challenge.description,
            'start_date': challenge.startDate,
            'end_date': challenge.endDate,
            'target': '',
            'reward': '',
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          
          for (final user in challenge.participants) {
            batch.insert('challenge_users', {
              'challenge_id': challenge.id,
              'user_id': user.userId,
              'progress': user.progress,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        } catch (e) {
          // Skip invalid challenges
        }
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

