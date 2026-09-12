import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/presentation/features/xonadosh/tabs/matching_tab_impl.dart';
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

const _dummyCandidate = XonadoshProfile(
  id: 101,
  username: 'jasur_dev',
  fullName: 'Jasur Saidov',
  phoneNumber: '+998901112233',
  telegramHandle: 'jasur_s',
  gender: 'male',
  age: 21,
  universityShort: 'TUIT',
  courseYear: 3,
  budgetMin: 600000,
  budgetMax: 1200000,
  sleepSchedule: 'early_bird',
  cleanliness: 'strict',
  studyHabit: 'silent',
  cookingHabit: 'rotates',
  smokingHabit: 'no',
  compatibilityScore: 92,
  matchReasons: ['🎓 Bir xil OTM', '🌙 Uyqu tartibi mos', '✨ Tozalik talabi bir xil'],
);

void main() {
  testWidgets('matching tab renders candidate card with match score and quick actions', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const XonadoshMatchingTab(),
        overrides: [
          xonadoshMyProfileProvider.overrideWith((ref) async => null),
          xonadoshMatchingRoommatesProvider.overrideWith((ref) async => [_dummyCandidate]),
          xonadoshUniversitiesProvider.overrideWith((ref) async => []),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Jasur Saidov'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('Why this match'), findsWidgets);
    expect(find.text('🎓 Bir xil OTM'), findsOneWidget);
    expect(find.text('Who are you looking for?'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);
    expect(find.byIcon(Icons.call_rounded), findsWidgets);
    expect(find.byIcon(Icons.send_rounded), findsWidgets);
  });
}
