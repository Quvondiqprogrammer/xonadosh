import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Token + preference session for XonaDosh.
class SessionManager {
  SessionManager({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            FlutterSecureStorage(
              iOptions: const IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              webOptions: kIsWeb
                  ? const WebOptions(
                      dbName: 'xonadosh_secure',
                      publicKey: 'xonadosh_web_v1',
                    )
                  : const WebOptions(),
            );

  final FlutterSecureStorage _storage;

  static const _kToken = 'xd_access_token';
  static const _kRefresh = 'xd_refresh_token';
  static const _kExpires = 'xd_token_expires';
  static const _kUsername = 'xd_username';
  static const _kUserJson = 'xd_user_json';
  static const _kLocale = 'xd_locale';
  static const _kTheme = 'xd_theme';

  String? _username;
  UserModel? _user;
  String _languageCode = 'uz';
  ThemeModePref _themeMode = ThemeModePref.system;

  String? get userId => _username;
  String? get username => _username;
  UserModel? get user => _user;
  String get languageCode => _languageCode;
  ThemeModePref get themeModePref => _themeMode;
  bool get isAuthenticated => _username != null && _username!.isNotEmpty;

  Future<void> load() async {
    _username = await _storage.read(key: _kUsername);
    final userRaw = await _storage.read(key: _kUserJson);
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(userRaw);
        if (decoded is Map) {
          _user = UserModel.fromJson(Map<String, dynamic>.from(decoded));
          if ((_username == null || _username!.isEmpty) &&
              _user!.username.isNotEmpty) {
            _username = _user!.username;
          }
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_kLocale) ?? 'uz';
    final themeRaw = prefs.getString(_kTheme) ?? 'system';
    _themeMode = ThemeModePref.values.firstWhere(
      (e) => e.name == themeRaw,
      orElse: () => ThemeModePref.system,
    );
  }

  Future<String?> getApiToken({bool allowExpired = false}) async {
    final token = await _storage.read(key: _kToken);
    if (token == null || token.isEmpty) return null;
    if (allowExpired) return token;
    final expRaw = await _storage.read(key: _kExpires);
    if (expRaw != null) {
      final exp = int.tryParse(expRaw);
      if (exp != null) {
        // Backend stores expires_at in milliseconds since epoch.
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final expMs = exp > 1000000000000 ? exp : exp * 1000;
        if (nowMs >= expMs - 30000) return null;
      }
    }
    return token;
  }

  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> saveApiTokens({
    required String token,
    String? refreshToken,
    int? expiresAt,
  }) async {
    await _storage.write(key: _kToken, value: token.trim());
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _storage.write(key: _kRefresh, value: refreshToken.trim());
    }
    if (expiresAt != null) {
      await _storage.write(key: _kExpires, value: '$expiresAt');
    }
  }

  Future<void> saveSession({
    required String username,
    required String token,
    String? refreshToken,
    int? expiresAt,
    UserModel? user,
  }) async {
    _username = username;
    _user = user;
    await _storage.write(key: _kUsername, value: username);
    if (user != null) {
      await _storage.write(key: _kUserJson, value: jsonEncode(user.toJson()));
    }
    await saveApiTokens(
      token: token,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Future<void> saveUser(UserModel user) async {
    _user = user;
    if (user.username.isNotEmpty) {
      _username = user.username;
      await _storage.write(key: _kUsername, value: user.username);
    }
    await _storage.write(key: _kUserJson, value: jsonEncode(user.toJson()));
  }

  Future<void> clearApiToken() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpires);
  }

  Future<void> clearSession() async {
    _username = null;
    _user = null;
    await clearApiToken();
    await _storage.delete(key: _kUsername);
    await _storage.delete(key: _kUserJson);
    // User-scoped prefs must not leak to the next account on this device.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('xonadosh_my_saved_profile');
      await prefs.remove('xonadosh_anketa_draft_v2');
    } catch (_) {}
  }

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, code);
  }

  Future<void> setThemeModePref(ThemeModePref mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode.name);
  }
}

enum ThemeModePref { light, dark, system }
