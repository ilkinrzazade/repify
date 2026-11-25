import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'coach_chat.dart';
import 'health_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'workout_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Light status bar icons on the dark background.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Server address and login token saved on the phone.
  await ApiClient.instance.loadSession();
  final loggedIn = ApiClient.instance.isLoggedIn;
  if (loggedIn) {
    // Show the local copy instantly, then sync with the server in the background.
    await WorkoutStore.instance.loadCache();
    unawaited(WorkoutStore.instance.refresh());
  }

  // Google Health Connect (steps, heart rate, calories) loads in the background.
  // The AI coach gets today's totals when the user asks something.
  unawaited(HealthService.instance.init());
  CoachConversation.healthProvider = () {
    final health = HealthService.instance;
    return health.isConnected ? health.today.toCoachJson() : null;
  };

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, this.loggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repify',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: repifyTheme,
      darkTheme: repifyTheme,
      home: SplashScreen(
        next: loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
