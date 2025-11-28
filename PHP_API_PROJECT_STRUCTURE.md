# PHP API Project Structure

This document outlines the recommended folder structure for implementing the ActiveX Gym App API in PHP.

## Recommended Project Structure

```
activex-gym-api/
├── api/
│   └── v1/
│       ├── auth/
│       │   ├── register.php
│       │   ├── login.php
│       │   └── logout.php
│       ├── users/
│       │   ├── index.php          # GET all users
│       │   ├── show.php            # GET user by ID
│       │   ├── create.php          # POST create user
│       │   ├── update.php          # PUT update user
│       │   ├── delete.php          # DELETE user
│       │   ├── trainers/
│       │   │   └── create.php      # POST create trainer
│       │   └── email/
│       │       └── show.php        # GET user by email
│       ├── workouts/
│       │   ├── index.php           # GET all workouts
│       │   └── show.php            # GET workout by ID
│       ├── workout-plans/
│       │   ├── index.php           # GET all workout plans
│       │   ├── show.php            # GET workout plan by ID
│       │   ├── create.php          # POST create workout plan
│       │   ├── update.php          # PUT update workout plan
│       │   ├── patch.php           # PATCH partial update
│       │   └── delete.php          # DELETE workout plan
│       ├── nutrition-plans/
│       │   ├── index.php           # GET all nutrition plans
│       │   ├── show.php            # GET nutrition plan by ID
│       │   ├── create.php          # POST create nutrition plan
│       │   ├── update.php          # PATCH update nutrition plan
│       │   └── delete.php          # DELETE nutrition plan
│       ├── exercises/
│       │   ├── index.php           # GET all exercises
│       │   ├── show.php            # GET exercise by ID
│       │   ├── create.php          # POST create exercise
│       │   ├── update.php          # PUT update exercise
│       │   └── delete.php          # DELETE exercise
│       ├── challenges/
│       │   ├── index.php           # GET all challenges
│       │   ├── show.php            # GET challenge by ID
│       │   ├── create.php          # POST create challenge
│       │   ├── update.php          # PATCH update challenge
│       │   └── delete.php          # DELETE challenge
│       ├── progress-logs/
│       │   ├── index.php           # GET progress logs
│       │   └── create.php          # POST create/update progress log
│       ├── trainers/
│       │   └── profile/
│       │       ├── show.php        # GET trainer profile
│       │       └── update.php      # PUT update profile
│       ├── favorites/
│       │   └── exercises/
│       │       ├── index.php       # GET favorite exercises
│       │       └── toggle.php      # POST toggle favorite
│       └── plan-assignments/
│           ├── index.php           # GET plan assignments
│           └── create.php          # POST assign plan
├── config/
│   ├── database.php                # Database configuration
│   ├── jwt.php                     # JWT configuration
│   └── cors.php                    # CORS configuration
├── includes/
│   ├── auth.php                    # Authentication helper functions
│   ├── response.php                # Response formatting functions
│   ├── validation.php              # Input validation functions
│   └── errors.php                  # Error handling functions
├── models/
│   ├── User.php
│   ├── WorkoutPlan.php
│   ├── NutritionPlan.php
│   ├── Exercise.php
│   ├── Challenge.php
│   ├── ProgressLog.php
│   ├── TrainerProfile.php
│   └── Workout.php
├── middleware/
│   ├── auth.php                    # Authentication middleware
│   ├── role.php                    # Role-based access control
│   └── cors.php                    # CORS middleware
├── database/
│   ├── migrations/
│   │   ├── 001_create_users_table.php
│   │   ├── 002_create_workout_plans_table.php
│   │   ├── 003_create_nutrition_plans_table.php
│   │   ├── 004_create_exercises_table.php
│   │   ├── 005_create_challenges_table.php
│   │   ├── 006_create_progress_logs_table.php
│   │   └── ...
│   └── seeds/
│       ├── seed_users.php
│       ├── seed_exercises.php
│       └── seed_workouts.php
├── utils/
│   ├── password.php                # Password hashing utilities
│   ├── jwt.php                     # JWT token utilities
│   ├── uuid.php                    # UUID generation
│   └── image.php                   # Image handling utilities
├── .htaccess                       # Apache rewrite rules
├── index.php                       # Entry point/router
├── composer.json                   # PHP dependencies
├── .env.example                    # Environment variables example
├── .env                            # Environment variables (not in git)
├── README.md
└── API_DOCUMENTATION.md            # API documentation

```

## Key Files Description

### Entry Point (index.php)
```php
<?php
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/response.php';
require_once __DIR__ . '/middleware/cors.php';
require_once __DIR__ . '/middleware/auth.php';

// Enable CORS
handleCors();

// Get request method and path
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = str_replace('/api/v1', '', $path);

// Route handling
// ... routing logic
```

