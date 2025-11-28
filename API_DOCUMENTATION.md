# ActiveX Gym App - API Documentation

## Base URL
```
https://your-domain.com/api/v1
```

## Authentication
All protected endpoints require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer {access_token}
```

## Response Format
All API responses follow this structure:
```json
{
  "success": true|false,
  "message": "Response message",
  "data": {},
  "errors": []
}
```

## Error Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Internal Server Error

---

## 1. Authentication Endpoints

### 1.1 User Registration
**POST** `/auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "u123",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "goal": null
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Validation Errors (422):**
- Email already exists
- Invalid email format
- Password too short (min 6 characters)
- Name is required

---

### 1.2 User Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "u123",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "goal": "Lose 5kg"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Responses:**
- `401` - Invalid credentials
- `404` - User not found

**Special Cases:**
- Admin login: Email contains "admin" or equals "admin@gmail.com"
- Trainer login: Requires password validation

---

### 1.3 Logout
**POST** `/auth/logout`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 2. User Management Endpoints

### 2.1 Get All Users (Admin Only)
**GET** `/users`

**Headers:**
```
Authorization: Bearer {admin_token}
```

**Query Parameters:**
- `role` (optional): Filter by role (`user`, `trainer`, `admin`)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "u123",
        "name": "John Doe",
        "email": "john@example.com",
        "role": "user",
        "goal": "Lose 5kg",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

---

### 2.2 Get User by ID
**GET** `/users/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "u123",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "goal": "Lose 5kg"
    }
  }
}
```

---

### 2.3 Get User by Email
**GET** `/users/email/{email}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "u123",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    }
  }
}
```

---

### 2.4 Create Trainer (Admin Only)
**POST** `/users/trainers`

**Headers:**
```
Authorization: Bearer {admin_token}
```

**Request Body:**
```json
{
  "name": "Coach Amy",
  "email": "amy@example.com",
  "password": "trainer123"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Trainer created successfully",
  "data": {
    "trainer": {
      "id": "t456",
      "name": "Coach Amy",
      "email": "amy@example.com",
      "role": "trainer"
    }
  }
}
```

**Error Responses:**
- `422` - Email already exists
- `403` - Admin access required

---

### 2.5 Update User
**PUT** `/users/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "name": "John Updated",
  "goal": "Build muscle"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "user": {
      "id": "u123",
      "name": "John Updated",
      "email": "john@example.com",
      "role": "user",
      "goal": "Build muscle"
    }
  }
}
```

---

### 2.6 Delete User (Admin Only)
**DELETE** `/users/{id}`

**Headers:**
```
Authorization: Bearer {admin_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

---

## 3. Workout Endpoints

### 3.1 Get All Workouts
**GET** `/workouts`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "workouts": [
      {
        "id": "w1",
        "title": "Full Body Strength",
        "level": "Beginner",
        "durationMinutes": 45,
        "kcal": 350,
        "exercisesCount": 8,
        "tags": ["Strength", "Full Body"],
        "equipment": "Dumbbells, Bench",
        "imageUrl": "https://example.com/image.jpg",
        "exercises": [
          {
            "id": "e1",
            "title": "Push-ups",
            "difficulty": "Beginner",
            "sets": 3,
            "reps": "10-15",
            "restSeconds": 60,
            "targetMuscles": ["Chest", "Triceps"],
            "videoUrl": "https://example.com/video.mp4",
            "instructions": ["Keep back straight", "Lower slowly"]
          }
        ]
      }
    ]
  }
}
```

---

