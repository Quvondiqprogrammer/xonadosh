import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(
    analytics: _analytics ?? FirebaseAnalytics.instance,
  );

  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('[AnalyticsService] init error: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  Future<void> logLogin({required String method}) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (_) {}
  }
}
