import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xonadosh/data/api/block_store.dart';
import 'package:xonadosh/data/api/onboarding_store.dart';
import 'package:xonadosh/data/models/chat_models.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';

export 'app_providers.dart';

final xonadoshShellTabIndexProvider = StateProvider<int>((ref) => 0);

final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return OnboardingStore();
});

final firstRunSeenProvider = FutureProvider<bool>((ref) async {
  return ref.read(onboardingStoreProvider).isSeen();
});

final xonadoshSelectedUniProvider = StateProvider<XonadoshUniversity?>(
  (ref) => null,
);

final xonadoshTypeFilterProvider = StateProvider<String>((ref) => 'all');

final xonadoshGenderFilterProvider = StateProvider<String>((ref) => 'any');

final xonadoshMatchGenderFilterProvider = StateProvider<String>((ref) => 'any');

/// Tinder Swipe vs List view mode for roommate matching
final xonadoshMatchSwipeModeProvider = StateProvider<bool>((ref) => true);

/// Matching university filter — kept separate from housing so a housing
/// city/OTM filter does not silently hide roommate matches.
final xonadoshMatchUniProvider = StateProvider<XonadoshUniversity?>(
  (ref) => null,
);

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

/// Matching OTM picker is independent of housing city so a housing
/// region filter cannot silently shrink roommate options.
final xonadoshAllUniversitiesProvider =
    FutureProvider.autoDispose<List<XonadoshUniversity>>((ref) async {
      return ref.watch(xonadoshRepositoryProvider).getUniversities();
    });

final blockStoreProvider = Provider<BlockStore>((ref) => BlockStore());

final blockedUsernamesProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(blockStoreProvider).load();
});

final xonadoshNoBrokerFilterProvider = StateProvider<bool>((ref) => false);
final xonadoshUtilitiesIncludedFilterProvider = StateProvider<bool>(
  (ref) => false,
);
final xonadoshSubsidyFilterProvider = StateProvider<bool>((ref) => false);
final xonadoshWomenOnlyFilterProvider = StateProvider<bool>((ref) => false);
final xonadoshNearUniFilterProvider = StateProvider<bool>((ref) => false);
final xonadoshMaxCommuteFilterProvider = StateProvider<int?>((ref) => null);

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
      final noBroker = ref.watch(xonadoshNoBrokerFilterProvider);
      final utilitiesIncluded = ref.watch(
        xonadoshUtilitiesIncludedFilterProvider,
      );
      final subsidyOnly = ref.watch(xonadoshSubsidyFilterProvider);
      final womenOnly = ref.watch(xonadoshWomenOnlyFilterProvider);
      final nearUniOnly = ref.watch(xonadoshNearUniFilterProvider);
      final maxCommute = ref.watch(xonadoshMaxCommuteFilterProvider);
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
        noBroker: noBroker ? true : null,
        utilitiesIncluded: utilitiesIncluded ? true : null,
        subsidyOnly: subsidyOnly ? true : null,
        womenOnly: womenOnly ? true : null,
        maxDistanceKm: nearUniOnly ? 2.0 : null,
        maxCommuteMin: maxCommute,
        limit: 50,
      );

      var filtered = listings;
      if (noBroker) {
        filtered = filtered.where((e) => e.isNoBroker).toList();
      }
      if (utilitiesIncluded) {
        filtered = filtered.where((e) => e.utilitiesIncluded).toList();
      }
      if (subsidyOnly) {
        filtered = filtered.where((e) => e.hasSubsidyContract).toList();
      }
      if (womenOnly) {
        filtered = filtered.where((e) => e.isWomenOnly).toList();
      }
      if (nearUniOnly) {
        filtered = filtered
            .where((e) => (e.distanceToUniversityKm ?? 999) <= 2.0)
            .toList();
      }
      if (blocked.isNotEmpty) {
        filtered = filtered
            .where((e) => !blocked.contains(e.username.trim().toLowerCase()))
            .toList();
      }
      return filtered;
    });

final xonadoshHouseRulesProvider =
    FutureProvider.autoDispose<List<XonadoshHouseRule>>((ref) async {
      return ref.watch(xonadoshRepositoryProvider).getHouseRules();
    });

final xonadoshListingDetailProvider = FutureProvider.autoDispose
    .family<XonadoshListing?, int>((ref, id) async {
      if (id <= 0) return null;
      return ref.watch(xonadoshRepositoryProvider).getListingDetail(id);
    });

final xonadoshCommuteProvider = FutureProvider.autoDispose
    .family<XonadoshCommuteEstimate?, ({int listingId, int uniId})>((
      ref,
      arg,
    ) async {
      return ref
          .watch(xonadoshRepositoryProvider)
          .calculateCommute(listingId: arg.listingId, universityId: arg.uniId);
    });

final xonadoshMyProfileProvider = FutureProvider.autoDispose<XonadoshProfile?>((
  ref,
) async {
  final repo = ref.watch(xonadoshRepositoryProvider);
  final session = ref.watch(sessionManagerProvider);
  return repo.getMyProfile(session.username);
});

