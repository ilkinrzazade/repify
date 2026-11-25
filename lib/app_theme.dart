import 'package:flutter/material.dart';

/// Repify design system: Charcoal + Neon Lime.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0E0F11);
  static const Color surface = Color(0xFF16171A);
  static const Color card = Color(0xFF1D1F23);
  static const Color cardHigh = Color(0xFF26292E);
  static const Color border = Color(0xFF2E3137);

  static const Color lime = Color(0xFFC8FF2E);
  static const Color limeDark = Color(0xFF9FCC1F);
  static const Color onLime = Color(0xFF0E0F11);

  static const Color text = Color(0xFFF3F4EF);
  static const Color muted = Color(0xFF8D9199);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFB547);
  static const Color gold = Color(0xFFFFC83D);
}

/// Kept for compatibility: the app now always uses the Repify dark theme.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.dark);

final ThemeData repifyTheme = _buildTheme();

final ThemeData lightTheme = repifyTheme;
final ThemeData darkTheme = repifyTheme;

ThemeData _buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.lime,
    onPrimary: AppColors.onLime,
    secondary: AppColors.lime,
    onSecondary: AppColors.onLime,
    secondaryContainer: AppColors.lime,
    onSecondaryContainer: AppColors.onLime,
    surface: AppColors.card,
    onSurface: AppColors.text,
    surfaceContainerHighest: AppColors.cardHigh,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    error: AppColors.danger,
  );

  final rounded16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.onLime,
        disabledBackgroundColor: AppColors.cardHigh,
        disabledForegroundColor: AppColors.muted,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: rounded16,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: rounded16,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lime,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardHigh,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      helperStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.cardHigh,
      selectedColor: AppColors.lime,
      checkmarkColor: AppColors.onLime,
      labelStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(color: AppColors.onLime, fontWeight: FontWeight.w700),
      side: BorderSide(color: AppColors.border),
      shape: StadiumBorder(),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.lime,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.cardHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
      actionTextColor: AppColors.lime,
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.surface),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.muted),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.lime),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.onLime : AppColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.lime : AppColors.cardHigh,
      ),
    ),
  );
}

/// Neon card used for highlights (lime background, dark text).
BoxDecoration limeCardDecoration({double radius = 24}) => BoxDecoration(
      color: AppColors.lime,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.lime.withAlpha(60),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );

/// Small rounded square with a lime icon, used on tiles and cards.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool filled;

  const IconBadge(this.icon, {super.key, this.size = 40, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? AppColors.lime : AppColors.lime.withAlpha(28),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.52,
        color: filled ? AppColors.onLime : AppColors.lime,
      ),
    );
  }
}

/// "12,360" -> "12.4k"
String compactNumber(num value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.round().toString();
}