### 3.2 Get Workout by ID
**GET** `/workouts/{id}`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "workout": {
      "id": "w1",
      "title": "Full Body Strength",
      "level": "Beginner",
      "durationMinutes": 45,
      "kcal": 350,
      "exercisesCount": 8,
      "tags": ["Strength", "Full Body"],
      "equipment": "Dumbbells, Bench",
      "imageUrl": "https://example.com/image.jpg",
      "exercises": []
    }
  }
}
```

---

## 4. Workout Plan Endpoints

### 4.1 Get All Workout Plans
**GET** `/workout-plans`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `trainer_id` (optional): Filter by trainer
- `user_id` (optional): Filter by assigned user

**Response (200):**
```json
{
  "success": true,
  "data": {
    "plans": [
      {
        "id": "wp1",
        "trainerId": "t456",
        "name": "Beginner Full Body",
        "description": "A comprehensive full body workout plan",
        "difficulty": "beginner",
        "durationMinutes": 45,
        "kcal": 350,
        "exercisesCount": 8,
        "tags": ["Cardio", "Full Body"],
        "equipment": "Dumbbells",
        "imageUrl": "https://example.com/image.jpg",
        "workouts": [
          {
            "workoutId": "w1",
            "dayOfWeek": 1,
            "sets": 3,
            "reps": "10-12"
          }
        ]
      }
    ]
  }
}
```

---

### 4.2 Get Workout Plan by ID
**GET** `/workout-plans/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "plan": {
      "id": "wp1",
      "trainerId": "t456",
      "name": "Beginner Full Body",
      "description": "A comprehensive full body workout plan",
      "difficulty": "beginner",
      "workouts": [],
      "durationMinutes": 45,
      "kcal": 350,
      "exercisesCount": 8,
      "tags": ["Cardio", "Full Body"],
      "equipment": "Dumbbells",
      "imageUrl": "https://example.com/image.jpg"
    }
  }
}
```

---

### 4.3 Create Workout Plan (Trainer Only)
**POST** `/workout-plans`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "name": "Beginner Full Body",
  "description": "A comprehensive full body workout plan",
  "difficulty": "beginner",
  "durationMinutes": 45,
  "kcal": 350,
  "exercisesCount": 8,
  "tags": ["Cardio", "Full Body"],
  "equipment": "Dumbbells",
  "imageUrl": "data:image/jpeg;base64,/9j/4AAQ...",
  "workouts": [
    {
      "workoutId": "w1",
      "dayOfWeek": 1,
      "sets": 3,
      "reps": "10-12"
    }
  ]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Workout plan created successfully",
  "data": {
    "plan": {
      "id": "wp1",
      "trainerId": "t456",
      "name": "Beginner Full Body",
      "description": "A comprehensive full body workout plan",
      "difficulty": "beginner",
      "workouts": []
    }
  }
}
```

**Error Responses:**
- `403` - Trainer access required
- `422` - Validation errors

---

### 4.4 Update Workout Plan (Trainer/Admin Only)
**PUT** `/workout-plans/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "name": "Updated Plan Name",
  "description": "Updated description",
  "difficulty": "intermediate",
  "durationMinutes": 50,
  "kcal": 400,
  "exercisesCount": 10,
  "tags": ["Strength", "Cardio"],
  "equipment": "Dumbbells, Bench",
  "imageUrl": "https://example.com/new-image.jpg",
  "workouts": [
    {
      "workoutId": "w1",
      "dayOfWeek": 1,
      "sets": 4,
      "reps": "12-15"
    }
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Workout plan updated successfully",
  "data": {
    "plan": {
      "id": "wp1",
      "trainerId": "t456",
      "name": "Updated Plan Name",
      "description": "Updated description",
      "difficulty": "intermediate"
    }
  }
}
```

---

### 4.5 Partial Update Workout Plan (Trainer Only)
**PATCH** `/workout-plans/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "name": "New Name",
  "description": "New Description",
  "difficulty": "advanced"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Workout plan updated successfully",
  "data": {
    "plan": {}
  }
}
```

---

### 4.6 Delete Workout Plan (Trainer Only)
**DELETE** `/workout-plans/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Workout plan deleted successfully"
}
```

---

## 5. Nutrition Plan Endpoints

### 5.1 Get All Nutrition Plans
**GET** `/nutrition-plans`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `trainer_id` (optional): Filter by trainer
- `user_id` (optional): Filter by assigned user

**Response (200):**
```json
{
  "success": true,
  "data": {
    "plans": [
      {
        "id": "np1",
        "trainerId": "t456",
        "name": "High Protein Diet",
        "description": "Muscle gain, weight loss",
        "dailyCaloriesTarget": 2000,
        "meals": [
          {
            "name": "Grilled Chicken Breast",
            "timeOfDay": "08:00"
          }
        ]
      }
    ]
  }
}
```

---

### 5.2 Get Nutrition Plan by ID
**GET** `/nutrition-plans/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "plan": {
      "id": "np1",
      "trainerId": "t456",
      "name": "High Protein Diet",
      "description": "Muscle gain, weight loss",
      "dailyCaloriesTarget": 2000,
      "meals": [
        {
          "name": "Grilled Chicken Breast",
          "timeOfDay": "08:00"
        }
      ]
    }
  }
}
```

