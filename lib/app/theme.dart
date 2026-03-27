import 'package:flutter/material.dart';

ThemeData buildTeenpleTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D7CFF),
      brightness: Brightness.light,
    ),
    fontFamily: 'Pretendard',
  );
}