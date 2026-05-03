import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _autoLoginKey = 'auto_login';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _schoolIdKey = 'school_id';
  static const _classRoomKey = 'class_room';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveAutoLogin(bool value) =>
      _storage.write(key: _autoLoginKey, value: value.toString());

  Future<bool> getAutoLogin() async {
    final val = await _storage.read(key: _autoLoginKey);
    return val == 'true';
  }

  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> saveSchoolId(int schoolId) =>
      _storage.write(key: _schoolIdKey, value: schoolId.toString());

  Future<int?> getSchoolId() async {
    final val = await _storage.read(key: _schoolIdKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> saveClassRoom(String classRoom) =>
      _storage.write(key: _classRoomKey, value: classRoom);

  Future<String?> getClassRoom() => _storage.read(key: _classRoomKey);

  Future<void> clearAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
  }
}
