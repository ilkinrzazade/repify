import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'login_screen.dart';
import 'workout_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved workouts before the first screen is shown.
  await WorkoutStore.instance.load();

  // Remember the dark mode choice between app launches.
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dark_mode') ?? false) {
      themeModeNotifier.value = ThemeMode.dark;
    }
    themeModeNotifier.addListener(() {
      prefs.setBool('dark_mode', themeModeNotifier.value == ThemeMode.dark);
    });
  } catch (e) {
    debugPrint('Could not load settings: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Repify',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const LoginScreen(),
        );
      },
    );
  }
}