---

### 5.3 Create Nutrition Plan (Trainer Only)
**POST** `/nutrition-plans`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "name": "High Protein Diet",
  "description": "Muscle gain, weight loss",
  "dailyCaloriesTarget": 2000,
  "meals": [
    {
      "name": "Grilled Chicken Breast",
      "timeOfDay": "08:00"
    },
    {
      "name": "Brown Rice & Vegetables",
      "timeOfDay": "13:00"
    }
  ]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Nutrition plan created successfully",
  "data": {
    "plan": {
      "id": "np1",
      "trainerId": "t456",
      "name": "High Protein Diet",
      "description": "Muscle gain, weight loss",
      "dailyCaloriesTarget": 2000,
      "meals": []
    }
  }
}
```

**Error Responses:**
- `403` - Trainer access required
- `422` - Validation errors

---

### 5.4 Update Nutrition Plan (Trainer Only)
**PATCH** `/nutrition-plans/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "name": "Updated Diet Plan",
  "description": "Updated description",
  "dailyCaloriesTarget": 2200
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Nutrition plan updated successfully",
  "data": {
    "plan": {}
  }
}
```

---

### 5.5 Delete Nutrition Plan (Trainer Only)
**DELETE** `/nutrition-plans/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Nutrition plan deleted successfully"
}
```

---

## 6. Exercise Management Endpoints

### 6.1 Get All Exercises
**GET** `/exercises`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "exercises": [
      {
        "id": "e1",
        "title": "Push-ups",
        "difficulty": "Beginner",
        "sets": 3,
        "reps": "10-15",
        "restSeconds": 60,
        "targetMuscles": ["Chest", "Triceps"],
        "videoUrl": "https://example.com/video.mp4",
        "instructions": ["Keep back straight", "Lower slowly"]
      }
    ]
  }
}
```

---

### 6.2 Get Exercise by ID
**GET** `/exercises/{id}`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "exercise": {
      "id": "e1",
      "title": "Push-ups",
      "difficulty": "Beginner",
      "sets": 3,
      "reps": "10-15",
      "restSeconds": 60,
      "targetMuscles": ["Chest", "Triceps"],
      "videoUrl": "https://example.com/video.mp4",
      "instructions": ["Keep back straight", "Lower slowly"]
    }
  }
}
```

---

### 6.3 Create Exercise (Trainer/Admin Only)
**POST** `/exercises`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "title": "Squats",
  "difficulty": "Intermediate",
  "sets": 4,
  "reps": "12-15",
  "restSeconds": 90,
  "targetMuscles": ["Quadriceps", "Glutes"],
  "videoUrl": "https://example.com/squats.mp4",
  "instructions": ["Keep knees aligned", "Go below parallel"]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Exercise created successfully",
  "data": {
    "exercise": {
      "id": "e2",
      "title": "Squats",
      "difficulty": "Intermediate",
      "sets": 4,
      "reps": "12-15",
      "restSeconds": 90,
      "targetMuscles": ["Quadriceps", "Glutes"],
      "videoUrl": "https://example.com/squats.mp4",
      "instructions": ["Keep knees aligned", "Go below parallel"]
    }
  }
}
```

**Error Responses:**
- `403` - Trainer/Admin access required
- `422` - Exercise with this ID already exists

---

### 6.4 Update Exercise (Trainer/Admin Only)
**PUT** `/exercises/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "title": "Updated Squats",
  "difficulty": "Advanced",
  "sets": 5,
  "reps": "15-20",
  "restSeconds": 120,
  "targetMuscles": ["Quadriceps", "Glutes", "Hamstrings"],
  "videoUrl": "https://example.com/updated-squats.mp4",
  "instructions": ["Keep knees aligned", "Go below parallel", "Drive through heels"]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Exercise updated successfully",
  "data": {
    "exercise": {}
  }
}
```

---

### 6.5 Delete Exercise (Trainer/Admin Only)
**DELETE** `/exercises/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Exercise deleted successfully"
}
```

---

## 7. Challenge Endpoints

