import 'package:xonadosh/l10n/app_localizations.dart';

String localizedAuthError(AppLocalizations l10n, Map<String, dynamic> res) {
  final code = (res['error_code'] ?? '').toString().trim();
  switch (code) {
    case 'username_taken':
      return l10n.registerErrorUsernameTaken;
    case 'phone_taken':
      return l10n.registerErrorPhoneTaken;
    case 'invalid_phone':
      return l10n.registerPhoneInvalid;
    case 'invalid_username':
      return l10n.registerUsernameInvalid;
    case 'weak_password':
      return l10n.registerPasswordHint;
    case 'invalid_name':
      return l10n.registerNameInvalid;
    case 'invalid_credentials':
      return l10n.loginErrorInvalid;
    case 'blocked':
      return l10n.loginErrorBlocked;
    case 'network':
      return l10n.errorNetwork;
    case 'rate_limited':
      return l10n.errorRateLimited;
  }

  final err = (res['error'] ?? '').toString();
  final lower = err.toLowerCase();
  if (lower.contains('telefon') && lower.contains('band')) {
    return l10n.registerErrorPhoneTaken;
  }
  if ((lower.contains('login') || lower.contains('username')) &&
      lower.contains('band')) {
    return l10n.registerErrorUsernameTaken;
  }
  if (lower.contains('parol') &&
      (lower.contains('8') || lower.contains('kamida'))) {
    return l10n.registerPasswordHint;
  }
  if (lower.contains('blok')) return l10n.loginErrorBlocked;
  if (lower.contains('login yoki parol') ||
      lower.contains('username or password') ||
      lower.contains('неверн')) {
    return l10n.loginErrorInvalid;
  }
  if (lower.contains('socket') ||
      lower.contains('timed out') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('handshake')) {
    return l10n.errorNetwork;
  }
  if (err.trim().isNotEmpty) return err.trim();
  return l10n.errorGeneric;
}
