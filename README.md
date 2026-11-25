# Repify

A mobile app for logging gym workouts and tracking progress.
Built with Flutter for the Mobile Application Development coursework at KTU.

## Features

- Live workout session with a timer, exercise logging, and total weight lifted
- Workout history with details (duration, exercises, volume)
- Progress line chart per exercise
- Manual workout entry
- Profile, settings, and dark mode
- Login screen with input validation

## Tech stack

- Flutter / Dart
- fl_chart (charts)
- Planned: Django REST Framework + PostgreSQL backend

## How to build and run

Requirements: Flutter SDK, Android Studio (Android SDK), an emulator or a real Android device.

```bash
git clone https://github.com/ilkinrzazade/repify.git
cd repify
flutter pub get
flutter run
```

Build an APK:

```bash
flutter build apk --release
```

The APK is created at `build/app/outputs/flutter-apk/app-release.apk`.

## Project status

- Iteration 1 (UI): done
- Iteration 2 (backend): planned
- Iteration 3 (testing and release): planned

Data is currently stored in memory (sample data, resets on restart).

## Author

Ilkin Rzazade
