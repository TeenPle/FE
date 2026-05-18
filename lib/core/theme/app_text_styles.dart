import 'package:flutter/material.dart';

/// TeenPle typography tokens.
///
/// Keep text styles on this scale unless a component has a fixed-size UI need
/// such as badges, counters, or compact timetable cells.
class AppTextStyles {
  AppTextStyles._();

  // App bars and large sheet/dialog headers.
  static const titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  // Section headers and important card group titles.
  static const titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0,
  );

  // List item titles, post titles, and emphasized compact text.
  static const titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0,
  );

  // Post bodies and long explanatory text.
  static const bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.65,
  );

  // General body text, form text, and chat messages.
  static const bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // Secondary descriptions and helper text.
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  // Buttons, emphasized labels, and selected states.
  static const labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  // Chips, tags, and compact buttons.
  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Badges, navigation labels, and small chips.
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Dates and secondary metrics such as views and likes.
  static const captionLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Timestamps and tiny metadata.
  static const captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Large numbers and primary highlights.
  static const displayLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  // Medium numbers and key values.
  static const displaySmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
  );
}
