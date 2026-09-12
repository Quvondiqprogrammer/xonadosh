import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xonadosh/data/api/onboarding_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first run is unseen then marked seen', () async {
    final store = OnboardingStore();
    expect(await store.isSeen(), isFalse);
    await store.markSeen();
    expect(await store.isSeen(), isTrue);
  });
}
