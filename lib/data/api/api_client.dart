import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import 'session_manager.dart';

/// Dio client with Bearer auth + single refresh retry on 401.
class ApiClient {
  ApiClient(this._session) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        validateStatus: (code) => code != null && code < 600,
      ),
    );
    _authDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
        validateStatus: (code) => code != null && code < 600,
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = _session.languageCode;
          if (options.extra['skipAuth'] == true) {
            options.headers.remove('Authorization');
          } else {
            var token = await _session.getApiToken();
            if (token == null || token.trim().isEmpty) {
              token = await _tryRefreshToken();
            }
            if (token == null || token.trim().isEmpty) {
              token = await _session.getApiToken(allowExpired: true);
            }
            if (token != null && token.trim().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${token.trim()}';
            } else {
              options.headers.remove('Authorization');
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          final code = response.statusCode ?? 0;
          final skipAuth = response.requestOptions.extra['skipAuth'] == true;
          final alreadyRetried = response.requestOptions.extra['retried'] == true;
          if (!skipAuth && code == 401 && !alreadyRetried) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null && refreshed.isNotEmpty) {
              try {
                final req = response.requestOptions;
                req.headers['Authorization'] = 'Bearer $refreshed';
                req.extra['retried'] = true;
                final retry = await _dio.fetch(req);
                return handler.resolve(retry);
              } catch (_) {}
            }
            await _session.clearApiToken();
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final code = error.response?.statusCode ?? 0;
          final skipAuth = error.requestOptions.extra['skipAuth'] == true;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          if (!skipAuth && code == 401 && !alreadyRetried) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null && refreshed.isNotEmpty) {
              try {
                final req = error.requestOptions;
                req.headers['Authorization'] = 'Bearer $refreshed';
                req.extra['retried'] = true;
                final retry = await _dio.fetch(req);
                return handler.resolve(retry);
              } catch (_) {}
            }
            await _session.clearApiToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  final SessionManager _session;
  late final Dio _dio;
  late final Dio _authDio;

  Dio get dio => _dio;
  SessionManager get session => _session;

  Future<String?> _tryRefreshToken() async {
    try {
      final rt = await _session.getRefreshToken();
      if (rt == null || rt.trim().isEmpty) return null;
      final res = await _authDio.post<Map<String, dynamic>>(
        'api/auth_refresh.php',
        data: {'refresh_token': rt.trim()},
      );
      if (res.statusCode == 200 && res.data is Map) {
        final body = Map<String, dynamic>.from(res.data as Map);
        if (body['ok'] == true && body['token'] is String) {
          final newToken = (body['token'] as String).trim();
          await _session.saveApiTokens(
            token: newToken,
            refreshToken: body['refresh_token'] as String?,
            expiresAt: (body['expires_at'] as num?)?.toInt(),
          );
          return newToken;
        }
      }
    } catch (_) {}
    return null;
  }
}
