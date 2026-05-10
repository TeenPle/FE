import 'package:flutter/services.dart';

abstract class AppHaptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void selection() => HapticFeedback.selectionClick();
}
