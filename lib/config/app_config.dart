/// Public API configuration. No secrets.
class AppConfig {
  AppConfig._();

  static const String appName = 'XonaDosh';
  static const String appVersion = '1.0.8';
  static const String baseUrl = 'https://xonadoshim.uz/';
  static const String privacyUrl = 'https://xonadoshim.uz/privacy/';
  static const String termsUrl = 'https://xonadoshim.uz/terms/';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 25);
}
