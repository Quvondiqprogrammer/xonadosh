import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/api/auth_api_client.dart';
import '../../data/api/session_manager.dart';
import '../../data/api/xonadosh_api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/xonadosh_repository.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(sessionManagerProvider));
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(ref.watch(apiClientProvider));
});

final xonadoshApiClientProvider = Provider<XonadoshApiClient>((ref) {
  return XonadoshApiClient(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiClientProvider),
    session: ref.watch(sessionManagerProvider),
    onSessionCleared: () =>
        ref.read(xonadoshRepositoryProvider).clearUserLocalData(),
  );
});

final xonadoshRepositoryProvider = Provider<XonadoshRepository>((ref) {
  return XonadoshRepository(ref.watch(xonadoshApiClientProvider));
});

/// Auth bootstrap: true if logged in. Never hangs forever on network.
final authBootstrapProvider = FutureProvider<bool>((ref) async {
  final session = ref.read(sessionManagerProvider);
  try {
    await session.load().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Keychain/prefs hiccup — treat as logged out.
  }
  ref.read(localeProvider.notifier).syncFromSession();
  ref.read(themeModeProvider.notifier).syncFromSession();
  try {
    return await ref
        .read(authRepositoryProvider)
        .hasValidSession()
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => session.isAuthenticated,
        );
  } catch (_) {
    return false;
  }
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(sessionManagerProvider));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._session) : super(Locale(_session.languageCode));

  final SessionManager _session;

  void syncFromSession() {
    state = Locale(_session.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _session.setLanguageCode(locale.languageCode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sessionManagerProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._session)
      : super(_map(_session.themeModePref));

  final SessionManager _session;

  static ThemeMode _map(ThemeModePref p) => switch (p) {
        ThemeModePref.light => ThemeMode.light,
        ThemeModePref.dark => ThemeMode.dark,
        ThemeModePref.system => ThemeMode.system,
      };

  void syncFromSession() {
    state = _map(_session.themeModePref);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final pref = switch (mode) {
      ThemeMode.light => ThemeModePref.light,
      ThemeMode.dark => ThemeModePref.dark,
      ThemeMode.system => ThemeModePref.system,
    };
    await _session.setThemeModePref(pref);
  }
}
