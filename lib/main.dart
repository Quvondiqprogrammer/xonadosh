import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/core/services/analytics_service.dart';
import 'package:xonadosh/core/services/fcm_service.dart';
import 'package:xonadosh/core/services/xonadosh_retention_notification_service.dart';
import 'package:xonadosh/firebase_options.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/presentation/common/app_viewport.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';
import 'package:xonadosh/presentation/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
        xonadoshFirebaseMessagingBackgroundHandler,
      );
      await XonaDoshFcmService.instance.initialize();
      await AnalyticsService.instance.initialize();
      await XonaDoshRetentionNotificationService.instance.initialize();
    }
  } catch (e) {
    debugPrint('[Firebase Init Error]: $e');
  }

  runApp(const ProviderScope(child: XonaDoshApp()));
}

class XonaDoshApp extends ConsumerWidget {
  const XonaDoshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'XonaDosh',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppViewport(child: child),
      routerConfig: router,
    );
  }
}
