import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'workout_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Server address and login token saved on the phone.
  await ApiClient.instance.loadSession();
  final loggedIn = ApiClient.instance.isLoggedIn;
  if (loggedIn) {
    // Show the local copy instantly, then sync with the server in the background.
    await WorkoutStore.instance.loadCache();
    unawaited(WorkoutStore.instance.refresh());
  }

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

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, this.loggedIn = false});

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
          home: loggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
