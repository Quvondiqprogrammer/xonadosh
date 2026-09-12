import '../api/auth_api_client.dart';
import '../api/session_manager.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({
    required this._api,
    required this._session,
    this._onSessionCleared,
  });

  final AuthApiClient _api;
  final SessionManager _session;
  final Future<void> Function()? _onSessionCleared;

  SessionManager get session => _session;

  bool _isAuthRejected(Map<String, dynamic> res) {
    final status = res['status'];
    return status == 401 || status == 403;
  }

  Future<bool> hasValidSession() async {
    var token = await _session.getApiToken();
    if (token == null || token.isEmpty) {
      final refreshed = await _session.getRefreshToken();
      if (refreshed == null || refreshed.isEmpty) return false;
      final res = await _api.refresh(refreshed);
      if (res['ok'] == true && res['token'] is String) {
        await _session.saveApiTokens(
          token: (res['token'] as String).trim(),
          refreshToken: res['refresh_token'] as String?,
          expiresAt: (res['expires_at'] as num?)?.toInt(),
        );
      } else if (_isAuthRejected(res)) {
        return false;
      } else {
        // Network / 5xx — keep local session instead of kicking the user out.
        return _session.isAuthenticated;
      }
    }
    final me = await _api.me();
    if (me['ok'] == true) {
      final user = AuthApiClient.userFromResponse(me);
      if (user != null && user.username.isNotEmpty) {
        await _session.saveUser(user);
      }
      return true;
    }
    if (_isAuthRejected(me)) return false;
    return _session.isAuthenticated;
  }

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final res = await _api.login(login: login, password: password);
    if (res['ok'] == true) {
      await _persistAuth(res);
    }
    return res;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String phone,
    required String password,
  }) async {
    final res = await _api.register(
      fullName: fullName,
      username: username,
      phone: phone,
      password: password,
    );
    if (res['ok'] == true) {
      await _persistAuth(res);
    }
    return res;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _session.clearSession();
    await _onSessionCleared?.call();
  }

  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    final res = await _api.deleteAccount(password: password);
    if (res['ok'] == true) {
      await _session.clearSession();
      await _onSessionCleared?.call();
    }
    return res;
  }

  Future<UserModel?> me() async {
    final res = await _api.me();
    if (res['ok'] == true) {
      return AuthApiClient.userFromResponse(res);
    }
    return null;
  }

  Future<void> _persistAuth(Map<String, dynamic> res) async {
    final username = (res['username'] ?? res['user']?['username'] ?? '').toString();
    final token = (res['token'] ?? '').toString();
    if (username.isEmpty || token.isEmpty) return;
    await _session.saveSession(
      username: username,
      token: token,
      refreshToken: res['refresh_token'] as String?,
      expiresAt: (res['expires_at'] as num?)?.toInt(),
      user: AuthApiClient.userFromResponse(res),
    );
  }
}
