import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/presentation/auth/login_screen.dart';
import 'package:xonadosh/presentation/features/xonadosh/xonadosh_shell.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

final _emptyOverrides = <Override>[
  xonadoshUniversitiesProvider.overrideWith((ref) async => <XonadoshUniversity>[]),
  xonadoshListingsProvider.overrideWith((ref) async => <XonadoshListing>[]),
  xonadoshMyProfileProvider.overrideWith((ref) async => null),
  xonadoshMatchingRoommatesProvider.overrideWith((ref) async => <XonadoshProfile>[]),
  xonadoshChoresProvider.overrideWith(
    (ref) async => (
      todayDay: 'dushanba',
      todayDuties: <XonadoshChore>[],
      allChores: <XonadoshChore>[],
    ),
  ),
  xonadoshRecipesAndMealPlanProvider.overrideWith(
    (ref) async => (
      recipes: <XonadoshRecipe>[],
      mealPlans: <XonadoshMealPlan>[],
    ),
  ),
  xonadoshGroceryCalculationProvider.overrideWith((ref) async => null),
];

void main() {
  testWidgets('login screen pumps', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('shell pumps with three tabs', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const XonadoshShell(), overrides: _emptyOverrides));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(XonadoshShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
