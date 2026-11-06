import 'package:dio/dio.dart';

import '../../domain/uz_phone.dart';
import 'api_client.dart';
import 'api_response.dart';
import '../models/user_model.dart';

class AuthApiClient {
  AuthApiClient(this._api);

  final ApiClient _api;

  Dio get _dio => _api.dio;

  Options get _skipAuth => Options(extra: const {'skipAuth': true});

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String phone,
    required String password,
  }) async {
    final uname = AuthUsername.normalize(username);
    final tel = IntlPhone.isValid(phone)
        ? IntlPhone.normalize(phone)
        : phone.trim();
    return _post(
      'api/auth_register.php',
      data: {
        'full_name': fullName.trim(),
        'username': uname,
        'phone': tel,
        'phone_number': tel,
        'password': password,
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    // Backend accepts username OR phone on the `username` field; also send
    // `phone` so either identifier works if the field name changes.
    final identifier = IntlPhone.isValid(login)
        ? IntlPhone.normalize(login)
        : login.trim();
    final payload = <String, dynamic>{
      'username': identifier,
      'password': password,
    };
    if (IntlPhone.isValid(login) ||
        IntlPhone.looksLikePhone(login) ||
        _looksLikePhone(login)) {
      payload['phone'] = identifier;
      payload['phone_number'] = identifier;
    }
    return _post('api/auth_login.php', data: payload, skipAuth: true);
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? email,
    String? name,
    String? avatarUrl,
    String? id,
  }) async {
    final payload = <String, dynamic>{'id_token': idToken};
    if (email != null) payload['email'] = email;
    if (name != null) payload['name'] = name;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (id != null) payload['id'] = id;
    return _post('api/auth_google.php', data: payload, skipAuth: true);
  }

  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    String? email,
    String? name,
    String? appleId,
  }) async {
    final payload = <String, dynamic>{'identity_token': identityToken};
    if (email != null) payload['email'] = email;
    if (name != null) payload['name'] = name;
    if (appleId != null) payload['apple_id'] = appleId;
    return _post('api/auth_apple.php', data: payload, skipAuth: true);
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    return _post(
      'api/auth_refresh.php',
      data: {'refresh_token': refreshToken},
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> logout() async {
    return _post('api/auth_logout.php', data: {});
  }

  Future<Map<String, dynamic>> me() async {
    return _get('api/auth_me.php');
  }

  Future<Map<String, dynamic>> deleteAccount({String? password}) async {
    final payload = <String, dynamic>{'confirm': 'delete'};
    if (password != null && password.isNotEmpty) {
      payload['password'] = password;
    }
    return _post('api/account_delete.php', data: payload);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await _dio.get<dynamic>(path);
      return ApiResponse.parse(res.data, status: res.statusCode);
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return {'ok': false, 'error': '$e'};
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    dynamic data,
    bool skipAuth = false,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: data,
        options: skipAuth ? _skipAuth : null,
      );
      return ApiResponse.parse(res.data, status: res.statusCode);
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return {'ok': false, 'error': '$e'};
    }
  }

  Map<String, dynamic> _err(DioException e) {
    final network =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
    if (network && e.response == null) {
      return {'ok': false, 'error': 'Network error', 'error_code': 'network'};
    }
    return ApiResponse.parse(
      e.response?.data,
      status: e.response?.statusCode,
      fallbackError: e.message ?? 'Network error',
    );
  }

  static bool _looksLikePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9;
  }

  static UserModel? userFromResponse(Map<String, dynamic> res) {
    final raw = res['user'];
    if (raw is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(raw));
    }
    if (res['username'] != null) {
      return UserModel.fromJson(res);
    }
    return null;
  }
}
