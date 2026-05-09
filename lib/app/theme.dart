import 'package:flutter/material.dart';

// 모든 페이지 전환에 적용할 좌우 슬라이드 트랜지션
const _transitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

ThemeData buildTeenpleLightTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFECF6FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
    ),
    pageTransitionsTheme: _transitions,
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
    pageTransitionsTheme: _transitions,
  );
}

// kept for backwards compat — returns light theme
ThemeData buildTeenpleTheme() => buildTeenpleLightTheme();
