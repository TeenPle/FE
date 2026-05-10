import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
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

  Future<void> saveUserId(int userId) =>
      _storage.write(key: _userIdKey, value: userId.toString());

  Future<int?> getUserId() async {
    final val = await _storage.read(key: _userIdKey);
    if (val != null) return int.tryParse(val);
    // 기존 SharedPreferences에 저장된 값 마이그레이션 (1회 수행 후 제거)
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getInt(_userIdKey);
    if (legacy != null) {
      await saveUserId(legacy);
      await prefs.remove(_userIdKey);
    }
    return legacy;
  }

  Future<void> saveUserRole(String role) =>
      _storage.write(key: _userRoleKey, value: role);

  Future<String?> getUserRole() async {
    final val = await _storage.read(key: _userRoleKey);
    if (val != null) return val;
    // 기존 SharedPreferences에 저장된 값 마이그레이션 (1회 수행 후 제거)
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_userRoleKey);
    if (legacy != null) {
      await saveUserRole(legacy);
      await prefs.remove(_userRoleKey);
    }
    return legacy;
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
    // 레거시 SharedPreferences 잔여 데이터 정리
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
  }
}