### 7.1 Get All Challenges
**GET** `/challenges`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "challenges": [
      {
        "id": "c1",
        "title": "30-Day Fitness Challenge",
        "description": "Complete 30 days of workouts",
        "startDate": "2024-01-01",
        "endDate": "2024-01-30",
        "createdBy": "t456",
        "participants": [
          {
            "userId": "u123",
            "progress": 75
          }
        ]
      }
    ]
  }
}
```

---

### 7.2 Get Challenge by ID
**GET** `/challenges/{id}`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "challenge": {
      "id": "c1",
      "title": "30-Day Fitness Challenge",
      "description": "Complete 30 days of workouts",
      "startDate": "2024-01-01",
      "endDate": "2024-01-30",
      "createdBy": "t456",
      "participants": [
        {
          "userId": "u123",
          "progress": 75
        }
      ]
    }
  }
}
```

---

### 7.3 Create Challenge (Trainer/Admin Only)
**POST** `/challenges`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "title": "30-Day Fitness Challenge",
  "description": "Complete 30 days of workouts",
  "startDate": "2024-01-01",
  "endDate": "2024-01-30",
  "participants": []
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Challenge created successfully",
  "data": {
    "challenge": {
      "id": "c1",
      "title": "30-Day Fitness Challenge",
      "description": "Complete 30 days of workouts",
      "startDate": "2024-01-01",
      "endDate": "2024-01-30",
      "createdBy": "t456",
      "participants": []
    }
  }
}
```

**Error Responses:**
- `403` - Trainer/Admin access required
- `422` - Validation errors

---

### 7.4 Update Challenge (Trainer/Admin Only)
**PATCH** `/challenges/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "title": "Updated Challenge Title",
  "description": "Updated description",
  "startDate": "2024-02-01",
  "endDate": "2024-02-28"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Challenge updated successfully",
  "data": {
    "challenge": {}
  }
}
```

---

### 7.5 Delete Challenge (Trainer/Admin Only)
**DELETE** `/challenges/{id}`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Challenge deleted successfully"
}
```

---

## 8. Progress Log Endpoints

### 8.1 Get Progress Logs for User
**GET** `/progress-logs`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `user_id` (required): User ID to fetch logs for

**Response (200):**
```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": "pl1",
        "userId": "u123",
        "date": "2024-01-15",
        "weightKg": 75.5,
        "caloriesBurned": 450,
        "notes": "Great workout today!"
      }
    ]
  }
}
```

---

### 8.2 Create/Update Progress Log
**POST** `/progress-logs`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "userId": "u123",
  "date": "2024-01-15",
  "weightKg": 75.5,
  "caloriesBurned": 450,
  "notes": "Great workout today!"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Progress log saved successfully",
  "data": {
    "log": {
      "id": "pl1",
      "userId": "u123",
      "date": "2024-01-15",
      "weightKg": 75.5,
      "caloriesBurned": 450,
      "notes": "Great workout today!"
    }
  }
}
```

**Note:** If a log already exists for the same user and date, it will be updated instead of creating a new one.

---

## 9. Trainer Profile Endpoints

### 9.1 Get Trainer Profile
**GET** `/trainers/profile`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "profile": {
      "name": "Coach Amy",
      "title": "Certified Personal Trainer",
      "bio": "Passionate fitness coach specializing in strength training and nutrition.",
      "email": "amy@example.com",
      "phone": "+1 (555) 123-4567",
      "location": "Los Angeles, CA",
      "clients": 24,
      "plans": 33,
      "rating": 4.9,
      "avatarUrl": "https://example.com/avatar.jpg"
    }
  }
}
```

---

### 9.2 Update Trainer Profile
**PUT** `/trainers/profile`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "name": "Coach Amy Updated",
  "title": "Senior Personal Trainer",
  "bio": "Updated bio",
  "phone": "+1 (555) 999-8888",
  "location": "New York, NY",
  "avatarUrl": "https://example.com/new-avatar.jpg"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "profile": {}
  }
}
```

---

## 10. Favorite Exercises Endpoints

### 10.1 Get User's Favorite Exercises
**GET** `/users/{userId}/favorites/exercises`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "exerciseIds": ["e1", "e2", "e3"]
  }
}
```

---

### 10.2 Toggle Favorite Exercise
**POST** `/users/{userId}/favorites/exercises/{exerciseId}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Favorite toggled successfully",
  "data": {
    "isFavorite": true
  }
}
```

**Note:** This endpoint toggles the favorite status. If the exercise is already favorited, it will be removed. If not favorited, it will be added.

