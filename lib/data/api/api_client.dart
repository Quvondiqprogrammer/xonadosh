import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import 'session_manager.dart';

/// Dio client with Bearer auth + single refresh retry on 401.
class ApiClient {
  ApiClient(this._session) {
    assert(
      AppConfig.baseUrl.startsWith('https://'),
      'XonaDosh API must be HTTPS',
    );

    final base = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      // Do not pin Content-Type globally — multipart uploads must set their own.
      headers: const {'Accept': 'application/json'},
      validateStatus: (code) => code != null && code < 600,
    );

    _dio = Dio(base);
    _authDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
        validateStatus: (code) => code != null && code < 600,
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = _session.languageCode;
          options.headers['X-XonaDosh-Client'] =
              'xonadosh-flutter/${AppConfig.appVersion}';
          if (options.data is! FormData &&
              (options.contentType == null ||
                  options.contentType == Headers.jsonContentType)) {
            options.headers.putIfAbsent(
              Headers.contentTypeHeader,
              () => Headers.jsonContentType,
            );
          }
          if (options.extra['skipAuth'] == true) {
            options.headers.remove('Authorization');
          } else {
            var token = await _session.getApiToken();
            if (token == null || token.trim().isEmpty) {
              token = await _tryRefreshToken();
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
          final retry = await _retryAfter401(response.requestOptions, response.statusCode);
          if (retry != null) return handler.resolve(retry);
          handler.next(response);
        },
        onError: (error, handler) async {
          final retry = await _retryAfter401(
            error.requestOptions,
            error.response?.statusCode,
          );
          if (retry != null) return handler.resolve(retry);
          handler.next(error);
        },
      ),
    );
  }

  final SessionManager _session;
  late final Dio _dio;
  late final Dio _authDio;

  /// True when the refresh endpoint rejected the token (not a network blip).
  bool _refreshRejected = false;

  Dio get dio => _dio;
  SessionManager get session => _session;

  Future<Response<dynamic>?> _retryAfter401(
    RequestOptions req,
    int? status,
  ) async {
    final skipAuth = req.extra['skipAuth'] == true;
    final alreadyRetried = req.extra['retried'] == true;
    if (skipAuth || status != 401 || alreadyRetried) return null;

    _refreshRejected = false;
    final refreshed = await _tryRefreshToken();
    if (refreshed != null && refreshed.isNotEmpty) {
      try {
        req.headers['Authorization'] = 'Bearer $refreshed';
        req.extra['retried'] = true;
        return await _dio.fetch(req);
      } catch (_) {
        return null;
      }
    }
    // Only drop the session when the refresh token itself is invalid.
    if (_refreshRejected) {
      await _session.clearApiToken();
    }
    return null;
  }

  Future<String?> _tryRefreshToken() async {
    try {
      final rt = await _session.getRefreshToken();
      if (rt == null || rt.trim().isEmpty) {
        _refreshRejected = true;
        return null;
      }
      final res = await _authDio.post<dynamic>(
        'api/auth_refresh.php',
        data: {'refresh_token': rt.trim()},
        options: Options(
          headers: const {Headers.contentTypeHeader: Headers.jsonContentType},
        ),
      );
      final code = res.statusCode ?? 0;
      final body = res.data;
      if (code == 401 || code == 403) {
        _refreshRejected = true;
        return null;
      }
      if (code == 200 && body is Map) {
        final map = Map<String, dynamic>.from(body);
        if (map['ok'] == true && map['token'] is String) {
          final newToken = (map['token'] as String).trim();
          if (newToken.isEmpty) {
            _refreshRejected = true;
            return null;
          }
          await _session.saveApiTokens(
            token: newToken,
            refreshToken: map['refresh_token'] as String?,
            expiresAt: (map['expires_at'] as num?)?.toInt(),
          );
          return newToken;
        }
        if (map['ok'] == false) {
          _refreshRejected = true;
        }
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 401 || code == 403) {
        _refreshRejected = true;
      }
    } catch (_) {}
    return null;
  }
}
