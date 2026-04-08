import 'package:flutter/material.dart';

ThemeData buildTeenpleTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFECF6FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
    ),
  );
}