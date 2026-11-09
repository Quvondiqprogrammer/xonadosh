import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ColivingGroupCodeNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to home_default when no saved preference exists', () {
      final notifier = ColivingGroupCodeNotifier();
      expect(notifier.state, 'home_default');
    });

    test('sets new group code and trims whitespace', () async {
      final notifier = ColivingGroupCodeNotifier();
      await notifier.setGroupCode('  HOME-9021  ');
      expect(notifier.state, 'HOME-9021');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_coliving_group_code'), 'HOME-9021');
    });

    test('empty string falls back to home_default', () async {
      final notifier = ColivingGroupCodeNotifier();
      await notifier.setGroupCode('');
      expect(notifier.state, 'home_default');
    });
  });
}