---

## 11. User Plan Assignments

### 11.1 Assign Plan to User
**POST** `/plan-assignments`

**Headers:**
```
Authorization: Bearer {trainer_token}
```

**Request Body:**
```json
{
  "userId": "u123",
  "planId": "wp1",
  "planType": "workout",
  "assignedBy": "t456",
  "startDate": "2024-01-15"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Plan assigned successfully",
  "data": {
    "assignment": {
      "id": "pa1",
      "userId": "u123",
      "planId": "wp1",
      "planType": "workout",
      "assignedBy": "t456",
      "startDate": "2024-01-15"
    }
  }
}
```

---

### 11.2 Get User's Assigned Plans
**GET** `/plan-assignments`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `user_id` (required): User ID
- `plan_type` (optional): Filter by type (`workout` or `nutrition`)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "assignments": [
      {
        "id": "pa1",
        "userId": "u123",
        "planId": "wp1",
        "planType": "workout",
        "assignedBy": "t456",
        "startDate": "2024-01-15"
      }
    ]
  }
}
```

---

## Data Models

### User Model
```json
{
  "id": "string (UUID)",
  "name": "string (required)",
  "email": "string (required, unique, email format)",
  "password": "string (hashed, required for registration/login)",
  "role": "string (enum: 'user', 'trainer', 'admin')",
  "goal": "string (optional)",
  "phone": "string (optional)",
  "age": "integer (optional)",
  "gender": "string (optional)",
  "height": "float (optional, in cm)",
  "weight": "float (optional, in kg)",
  "fitness_goal": "string (optional)",
  "created_at": "datetime (ISO 8601)"
}
```

### Workout Plan Model
```json
{
  "id": "string (UUID)",
  "trainerId": "string (required, UUID)",
  "name": "string (required)",
  "description": "string (required)",
  "difficulty": "string (enum: 'beginner', 'intermediate', 'advanced')",
  "durationMinutes": "integer (optional)",
  "kcal": "integer (optional)",
  "exercisesCount": "integer (optional)",
  "tags": "array of strings (optional)",
  "equipment": "string (optional)",
  "imageUrl": "string (optional, base64 or URL)",
  "workouts": "array of PlanWorkoutModel",
  "created_at": "datetime (ISO 8601)"
}
```

### Plan Workout Model
```json
{
  "workoutId": "string (required, UUID)",
  "dayOfWeek": "integer (required, 1-7, Monday=1)",
  "sets": "integer (required)",
  "reps": "string (required, e.g., '10-12')"
}
```

### Nutrition Plan Model
```json
{
  "id": "string (UUID)",
  "trainerId": "string (required, UUID)",
  "name": "string (required)",
  "description": "string (required)",
  "dailyCaloriesTarget": "integer (required)",
  "meals": "array of MealModel",
  "created_at": "datetime (ISO 8601)"
}
```

### Meal Model
```json
{
  "name": "string (required)",
  "timeOfDay": "string (required, format: 'HH:mm')"
}
```

### Exercise Model
```json
{
  "id": "string (UUID)",
  "title": "string (required)",
  "difficulty": "string (enum: 'Beginner', 'Intermediate', 'Advanced')",
  "sets": "integer (required)",
  "reps": "string (required)",
  "restSeconds": "integer (required)",
  "targetMuscles": "array of strings (required)",
  "videoUrl": "string (optional)",
  "instructions": "array of strings (optional)",
  "created_at": "datetime (ISO 8601)"
}
```

### Challenge Model
```json
{
  "id": "string (UUID)",
  "title": "string (required)",
  "description": "string (required)",
  "startDate": "string (required, format: 'YYYY-MM-DD')",
  "endDate": "string (required, format: 'YYYY-MM-DD')",
  "createdBy": "string (optional, UUID, trainer ID)",
  "participants": "array of ChallengeUserModel",
  "created_at": "datetime (ISO 8601)"
}
```

### Challenge User Model
```json
{
  "userId": "string (required, UUID)",
  "progress": "integer (required, 0-100, percentage)"
}
```

### Progress Log Model
```json
{
  "id": "string (UUID)",
  "userId": "string (required, UUID)",
  "date": "string (required, format: 'YYYY-MM-DD')",
  "weightKg": "float (optional)",
  "caloriesBurned": "integer (optional)",
  "bodyFatPercentage": "float (optional)",
  "muscleMass": "float (optional)",
  "notes": "string (optional)"
}
```

### Trainer Profile Model
```json
{
  "name": "string (required)",
  "title": "string (required)",
  "bio": "string (required)",
  "email": "string (required)",
  "phone": "string (required)",
  "location": "string (required)",
  "clients": "integer (required)",
  "plans": "integer (required)",
  "rating": "float (required, 0.0-5.0)",
  "avatarUrl": "string (optional)"
}
```

---

## Authentication & Authorization

### Token Format
JWT (JSON Web Token) with the following payload:
```json
{
  "user_id": "u123",
  "email": "user@example.com",
  "role": "user",
  "iat": 1234567890,
  "exp": 1234571490
}
```

### Role-Based Access Control

- **User**: Can access their own data, view plans assigned to them, create progress logs
- **Trainer**: Can create/update/delete workout plans, nutrition plans, exercises, challenges. Can view their own profile and assigned users.
- **Admin**: Full access to all endpoints, can manage users (create trainers, delete users)

### Protected Endpoints
All endpoints except `/auth/register` and `/auth/login` require authentication.

---

## Error Handling

### Standard Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": [
    {
      "field": "email",
      "message": "Email already exists"
    }
  ]
}
```

