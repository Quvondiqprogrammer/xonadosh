/// Normalizes PHP/JSON API envelopes from `honadosh.uz`.
///
/// Backend success bodies typically include `"ok": true`. Errors use
/// `"ok": false` plus `"error"` (sometimes `"message"`) and may arrive as
/// HTML, a bare string, or HTTP 4xx/5xx with a JSON body.
class ApiResponse {
  ApiResponse._();

  static bool isOk(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'ok' || v == 'success';
    }
    return false;
  }

  /// Compact query map: drop nulls and blank strings so PHP `isset` filters
  /// are not tripped by `university_id=` / `gender=`.
  static Map<String, dynamic> compactQuery(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      out[key] = value;
    });
    return out;
  }

  static String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty) continue;
      return s;
    }
    return null;
  }

  static Map<String, dynamic> parse(
    dynamic data, {
    int? status,
    String fallbackError = 'Invalid response',
  }) {
    var map = _coerceMap(data, fallbackError: fallbackError);

    final explicitOk = map.containsKey('ok');
    var ok = explicitOk
        ? isOk(map['ok'])
        : (status == null || (status >= 200 && status < 400)) &&
            map['error'] == null;

    if (status != null && status >= 400) {
      ok = false;
    }

    map['ok'] = ok;
    if (status != null) map['status'] = status;

    if (!ok) {
      map['error'] = _firstNonEmpty(map, const ['error', 'message', 'msg', 'detail']) ??
          fallbackError;
    }
    return map;
  }

  static Map<String, dynamic> _coerceMap(
    dynamic data, {
    required String fallbackError,
  }) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return {'ok': false, 'error': fallbackError};
      }
      if (_looksLikeHtml(trimmed)) {
        return {'ok': false, 'error': 'Server returned an HTML error page'};
      }
      return {'ok': false, 'error': _truncate(trimmed)};
    }
    if (data == null) {
      return {'ok': false, 'error': fallbackError};
    }
    return {'ok': false, 'error': fallbackError};
  }

  static bool _looksLikeHtml(String raw) {
    final head = raw.length > 80 ? raw.substring(0, 80) : raw;
    final lower = head.toLowerCase();
    return lower.contains('<html') ||
        lower.contains('<!doctype') ||
        lower.contains('<body') ||
        lower.contains('<br');
  }

  static String _truncate(String raw, [int max = 180]) {
    final oneLine = raw.replaceAll(RegExp(r'\s+'), ' ');
    if (oneLine.length <= max) return oneLine;
    return '${oneLine.substring(0, max)}…';
  }
}
