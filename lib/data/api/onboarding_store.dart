import 'package:shared_preferences/shared_preferences.dart';

/// First-run welcome sheet persistence.
class OnboardingStore {
  static const key = 'xd_onboarding_v1_seen';

  Future<bool> isSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {}
  }
}
