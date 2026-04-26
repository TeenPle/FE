import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _autoLoginKey = 'auto_login';
  static const _userRoleKey = 'user_role';
  static const _schoolIdKey = 'school_id';
  static const _classRoomKey = 'class_room';

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveAutoLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, value);
  }

  Future<bool> getAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLoginKey) ?? false;
  }

  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> saveSchoolId(int schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_schoolIdKey, schoolId);
  }

  Future<int?> getSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_schoolIdKey);
  }

  Future<void> saveClassRoom(String classRoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_classRoomKey, classRoom);
  }

  Future<String?> getClassRoom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_classRoomKey);
  }

  /// 토큰·자동로그인 플래그·역할·학교 ID 모두 삭제
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_autoLoginKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_schoolIdKey);
    await prefs.remove(_classRoomKey);
  }
}
