import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _autoLoginKey = 'auto_login';
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

  Future<void> saveUserRole(String role) =>
      _storage.write(key: _userRoleKey, value: role);

  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  Future<void> saveSchoolId(int schoolId) =>
      _storage.write(key: _schoolIdKey, value: schoolId.toString());

  Future<int?> getSchoolId() async {
    final val = await _storage.read(key: _schoolIdKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> saveClassRoom(String classRoom) =>
      _storage.write(key: _classRoomKey, value: classRoom);

  Future<String?> getClassRoom() => _storage.read(key: _classRoomKey);

  Future<void> clearAll() => _storage.deleteAll();
}
