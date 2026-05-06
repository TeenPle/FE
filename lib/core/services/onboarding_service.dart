import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _keySchoolDone = 'onboarding_school_done';
  static const _keyTimetableDone = 'onboarding_timetable_done';

  Future<bool> isFirstSchoolVisit() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keySchoolDone) ?? false);
  }

  Future<void> markSchoolVisited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySchoolDone, true);
  }

  Future<bool> isFirstTimetableVisit() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyTimetableDone) ?? false);
  }

  Future<void> markTimetableVisited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTimetableDone, true);
  }

  /// 디버그 빌드에서만 사용. 온보딩 완료 상태를 초기화한다.
  Future<void> resetForDebug() async {
    assert(kDebugMode, 'resetForDebug must only be called in debug mode');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySchoolDone);
  }

  Future<void> resetTimetableForDebug() async {
    assert(kDebugMode, 'resetTimetableForDebug must only be called in debug mode');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTimetableDone);
  }
}