### Common Error Messages
- `"Email already exists"` - Email is already registered
- `"Invalid credentials"` - Wrong email/password
- `"User not found"` - User doesn't exist
- `"Unauthorized"` - Missing or invalid token
- `"Forbidden"` - Insufficient permissions
- `"Validation failed"` - Request validation errors
- `"Resource not found"` - Requested resource doesn't exist

---

## Rate Limiting
- **Public endpoints**: 100 requests per minute
- **Authenticated endpoints**: 1000 requests per minute
- **Admin endpoints**: 2000 requests per minute

---

## Pagination
For list endpoints, use query parameters:
- `page` (default: 1)
- `limit` (default: 20, max: 100)

**Response includes:**
```json
{
  "success": true,
  "data": {
    "items": [],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

---

## File Uploads

### Image Upload
For workout plan images, use base64 encoding in the request body:
```json
{
  "imageUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}
```

Alternatively, use multipart/form-data:
- **Endpoint**: `POST /upload/image`
- **Field**: `image`
- **Response**: Returns URL to uploaded image

---

## Database Schema Recommendations

### Tables
1. `users` - User accounts
2. `workout_plans` - Workout plans
3. `plan_workouts` - Workout plan schedule (many-to-many)
4. `nutrition_plans` - Nutrition plans
5. `nutrition_plan_meals` - Nutrition plan meals
6. `exercises` - Exercise library
7. `workouts` - Predefined workouts
8. `challenges` - Community challenges
9. `challenge_users` - Challenge participants
10. `progress_logs` - User progress tracking
11. `user_plan_assignments` - Plan assignments to users
12. `favorite_exercises` - User favorite exercises
13. `trainer_profiles` - Trainer profile information

---

## Implementation Notes

1. **Password Hashing**: Use bcrypt or Argon2 for password hashing
2. **Token Expiry**: JWT tokens should expire after 24 hours
3. **Email Validation**: Use proper email regex validation
4. **Date Formats**: Use ISO 8601 format (YYYY-MM-DD) for dates
5. **Image Storage**: Consider using cloud storage (AWS S3, Cloudinary) for images
6. **Database**: Use UUIDs for primary keys
7. **Soft Deletes**: Consider implementing soft deletes for important data
8. **Logging**: Log all API requests for debugging and security
9. **CORS**: Configure CORS properly for mobile app access
10. **HTTPS**: Always use HTTPS in production

---

## Testing

### Test Endpoints
- Base URL: `https://your-domain.com/api/v1`
- Test Admin: `admin@gmail.com` / `admin123`
- Test Trainer: Create via admin panel
- Test User: Register new account

### Sample cURL Commands

**Register:**
```bash
curl -X POST https://your-domain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'
```

**Login:**
```bash
curl -X POST https://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**Get Workouts:**
```bash
curl -X GET https://your-domain.com/api/v1/workouts \
  -H "Authorization: Bearer {token}"
```

---

## Version History
- **v1.0** - Initial API documentation (2024-01-15)

---

## Support
For API support, contact: api-support@activex-gym.com

