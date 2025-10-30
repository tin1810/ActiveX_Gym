# ActiveX Gym App

A modern Flutter fitness application with a beautiful and intuitive user interface.

## Features

- **Home Dashboard**: Clean and modern home screen with workout progress tracking
- **Workout Progress**: Visual progress indicators showing exercise completion
- **Today's Workouts**: Featured workout cards with duration and calorie information
- **Popular Exercises**: Quick access to different exercise categories
- **Bottom Navigation**: Easy navigation between Home, Workouts, Progress, and Profile

## Screenshots

The app features a clean, modern design with:
- Personalized greeting with user profile
- Circular progress indicators for workout tracking
- Dark-themed workout cards with exercise details
- Colorful exercise category cards
- Intuitive bottom navigation

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point and navigation
├── screens/
│   └── home_page.dart       # Main home screen
└── widgets/
    ├── header_section.dart           # User greeting and profile
    ├── workout_progress_card.dart    # Progress tracking widget
    ├── today_workouts_card.dart      # Featured workout display
    └── popular_exercises_section.dart # Exercise categories
```

## Dependencies

- `flutter`: Flutter SDK
- `cupertino_icons`: iOS-style icons
- `google_fonts`: Custom font support
- `cached_network_image`: Optimized image loading

## Testing

Run the test suite:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
