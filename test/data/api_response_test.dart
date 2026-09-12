import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/data/api/api_response.dart';

void main() {
  group('ApiResponse.isOk', () {
    test('accepts PHP/JSON truthy variants', () {
      expect(ApiResponse.isOk(true), isTrue);
      expect(ApiResponse.isOk(1), isTrue);
      expect(ApiResponse.isOk('true'), isTrue);
      expect(ApiResponse.isOk('1'), isTrue);
      expect(ApiResponse.isOk('ok'), isTrue);
      expect(ApiResponse.isOk(false), isFalse);
      expect(ApiResponse.isOk(0), isFalse);
      expect(ApiResponse.isOk(null), isFalse);
    });
  });

  group('ApiResponse.parse', () {
    test('keeps ok true and status on 200 JSON', () {
      final map = ApiResponse.parse({'ok': true, 'token': 'abc'}, status: 200);
      expect(map['ok'], isTrue);
      expect(map['status'], 200);
      expect(map['token'], 'abc');
    });

    test('forces ok false on HTTP 401 even if body says ok', () {
      final map = ApiResponse.parse(
        {'ok': true, 'error': 'nope'},
        status: 401,
      );
      expect(map['ok'], isFalse);
      expect(map['error'], 'nope');
    });

    test('uses message as error when ok is false', () {
      final map = ApiResponse.parse(
        {'ok': false, 'message': 'Parol noto‘g‘ri'},
        status: 401,
      );
      expect(map['ok'], isFalse);
      expect(map['error'], 'Parol noto‘g‘ri');
    });

    test('detects HTML error pages', () {
      final map = ApiResponse.parse(
        '<html><body>500 Internal Server Error</body></html>',
        status: 500,
      );
      expect(map['ok'], isFalse);
      expect(map['error'], contains('HTML'));
    });

    test('coerces ok: 1 to true', () {
      final map = ApiResponse.parse({'ok': 1, 'listings': []}, status: 200);
      expect(map['ok'], isTrue);
    });
  });

  group('ApiResponse.compactQuery', () {
    test('drops null and blank values', () {
      final q = ApiResponse.compactQuery({
        'city': 'Toshkent',
        'gender': '',
        'university_id': null,
        'limit': 30,
      });
      expect(q.keys, unorderedEquals(['city', 'limit']));
      expect(q['city'], 'Toshkent');
      expect(q['limit'], 30);
    });
  });
}
