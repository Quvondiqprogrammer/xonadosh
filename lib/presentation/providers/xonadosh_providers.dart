import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/data/api/block_store.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';

export 'app_providers.dart';

final xonadoshSelectedUniProvider =
    StateProvider<XonadoshUniversity?>((ref) => null);

final xonadoshTypeFilterProvider = StateProvider<String>((ref) => 'all');

final xonadoshGenderFilterProvider = StateProvider<String>((ref) => 'any');

final xonadoshMatchGenderFilterProvider = StateProvider<String>((ref) => 'any');

final xonadoshSearchQueryProvider = StateProvider<String?>((ref) => null);

final xonadoshCityProvider = StateProvider<String?>((ref) => null);
final xonadoshDistrictProvider = StateProvider<String?>((ref) => null);

final xonadoshMinPriceProvider = StateProvider<double?>((ref) => null);
final xonadoshMaxPriceProvider = StateProvider<double?>((ref) => null);

final xonadoshRoommateCountProvider = StateProvider<int>((ref) => 4);

final xonadoshUniversitiesProvider =
    FutureProvider.autoDispose<List<XonadoshUniversity>>((ref) async {
  final city = ref.watch(xonadoshCityProvider);
  return ref.watch(xonadoshRepositoryProvider).getUniversities(city: city);
});

final blockStoreProvider = Provider<BlockStore>((ref) => BlockStore());

final blockedUsernamesProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(blockStoreProvider).load();
});

final xonadoshListingsProvider =
    FutureProvider.autoDispose<List<XonadoshListing>>((ref) async {
  final repo = ref.watch(xonadoshRepositoryProvider);
  final selectedUni = ref.watch(xonadoshSelectedUniProvider);
  final type = ref.watch(xonadoshTypeFilterProvider);
  final gender = ref.watch(xonadoshGenderFilterProvider);
  final city = ref.watch(xonadoshCityProvider);
  final district = ref.watch(xonadoshDistrictProvider);
  final query = ref.watch(xonadoshSearchQueryProvider);
  final minPrice = ref.watch(xonadoshMinPriceProvider);
  final maxPrice = ref.watch(xonadoshMaxPriceProvider);
  final blocked = await ref.watch(blockedUsernamesProvider.future);

  final listings = await repo.getListings(
    universityId: selectedUni?.id,
    type: type == 'all' ? null : type,
    gender: gender == 'any' ? null : gender,
    city: city,
    district: district,
    query: query,
    minPrice: minPrice,
    maxPrice: maxPrice,
    limit: 50,
  );
  if (blocked.isEmpty) return listings;
  return listings
      .where((e) => !blocked.contains(e.username.trim().toLowerCase()))
      .toList();
});

final xonadoshListingDetailProvider =
    FutureProvider.autoDispose.family<XonadoshListing?, int>((ref, id) async {
  if (id <= 0) return null;
  return ref.watch(xonadoshRepositoryProvider).getListingDetail(id);
});

final xonadoshCommuteProvider = FutureProvider.autoDispose
    .family<XonadoshCommuteEstimate?, ({int listingId, int uniId})>(
        (ref, arg) async {
  return ref.watch(xonadoshRepositoryProvider).calculateCommute(
        listingId: arg.listingId,
        universityId: arg.uniId,
      );
});

final xonadoshMyProfileProvider =
    FutureProvider.autoDispose<XonadoshProfile?>((ref) async {
  final repo = ref.watch(xonadoshRepositoryProvider);
  final session = ref.watch(sessionManagerProvider);
  return repo.getMyProfile(session.userId);
});

final xonadoshMatchingRoommatesProvider =
    FutureProvider.autoDispose<List<XonadoshProfile>>((ref) async {
  final repo = ref.watch(xonadoshRepositoryProvider);
  final session = ref.watch(sessionManagerProvider);
  final selectedUni = ref.watch(xonadoshSelectedUniProvider);
  final gender = ref.watch(xonadoshMatchGenderFilterProvider);
  final lang = ref.watch(localeProvider).languageCode;

  final apiGender = switch (gender) {
    'boys' => 'male',
    'girls' => 'female',
    _ => null,
  };

  final matches = await repo.getMatchingRoommates(
    username: session.userId,
    universityId: selectedUni?.id,
    gender: apiGender,
    lang: lang,
  );
  final blocked = await ref.watch(blockedUsernamesProvider.future);
  if (blocked.isEmpty) return matches;
  return matches
      .where((e) => !blocked.contains(e.username.trim().toLowerCase()))
      .toList();
});

final xonadoshChoresProvider = FutureProvider.autoDispose<
    ({
      String todayDay,
      List<XonadoshChore> todayDuties,
      List<XonadoshChore> allChores
    })>((ref) async {
  return ref.watch(xonadoshRepositoryProvider).getChores();
});

final xonadoshRecipesAndMealPlanProvider = FutureProvider.autoDispose<
    ({List<XonadoshRecipe> recipes, List<XonadoshMealPlan> mealPlans})>((ref) async {
  return ref.watch(xonadoshRepositoryProvider).getRecipesAndMealPlan();
});

final xonadoshGroceryCalculationProvider =
    FutureProvider.autoDispose<XonadoshGroceryCalculation?>((ref) async {
  final roommateCount = ref.watch(xonadoshRoommateCountProvider);
  return ref
      .watch(xonadoshRepositoryProvider)
      .calculateGrocery(roommateCount: roommateCount);
});

final xonadoshKarmaProvider =
    FutureProvider.autoDispose<XonadoshKarmaData>((ref) async {
  return ref.watch(xonadoshRepositoryProvider).getKarma();
});

final xonadoshPollsProvider =
    FutureProvider.autoDispose<XonadoshPollsData>((ref) async {
  return ref.watch(xonadoshRepositoryProvider).getPolls();
});

final xonadoshFinancesProvider =
    FutureProvider.autoDispose<XonadoshFinancesData>((ref) async {
  return ref.watch(xonadoshRepositoryProvider).getFinances();
});

