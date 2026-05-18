import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ameko_app/core/utils/app_logger.dart';

/// Handles all persistent storage: secure tokens + cached user data.
class StorageService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'cached_user';

  final FlutterSecureStorage _secureStorage;
  late SharedPreferences _prefs;

  StorageService(this._secureStorage);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    appLogger.i('StorageService initialized');
  }

  // ─── Token Management (Secure Storage) ──────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    appLogger.d('Token saved');
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    appLogger.d('Tokens cleared');
  }

  // ─── User Cache (SharedPreferences) ─────────────────────────────────────────

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, jsonEncode(user));
    appLogger.d('User cached');
  }

  Map<String, dynamic>? getUser() {
    final json = _prefs.getString(_userKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  // ─── Full Logout ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    appLogger.i('All storage cleared (logout)');
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