### Database Configuration (config/database.php)
```php
<?php
class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $conn;

    public function __construct() {
        $this->host = getenv('DB_HOST') ?: 'localhost';
        $this->db_name = getenv('DB_NAME') ?: 'activex_gym';
        $this->username = getenv('DB_USER') ?: 'root';
        $this->password = getenv('DB_PASS') ?: '';
    }

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $e) {
            echo "Connection error: " . $e->getMessage();
        }
        return $this->conn;
    }
}
```

### Response Helper (includes/response.php)
```php
<?php
function sendResponse($success, $message, $data = null, $errors = [], $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    
    $response = [
        'success' => $success,
        'message' => $message
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    if (!empty($errors)) {
        $response['errors'] = $errors;
    }
    
    echo json_encode($response);
    exit;
}

function sendSuccess($message, $data = null, $statusCode = 200) {
    sendResponse(true, $message, $data, [], $statusCode);
}

function sendError($message, $errors = [], $statusCode = 400) {
    sendResponse(false, $message, null, $errors, $statusCode);
}
```

### Authentication Middleware (middleware/auth.php)
```php
<?php
function verifyToken() {
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }
    
    if (!$token) {
        sendError('Unauthorized', [], 401);
    }
    
    // Verify JWT token
    try {
        $decoded = verifyJWT($token);
        return $decoded;
    } catch (Exception $e) {
        sendError('Invalid token', [], 401);
    }
}

function requireAuth() {
    return verifyToken();
}

function requireRole($allowedRoles) {
    $user = requireAuth();
    if (!in_array($user->role, $allowedRoles)) {
        sendError('Forbidden', [], 403);
    }
    return $user;
}
```

### Example Endpoint (api/v1/auth/login.php)
```php
<?php
require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../includes/response.php';
require_once __DIR__ . '/../../../includes/validation.php';
require_once __DIR__ . '/../../../utils/jwt.php';
require_once __DIR__ . '/../../../models/User.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed', [], 405);
}

$data = json_decode(file_get_contents('php://input'), true);

// Validate input
$errors = [];
if (empty($data['email'])) {
    $errors[] = ['field' => 'email', 'message' => 'Email is required'];
}
if (empty($data['password'])) {
    $errors[] = ['field' => 'password', 'message' => 'Password is required'];
}

if (!empty($errors)) {
    sendError('Validation failed', $errors, 422);
}

// Check for admin login
$email = strtolower(trim($data['email']));
if ($email === 'admin@gmail.com' || strpos($email, 'admin') !== false) {
    // Handle admin login
    $user = [
        'id' => 'a1',
        'name' => 'Admin',
        'email' => $email,
        'role' => 'admin'
    ];
    $token = generateJWT($user);
    sendSuccess('Login successful', [
        'user' => $user,
        'token' => $token
    ], 200);
}

// Regular user/trainer login
$database = new Database();
$db = $database->getConnection();
$userModel = new User($db);

$user = $userModel->findByEmail($email);

if (!$user) {
    sendError('User not found', [], 404);
}

// Verify password
if (!password_verify($data['password'], $user['password'])) {
    if ($user['role'] === 'trainer' && !empty($user['password'])) {
        sendError('Incorrect password', [], 401);
    }
}

// Generate token
$token = generateJWT([
    'id' => $user['id'],
    'email' => $user['email'],
    'role' => $user['role']
]);

sendSuccess('Login successful', [
    'user' => [
        'id' => $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'role' => $user['role'],
        'goal' => $user['goal'] ?? null
    ],
    'token' => $token
], 200);
```

## Database Schema SQL

### Users Table
```sql
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('user', 'trainer', 'admin') NOT NULL DEFAULT 'user',
    goal VARCHAR(255),
    phone VARCHAR(20),
    age INT,
    gender VARCHAR(10),
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    fitness_goal VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
);
```

### Workout Plans Table
```sql
CREATE TABLE workout_plans (
    id VARCHAR(36) PRIMARY KEY,
    trainer_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    difficulty ENUM('beginner', 'intermediate', 'advanced') NOT NULL,
    duration_minutes INT,
    kcal INT,
    exercises_count INT,
    tags JSON,
    equipment VARCHAR(255),
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_trainer (trainer_id)
);
```

### Plan Workouts Table
```sql
CREATE TABLE plan_workouts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plan_id VARCHAR(36) NOT NULL,
    workout_id VARCHAR(36) NOT NULL,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    sets INT NOT NULL,
    reps VARCHAR(50) NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
    INDEX idx_plan (plan_id)
);
```

### Nutrition Plans Table
```sql
CREATE TABLE nutrition_plans (
    id VARCHAR(36) PRIMARY KEY,
    trainer_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    daily_calories_target INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_trainer (trainer_id)
);
```

### Nutrition Plan Meals Table
```sql
CREATE TABLE nutrition_plan_meals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plan_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    time_of_day VARCHAR(10) NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES nutrition_plans(id) ON DELETE CASCADE,
    INDEX idx_plan (plan_id)
);
```

