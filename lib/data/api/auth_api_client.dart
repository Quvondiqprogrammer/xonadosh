import 'package:dio/dio.dart';

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
    return _post(
      'api/auth_register.php',
      data: {
        'full_name': fullName,
        'username': username,
        'phone': phone,
        'phone_number': phone,
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
    final payload = <String, dynamic>{
      'username': login,
      'password': password,
    };
    if (_looksLikePhone(login)) {
      payload['phone'] = login;
      payload['phone_number'] = login;
    }
    return _post(
      'api/auth_login.php',
      data: payload,
      skipAuth: true,
    );
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

  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    return _post(
      'api/account_delete.php',
      data: {
        'password': password,
        'confirm': 'delete',
      },
    );
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
