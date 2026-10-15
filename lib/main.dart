import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'login_screen.dart';

void main() {
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