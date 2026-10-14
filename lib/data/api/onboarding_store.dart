import 'package:shared_preferences/shared_preferences.dart';

/// First-run 3-screen onboarding persistence (v2 = ASC 4.3 unique flow).
class OnboardingStore {
  static const key = 'xd_onboarding_v2_firstrun_seen';

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
