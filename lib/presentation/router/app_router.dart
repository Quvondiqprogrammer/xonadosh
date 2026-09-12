import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/auth/login_screen.dart';
import 'package:xonadosh/presentation/auth/register_screen.dart';
import 'package:xonadosh/presentation/common/loading.dart';
import 'package:xonadosh/presentation/features/xonadosh/screens/create_listing_screen.dart';
import 'package:xonadosh/presentation/features/xonadosh/screens/listing_detail_screen.dart';
import 'package:xonadosh/presentation/features/xonadosh/screens/map_screen.dart';
import 'package:xonadosh/presentation/features/xonadosh/screens/profile_edit_screen.dart';
import 'package:xonadosh/presentation/features/xonadosh/screens/settings_screen.dart';
import 'package:xonadosh/presentation/features/xonadosh/xonadosh_shell.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final boot = ref.read(authBootstrapProvider);
      final loc = state.matchedLocation;
      final onLogin = loc == AppRoutes.login;
      final onRegister = loc == AppRoutes.register;
      final onSplash = loc == AppRoutes.splash;

      // Still checking session → keep splash only.
      // If a local session already exists, don't yank the user back to splash
      // (login/register would flash splash after a successful sign-in).
      if (boot.isLoading || boot.isRefreshing) {
        final hasLocal = ref.read(sessionManagerProvider).isAuthenticated;
        if (hasLocal && !onLogin && !onRegister && !onSplash) {
          return null;
        }
        return onSplash ? null : AppRoutes.splash;
      }

      final loggedIn = boot.asData?.value == true;

      // Not logged in (or bootstrap error) → login (never stay on splash).
      if (!loggedIn) {
        if (onLogin || onRegister) return null;
        return AppRoutes.login;
      }

      // Logged in → leave auth screens.
      if (onLogin || onRegister || onSplash) {
        return AppRoutes.shell;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const Scaffold(body: AppLoading()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.shell,
        builder: (_, _) => const XonadoshShell(),
        routes: [
          GoRoute(
            path: 'map',
            builder: (_, _) => const XonadoshMapScreen(),
          ),
          GoRoute(
            path: 'listing/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return XonadoshListingDetailScreen(listingId: id);
            },
          ),
          GoRoute(
            path: 'profile-edit',
            builder: (_, state) {
              final extra = state.extra;
              return XonadoshProfileEditScreen(
                initialProfile: extra is XonadoshProfile ? extra : null,
              );
            },
          ),
          GoRoute(
            path: 'create-listing',
            builder: (_, _) => const XonadoshCreateListingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(authBootstrapProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
