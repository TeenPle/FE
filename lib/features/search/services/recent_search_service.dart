import 'package:shared_preferences/shared_preferences.dart';

/// 최근 검색어를 로컬에 저장하는 서비스
class RecentSearchService {
  static const String _storageKey = 'recent_search_keywords';
  static const int _maxCount = 10;

  /// 저장된 최근 검색어 목록을 불러옴
  Future<List<String>> getRecentKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? [];
  }

  /// 검색어를 최근 검색어 목록 맨 앞에 저장
  Future<List<String>> saveKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return getRecentKeywords();
    }

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? [];

    current.removeWhere((item) => item == trimmed);
    current.insert(0, trimmed);

    final limited = current.take(_maxCount).toList();
    await prefs.setStringList(_storageKey, limited);

    return limited;
  }

  /// 특정 최근 검색어를 삭제
  Future<List<String>> removeKeyword(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? [];

    current.removeWhere((item) => item == keyword);
    await prefs.setStringList(_storageKey, current);

    return current;
  }

  /// 최근 검색어 전체를 삭제
  Future<List<String>> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    return [];
  }
}