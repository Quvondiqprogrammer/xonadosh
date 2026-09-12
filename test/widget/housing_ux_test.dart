import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/presentation/features/xonadosh/tabs/housing_tab.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/listing_card.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/onboarding_welcome.dart';
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

XonadoshListing _listing() {
  return const XonadoshListing(
    id: 7,
    username: 'ali',
    ownerName: 'Ali',
    phoneNumber: '+998901112233',
    telegramHandle: 'ali_t',
    type: 'rent',
    title: 'Yunusobod 2 rooms',
    description: 'Near metro',
    price: 2500000,
    currency: 'UZS',
    pricePeriod: 'month',
    city: 'Toshkent',
    district: 'Yunusobod',
    address: 'Amir Temur 12',
    latitude: 41.3,
    longitude: 69.2,
    roomsCount: 2,
    floor: 3,
    totalFloors: 5,
    areaSqm: 45,
    targetGender: 'any',
    targetTenant: 'Students',
    amenities: [],
    photos: [],
    status: 'active',
    nearestMetro: 'Yunusobod',
    nearestUniversityShort: 'TATU',
    distanceToUniversityKm: 1.2,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty housing market tells user to post a listing', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const Scaffold(body: XonadoshHousingTab()),
        overrides: [
          xonadoshUniversitiesProvider.overrideWith((ref) async => <XonadoshUniversity>[]),
          xonadoshListingsProvider.overrideWith((ref) async => <XonadoshListing>[]),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No listings yet'), findsOneWidget);
    expect(find.text('Post listing'), findsWidgets);
    expect(find.text('Find a room'), findsOneWidget);
    expect(find.text('Find a roommate'), findsOneWidget);
  });

  testWidgets('listing card shows price, metro, university distance and report', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: XonadoshListingCard(
            item: _listing(),
            bookmarked: false,
            onTap: () {},
            onBookmark: () {},
            onReport: () {},
            onCall: () {},
            onTelegram: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Yunusobod 2 rooms'), findsOneWidget);
    expect(find.textContaining('2 500 000'), findsOneWidget);
    expect(find.text('Yunusobod'), findsWidgets);
    expect(find.textContaining('Metro Yunusobod'), findsOneWidget);
    expect(find.textContaining('TATU'), findsOneWidget);
    expect(find.textContaining('1.2 km'), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('onboarding sheet explains three jobs', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: XonadoshOnboardingSheet(onDone: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('What XonaDosh does'), findsOneWidget);
    expect(find.text('Find a room'), findsOneWidget);
    expect(find.text('Find a roommate'), findsOneWidget);
    expect(find.text('Live together'), findsOneWidget);
    expect(find.text('Let’s start'), findsOneWidget);
  });
}
