import 'package:flutter/material.dart';

ThemeData buildTeenpleLightTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFECF6FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
    ),
  );
}

ThemeData buildTeenpleDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E1E1E),
      surfaceContainer: const Color(0xFF1E1E1E),
    ),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2C2C2C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Color(0xFFEEEEEE),
      elevation: 0,
    ),
  );
}

// kept for backwards compat — returns light theme
ThemeData buildTeenpleTheme() => buildTeenpleLightTheme();