final xonadoshMatchingRoommatesProvider =
    FutureProvider.autoDispose<List<XonadoshProfile>>((ref) async {
      final repo = ref.watch(xonadoshRepositoryProvider);
      final session = ref.watch(sessionManagerProvider);
      final selectedUni = ref.watch(xonadoshMatchUniProvider);
      final gender = ref.watch(xonadoshMatchGenderFilterProvider);
      final lang = ref.watch(localeProvider).languageCode;
      final myProfile = await ref.watch(xonadoshMyProfileProvider.future);

      final apiGender = switch (gender) {
        'boys' => 'male',
        'girls' => 'female',
        _ => null,
      };

      final matches = await repo.getMatchingRoommates(
        username: session.username,
        universityId: selectedUni?.id,
        gender: apiGender,
        sleepSchedule: myProfile?.sleepSchedule,
        cleanliness: myProfile?.cleanliness,
        studyHabit: myProfile?.studyHabit,
        cookingHabit: myProfile?.cookingHabit,
        smokingHabit: myProfile?.smokingHabit,
        budgetMin: myProfile?.budgetMin,
        budgetMax: myProfile?.budgetMax,
        lang: lang,
      );
      final blocked = await ref.watch(blockedUsernamesProvider.future);
      if (blocked.isEmpty) return matches;
      return matches
          .where((e) => !blocked.contains(e.username.trim().toLowerCase()))
          .toList();
    });

class ColivingGroupCodeNotifier extends StateNotifier<String> {
  static const _prefKey = 'active_coliving_group_code';

  ColivingGroupCodeNotifier() : super('home_default') {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        state = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> setGroupCode(String code) async {
    final clean = code.trim().isEmpty ? 'home_default' : code.trim();
    state = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, clean);
    } catch (_) {}
  }
}

final colivingGroupCodeProvider =
    StateNotifierProvider<ColivingGroupCodeNotifier, String>((ref) {
  return ColivingGroupCodeNotifier();
});

final xonadoshChoresProvider =
    FutureProvider.autoDispose<
      ({
        String todayDay,
        List<XonadoshChore> todayDuties,
        List<XonadoshChore> allChores,
      })
    >((ref) async {
      final groupCode = ref.watch(colivingGroupCodeProvider);
      return ref.watch(xonadoshRepositoryProvider).getChores(groupCode: groupCode);
    });

final xonadoshRecipesAndMealPlanProvider =
    FutureProvider.autoDispose<
      ({List<XonadoshRecipe> recipes, List<XonadoshMealPlan> mealPlans})
    >((ref) async {
      final groupCode = ref.watch(colivingGroupCodeProvider);
      return ref
          .watch(xonadoshRepositoryProvider)
          .getRecipesAndMealPlan(groupCode: groupCode);
    });

final xonadoshGroceryCalculationProvider =
    FutureProvider.autoDispose<XonadoshGroceryCalculation?>((ref) async {
      final roommateCount = ref.watch(xonadoshRoommateCountProvider);
      return ref
          .watch(xonadoshRepositoryProvider)
          .calculateGrocery(roommateCount: roommateCount);
    });

final xonadoshKarmaProvider = FutureProvider.autoDispose<XonadoshKarmaData>((
  ref,
) async {
  final groupCode = ref.watch(colivingGroupCodeProvider);
  return ref.watch(xonadoshRepositoryProvider).getKarma(groupCode: groupCode);
});

final xonadoshPollsProvider = FutureProvider.autoDispose<XonadoshPollsData>((
  ref,
) async {
  final groupCode = ref.watch(colivingGroupCodeProvider);
  return ref.watch(xonadoshRepositoryProvider).getPolls(groupCode: groupCode);
});

final xonadoshFinancesProvider =
    FutureProvider.autoDispose<XonadoshFinancesData>((ref) async {
      final groupCode = ref.watch(colivingGroupCodeProvider);
      return ref
          .watch(xonadoshRepositoryProvider)
          .getFinances(groupCode: groupCode);
    });

final xonadoshHouseRulesAgreementProvider = FutureProvider.autoDispose
    .family<XonadoshHouseRulesAgreement, String>((ref, groupCode) async {
      return ref
          .watch(xonadoshRepositoryProvider)
          .getHouseRulesAgreement(groupCode: groupCode);
    });

final xonadoshSquadsProvider = FutureProvider.autoDispose<List<XonadoshSquad>>((
  ref,
) async {
  final selectedUni = ref.watch(xonadoshSelectedUniProvider);
  return ref
      .watch(xonadoshRepositoryProvider)
      .getSquads(universityId: selectedUni?.id);
});

// -------------------------------------------------------------
// IN-APP CHAT PROVIDERS
// -------------------------------------------------------------

final chatConversationsProvider =
    FutureProvider.autoDispose<List<ChatConversationModel>>((ref) async {
  return ref.watch(xonadoshRepositoryProvider).getChatConversations();
});

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessageModel>, int>((ref, conversationId) async {
  return ref.watch(xonadoshRepositoryProvider).getChatMessages(conversationId);
});

final chatTotalUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final convsAsync = ref.watch(chatConversationsProvider);
  return convsAsync.maybeWhen(
    data: (convs) => convs.fold<int>(0, (sum, c) => sum + c.unreadCount),
    orElse: () => 0,
  );
});
