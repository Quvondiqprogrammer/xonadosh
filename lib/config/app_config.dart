/// Public API configuration. No secrets.
class AppConfig {
  AppConfig._();

  static const String appName = 'XonaDosh';
  static const String appVersion = '1.0.1';
  static const String baseUrl = 'https://honadosh.uz/';
  static const String privacyUrl = 'https://honadosh.uz/privacy/';
  static const String termsUrl = 'https://honadosh.uz/terms/';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 25);
}