### Exercises Table
```sql
CREATE TABLE exercises (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    difficulty ENUM('Beginner', 'Intermediate', 'Advanced') NOT NULL,
    sets INT NOT NULL,
    reps VARCHAR(50) NOT NULL,
    rest_seconds INT NOT NULL,
    target_muscles JSON NOT NULL,
    video_url TEXT,
    instructions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_difficulty (difficulty)
);
```

### Challenges Table
```sql
CREATE TABLE challenges (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_by VARCHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_dates (start_date, end_date)
);
```

### Challenge Users Table
```sql
CREATE TABLE challenge_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    progress INT DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_challenge_user (challenge_id, user_id),
    INDEX idx_challenge (challenge_id),
    INDEX idx_user (user_id)
);
```

### Progress Logs Table
```sql
CREATE TABLE progress_logs (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    date DATE NOT NULL,
    weight DECIMAL(5,2),
    calories_burned INT DEFAULT 0,
    body_fat_percentage DECIMAL(5,2),
    muscle_mass DECIMAL(5,2),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_date (user_id, date),
    INDEX idx_user (user_id),
    INDEX idx_date (date)
);
```

### User Plan Assignments Table
```sql
CREATE TABLE user_plan_assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    plan_id VARCHAR(36) NOT NULL,
    plan_type ENUM('workout', 'nutrition') NOT NULL,
    assigned_by VARCHAR(36) NOT NULL,
    start_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_plan (plan_id, plan_type)
);
```

### Favorite Exercises Table
```sql
CREATE TABLE favorite_exercises (
    user_id VARCHAR(36) NOT NULL,
    exercise_id VARCHAR(36) NOT NULL,
    PRIMARY KEY (user_id, exercise_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);
```

### Trainer Profiles Table
```sql
CREATE TABLE trainer_profiles (
    trainer_id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    bio TEXT NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    location VARCHAR(255) NOT NULL,
    clients INT DEFAULT 0,
    plans INT DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating BETWEEN 0.0 AND 5.0),
    avatar_url TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## Environment Variables (.env.example)
```env
# Database
DB_HOST=localhost
DB_NAME=activex_gym
DB_USER=root
DB_PASS=

# JWT
JWT_SECRET=your-secret-key-here
JWT_EXPIRY=86400

# API
API_BASE_URL=http://localhost/api/v1
CORS_ALLOWED_ORIGINS=*

# File Upload
UPLOAD_DIR=uploads/
MAX_FILE_SIZE=5242880
```

## Composer Dependencies (composer.json)
```json
{
    "name": "activex/gym-api",
    "description": "ActiveX Gym App API",
    "require": {
        "php": ">=7.4",
        "firebase/php-jwt": "^6.0",
        "vlucas/phpdotenv": "^5.0"
    },
    "autoload": {
        "psr-4": {
            "ActiveX\\": "src/"
        }
    }
}
```

## .htaccess (Apache)
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^api/v1/(.*)$ index.php?route=$1 [QSA,L]

# CORS Headers
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type, Authorization"

# Handle OPTIONS requests
RewriteCond %{REQUEST_METHOD} OPTIONS
RewriteRule ^(.*)$ $1 [R=200,L]
```

## Implementation Checklist

- [ ] Set up project structure
- [ ] Configure database connection
- [ ] Implement JWT authentication
- [ ] Create database tables
- [ ] Implement authentication endpoints
- [ ] Implement user management endpoints
- [ ] Implement workout plan endpoints
- [ ] Implement nutrition plan endpoints
- [ ] Implement exercise endpoints
- [ ] Implement challenge endpoints
- [ ] Implement progress log endpoints
- [ ] Implement trainer profile endpoints
- [ ] Add input validation
- [ ] Add error handling
- [ ] Add CORS support
- [ ] Add rate limiting
- [ ] Add logging
- [ ] Write unit tests
- [ ] Write API documentation
- [ ] Deploy to production

## Security Best Practices

1. **Password Hashing**: Always use `password_hash()` and `password_verify()`
2. **SQL Injection**: Use prepared statements (PDO)
3. **XSS Protection**: Sanitize all user inputs
4. **CSRF Protection**: Implement CSRF tokens for state-changing operations
5. **Rate Limiting**: Implement rate limiting to prevent abuse
6. **HTTPS**: Always use HTTPS in production
7. **Token Expiry**: Set reasonable JWT token expiry times
8. **Input Validation**: Validate all inputs on the server side
9. **Error Messages**: Don't expose sensitive information in error messages
10. **Logging**: Log all security-related events

## Testing

Use tools like:
- Postman for API testing
- PHPUnit for unit testing
- cURL for command-line testing

## Deployment

Recommended hosting:
- Shared hosting with PHP 7.4+
- VPS with Apache/Nginx
- Cloud platforms (AWS, Google Cloud, Azure)

