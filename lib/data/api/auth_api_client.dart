import 'package:dio/dio.dart';

import '../models/user_model.dart';
import 'api_client.dart';

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
        'password': password,
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    return _post(
      'api/auth_login.php',
      data: {
        'username': login,
        'password': password,
      },
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
      return _asMap(res.data, status: res.statusCode);
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
      return _asMap(res.data, status: res.statusCode);
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return {'ok': false, 'error': '$e'};
    }
  }

  Map<String, dynamic> _asMap(dynamic data, {int? status}) {
    final Map<String, dynamic> map;
    if (data is Map<String, dynamic>) {
      map = Map<String, dynamic>.from(data);
    } else if (data is Map) {
      map = Map<String, dynamic>.from(data);
    } else {
      map = {'ok': false, 'error': 'Invalid response'};
    }
    if (status != null) map['status'] = status;
    if (status != null && status >= 400) {
      map['ok'] = false;
    }
    return map;
  }

  Map<String, dynamic> _err(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode;
    if (data is Map) {
      return {
        'ok': false,
        'error': data['error'] ?? e.message,
        'status': ?status,
      };
    }
    return {
      'ok': false,
      'error': e.message ?? 'Network error',
      'status': ?status,
    };
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
