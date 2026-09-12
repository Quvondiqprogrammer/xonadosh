import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xonadosh/data/api/xonadosh_api_client.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';

class XonadoshRepository {
  XonadoshRepository(this._api);

  final XonadoshApiClient _api;

  /// 1. OTMlar ro'yxatini olish
  Future<List<XonadoshUniversity>> getUniversities({
    String? city,
    String? query,
  }) async {
    final res = await _api.getUniversities(city: city, query: query);
    if (res['ok'] == true && res['universities'] is List) {
      final list = res['universities'] as List;
      return list
          .map((e) => XonadoshUniversity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (res['ok'] == true) return [];
    throw Exception((res['error'] ?? 'Universitetlar yuklanmadi').toString());
  }

  /// 2. Uy-joy va ijara e'lonlarini olish
  Future<List<XonadoshListing>> getListings({
    int? universityId,
    String? type,
    String? gender,
    String? city,
    String? district,
    int? rooms,
    double? minPrice,
    double? maxPrice,
    String? query,
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _api.getListings(
      universityId: universityId,
      type: type,
      gender: gender,
      city: city,
      district: district,
      rooms: rooms,
      minPrice: minPrice,
      maxPrice: maxPrice,
      query: query,
      limit: limit,
      offset: offset,
    );

    if (res['ok'] == true && res['listings'] is List) {
      final list = res['listings'] as List;
      return list
          .map((e) => XonadoshListing.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (res['ok'] == true) return [];
    throw Exception((res['error'] ?? 'E\'lonlar yuklanmadi').toString());
  }

  /// 3. Bitta e'lon tafsilotini olish
  Future<XonadoshListing?> getListingDetail(int listingId) async {
    final res = await _api.getListings(listingId: listingId, limit: 1);
    if (res['ok'] == true && res['listings'] is List) {
      final list = res['listings'] as List;
      if (list.isEmpty) return null;
      return XonadoshListing.fromJson(Map<String, dynamic>.from(list.first as Map));
    }
    throw Exception((res['error'] ?? 'E\'lon topilmadi').toString());
  }

  /// 4. Yangi e'lon yaratish
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async {
    return _api.createListing(data);
  }

  /// Rasm yuklash (web + mobil)
  Future<String?> uploadPhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final res = await _api.uploadPhoto(bytes: bytes, filename: filename);
    if (res['ok'] == true && res['url'] is String) {
      return res['url'] as String;
    }
    return null;
  }

  /// 5. E'lonni o'chirish
  Future<Map<String, dynamic>> deleteListing(int listingId) async {
    return _api.deleteListing(listingId);
  }

  /// 6. Transport va masofa hisoblash
  Future<XonadoshCommuteEstimate?> calculateCommute({
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    int? universityId,
    int? listingId,
  }) async {
    final res = await _api.calculateCommute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      universityId: universityId,
      listingId: listingId,
    );
    if (res['ok'] == true) {
      return XonadoshCommuteEstimate.fromJson(res);
    }
    return null;
  }

  /// 7. Xonadosh anketalari va AI moslik
  Future<List<XonadoshProfile>> getMatchingRoommates({
    String? username,
    int? universityId,
    String? gender,
    String? sleepSchedule,
    String? cleanliness,
    String? studyHabit,
    String? cookingHabit,
    String? smokingHabit,
    double? budgetMin,
    double? budgetMax,
    String? lang,
  }) async {
    final res = await _api.getMatchingRoommates(
      username: username,
      universityId: universityId,
      gender: gender,
      sleepSchedule: sleepSchedule,
      cleanliness: cleanliness,
      studyHabit: studyHabit,
      cookingHabit: cookingHabit,
      smokingHabit: smokingHabit,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      lang: lang,
    );

    if (res['ok'] == true && res['matches'] is List) {
      final list = res['matches'] as List;
      return list
          .map((e) => XonadoshProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (res['ok'] == true) return [];
    throw Exception((res['error'] ?? 'Mos xonadoshlar yuklanmadi').toString());
  }

  static const _kProfilePref = 'xonadosh_my_saved_profile';
  static const _kDraftPref = 'xonadosh_anketa_draft_v2';

  /// Drop in-memory + on-disk user data so the next account cannot see it.
  Future<void> clearUserLocalData() async {
    _karmaCache = null;
    _pollsCache = null;
    _financesCache = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfilePref);
      await prefs.remove(_kDraftPref);
      await prefs.remove(_kKarmaPref);
      await prefs.remove(_kPollsPref);
      await prefs.remove(_kFinancesPref);
    } catch (_) {}
  }

  /// 8. Shaxsiy anketani olish, saqlash va o'chirish
  Future<XonadoshProfile?> getMyProfile([String? username]) async {
    XonadoshProfile? cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_kProfilePref);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map) {
          cached = XonadoshProfile.fromJson(Map<String, dynamic>.from(decoded));
          final cacheUser = cached.username.trim().toLowerCase();
          final wantUser = (username ?? '').trim().toLowerCase();
          if (wantUser.isNotEmpty &&
              cacheUser.isNotEmpty &&
              cacheUser != wantUser) {
            await prefs.remove(_kProfilePref);
            cached = null;
          }
        }
      }
    } catch (_) {
      cached = null;
    }

    if (username != null && username.isNotEmpty) {
      final remote = await _fetchAndCacheRemoteProfile(username);
      return remote ?? cached;
    }
    return cached;
  }

  Future<XonadoshProfile?> _fetchAndCacheRemoteProfile(String username) async {
    try {
      final res = await _api.getProfiles(username: username);
      if (res['ok'] == true && res['profile'] != null && res['profile'] is Map) {
        final profile = XonadoshProfile.fromJson(Map<String, dynamic>.from(res['profile'] as Map));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kProfilePref, jsonEncode(profile.toJson()));
        return profile;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> data) async {
    final res = await _api.saveProfile(data);
    if (res['ok'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final profileData = Map<String, dynamic>.from(data);
        if (res['profile_id'] != null) {
          profileData['id'] = res['profile_id'];
        }
        await prefs.setString(_kProfilePref, jsonEncode(profileData));
      } catch (_) {}
    }
    return res;
  }

  Future<bool> deleteMyProfile([String? username]) async {
    try {
      final res = await _api.saveProfile({
        'action': 'delete',
        'username': ?username,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfilePref);
      await prefs.remove(_kDraftPref);
      return res['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 9. Navbatchilik jadvali (Chores)
  Future<({String todayDay, List<XonadoshChore> todayDuties, List<XonadoshChore> allChores})> getChores({
    String groupCode = 'home_default',
  }) async {
    final res = await _api.getChores(groupCode: groupCode);
    if (res['ok'] == true) {
      final todayDay = (res['today_day'] ?? 'dushanba').toString();
      final todayList = (res['today_duties'] as List? ?? [])
          .map((e) => XonadoshChore.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final allList = (res['all_chores'] as List? ?? [])
          .map((e) => XonadoshChore.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return (todayDay: todayDay, todayDuties: todayList, allChores: allList);
    }
    throw Exception((res['error'] ?? 'Navbatchilik yuklanmadi').toString());
  }

  Future<bool> toggleChoreDone({
    required int choreId,
    required bool isCompleted,
    String groupCode = 'home_default',
  }) async {
    final res = await _api.toggleChoreDone(
      choreId: choreId,
      isCompleted: isCompleted,
      groupCode: groupCode,
    );
    return res['ok'] == true;
  }

  Future<Map<String, dynamic>> addChore(Map<String, dynamic> data) async {
    return _api.addChore(data);
  }

  Future<bool> assignChore({
    required int choreId,
    required String assignedName,
    String groupCode = 'home_default',
  }) async {
    final res = await _api.assignChore(
      choreId: choreId,
      assignedName: assignedName,
      groupCode: groupCode,
    );
    return res['ok'] == true;
  }

  /// 10. Retseptlar va haftalik menyu
  Future<({List<XonadoshRecipe> recipes, List<XonadoshMealPlan> mealPlans})> getRecipesAndMealPlan({
    String groupCode = 'home_default',
  }) async {
    final res = await _api.getRecipesAndMealPlan(groupCode: groupCode);
    if (res['ok'] == true) {
      final rList = (res['recipes'] as List? ?? [])
          .map((e) => XonadoshRecipe.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final pList = (res['weekly_meal_plan'] as List? ?? [])
          .map((e) => XonadoshMealPlan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return (recipes: rList, mealPlans: pList);
    }
    throw Exception((res['error'] ?? 'Taomnoma yuklanmadi').toString());
  }

  Future<bool> setMealPlan(Map<String, dynamic> data) async {
    final res = await _api.setMealPlan(data);
    return res['ok'] == true;
  }

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> data) async {
    return _api.createRecipe(data);
  }

  /// 11. Bozorlik va real narxlar hisoblagichi
  Future<XonadoshGroceryCalculation?> calculateGrocery({
    int roommateCount = 4,
    List<int>? recipeIds,
    String groupCode = 'home_default',
  }) async {
    try {
      final res = await _api.calculateGrocery(
        roommateCount: roommateCount,
        recipeIds: recipeIds,
        groupCode: groupCode,
      );
      if (res['ok'] == true) {
        return XonadoshGroceryCalculation.fromJson(res);
      }
    } catch (_) {}

    // Offline / Standalone Fallback based on 21 student meals & realistic Uzbekistan 2026 market prices
    final scale = roommateCount / 4.0;
    final buxankaCount = (36 * scale).round();
    final patirCount = (6 * scale).round();
    final totalBreadCost = buxankaCount * 3000 + patirCount * 5000;

    final fallbackItems = [
      XonadoshGroceryItem(
        key: 'chicken_fillet',
        nameUz: "Tovuq filesi (Toza lahm)",
        category: "Go'sht",
        unit: 'kg',
        quantity: double.parse((3.8 * scale).toStringAsFixed(2)),
        unitPriceUzs: 45000,
        minPriceUzs: 42000,
        maxPriceUzs: 49000,
        totalPriceUzs: (3.8 * scale * 45000).roundToDouble(),
        cheapestSource: "Chorsu / Sergeli parrandachilik paviloni",
        buyingTips: "10 kg quti bilan ulgurji olinganda 40 000–42 000 so‘m/kg",
        usedForMeals: ['🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'bread_bukhanka',
        nameUz: "Non (Qolipli Buxanka)",
        category: "Non mahsulotlari",
        unit: 'dona',
        quantity: buxankaCount.toDouble(),
        unitPriceUzs: 3000,
        minPriceUzs: 2800,
        maxPriceUzs: 3500,
        totalPriceUzs: (buxankaCount * 3000).toDouble(),
        cheapestSource: "Mahalla novvoyxonasi",
        buyingTips: "Kuniga yangi issiq olinadi (ertalab va kechqurun)",
        usedForMeals: ['🌅 Nonushta', '🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'eggs',
        nameUz: "Tuxum (Saralangan C-1)",
        category: "Sut & Tuxum",
        unit: 'dona',
        quantity: (64 * scale).roundToDouble(),
        unitPriceUzs: 1600,
        minPriceUzs: 1400,
        maxPriceUzs: 1800,
        totalPriceUzs: ((64 * scale).round() * 1600).toDouble(),
        cheapestSource: "Chorsu tuxum qatori / Parrandachilik savdo rastasi",
        buyingTips: "30 donalik lotok bilan olish tejamkor (lotogi 42 000 so‘m)",
        usedForMeals: ['🌅 Nonushta', '🌙 Kechki', '🌤 Tushlik'],
      ),
      XonadoshGroceryItem(
        key: 'tomato',
        nameUz: "Pomidor (Yangi qizil)",
        category: "Sabzavot",
        unit: 'kg',
        quantity: double.parse((3.4 * scale).toStringAsFixed(2)),
        unitPriceUzs: 14000,
        minPriceUzs: 10000,
        maxPriceUzs: 19000,
        totalPriceUzs: (3.4 * scale * 14000).roundToDouble(),
        cheapestSource: "Chorsu dehqon bozori (17:00 dan keyin)",
        buyingTips: "Kechqurun 17:00 dan so‘ng dehqonlar 20–30% arzonlashtirib sotadi",
        usedForMeals: ['🌅 Nonushta', '🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'rice_alanga',
        nameUz: "Guruch (Alanga saralangan)",
        category: "Don & Dukkak",
        unit: 'kg',
        quantity: double.parse((1.6 * scale).toStringAsFixed(2)),
        unitPriceUzs: 19000,
        minPriceUzs: 17000,
        maxPriceUzs: 22000,
        totalPriceUzs: (1.6 * scale * 19000).roundToDouble(),
        cheapestSource: "Qo‘yliq ulgurji dehqon bozori",
        buyingTips: "Talabalar palovi va mastavasi uchun eng to‘yimli va tejamkor",
        usedForMeals: ['🌙 Kechki', '🌤 Tushlik'],
      ),
      XonadoshGroceryItem(
        key: 'bread_patir',
        nameUz: "Non (Tandir Patir / Obi non)",
        category: "Non mahsulotlari",
        unit: 'dona',
        quantity: patirCount.toDouble(),
        unitPriceUzs: 5000,
        minPriceUzs: 4000,
        maxPriceUzs: 8000,
        totalPriceUzs: (patirCount * 5000).toDouble(),
        cheapestSource: "Tandir novvoyxonalari",
        buyingTips: "Palov va kechki ovqat kunlari tandirdan issiq olinadi",
        usedForMeals: ['🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'oil_vegetable',
        nameUz: "O‘simlik yog‘i (Pista yog‘i)",
        category: "Yog‘ & Moy",
        unit: 'litr',
        quantity: double.parse((1.6 * scale).toStringAsFixed(2)),
        unitPriceUzs: 18000,
        minPriceUzs: 16500,
        maxPriceUzs: 20000,
        totalPriceUzs: (1.6 * scale * 18000).roundToDouble(),
        cheapestSource: "Qo‘yliq ulgurji baqqollik / Havas aksiyasi",
        buyingTips: "5 litrlik idishda olinganda 1 litri 16 500 so‘mga to‘g‘ri keladi",
        usedForMeals: ['🌅 Nonushta', '🌙 Kechki', '🌤 Tushlik'],
      ),
      XonadoshGroceryItem(
        key: 'potato',
        nameUz: "Kartoshka (Qizil / Oq)",
        category: "Sabzavot",
        unit: 'kg',
        quantity: double.parse((4.1 * scale).toStringAsFixed(2)),
        unitPriceUzs: 6000,
        minPriceUzs: 5000,
        maxPriceUzs: 7500,
        totalPriceUzs: (4.1 * scale * 6000).roundToDouble(),
        cheapestSource: "Qo‘yliq mashinalar ulgurji qatori",
        buyingTips: "1 qop (25 kg) olinganda 5 000 so‘m/kg dan beriladi",
        usedForMeals: ['🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'tea_green_black',
        nameUz: "Ko‘k choy (95-nav, 100g pachka)",
        category: "Baqqollik",
        unit: 'pachka',
        quantity: (2 * scale).clamp(1.0, 10.0).roundToDouble(),
        unitPriceUzs: 10000,
        minPriceUzs: 8000,
        maxPriceUzs: 14000,
        totalPriceUzs: ((2 * scale).clamp(1.0, 10.0).round() * 10000).toDouble(),
        cheapestSource: "Chorsu choy rastasi",
        buyingTips: "Talabalar uchun klassik 95-nav ko‘k choy",
        usedForMeals: ['🌅 Nonushta', '🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'sugar',
        nameUz: "Shakar (1 kg)",
        category: "Baqqollik",
        unit: 'kg',
        quantity: double.parse((1.4 * scale).toStringAsFixed(2)),
        unitPriceUzs: 14000,
        minPriceUzs: 12500,
        maxPriceUzs: 16000,
        totalPriceUzs: (1.4 * scale * 14000).roundToDouble(),
        cheapestSource: "Qo‘yliq ulgurji shakar bozori (5 kg xaltada)",
        buyingTips: "5 kg xaltada 12 500 so‘m/kg",
        usedForMeals: ['🌅 Nonushta', '🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'pasta_makaron',
        nameUz: "Makaron (450g pachka)",
        category: "Baqqollik",
        unit: 'pachka',
        quantity: double.parse((1.5 * scale).toStringAsFixed(2)),
        unitPriceUzs: 9500,
        minPriceUzs: 8000,
        maxPriceUzs: 12000,
        totalPriceUzs: (1.5 * scale * 9500).roundToDouble(),
        cheapestSource: "Havas / FixPrice / Ulgurji savdo",
        buyingTips: "10 pachkalik blokda olinganda 8 000 so‘m/pachka",
        usedForMeals: ['🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'onion',
        nameUz: "Piyoz (Oshbop sariq)",
        category: "Sabzavot",
        unit: 'kg',
        quantity: double.parse((3.4 * scale).toStringAsFixed(2)),
        unitPriceUzs: 4000,
        minPriceUzs: 3200,
        maxPriceUzs: 5000,
        totalPriceUzs: (3.4 * scale * 4000).roundToDouble(),
        cheapestSource: "Qo‘yliq ulgurji qator",
        buyingTips: "1 qop (30 kg) olinganda 3 200 so‘m/kg",
        usedForMeals: ['🌅 Nonushta', '🌙 Kechki', '🌤 Tushlik'],
      ),
      XonadoshGroceryItem(
        key: 'salt_spices',
        nameUz: "Ziravorlar to‘plami (Zira, murch, tuz)",
        category: "Ziravor",
        unit: 'to‘plam',
        quantity: 1.0,
        unitPriceUzs: 8000,
        minPriceUzs: 5000,
        maxPriceUzs: 12000,
        totalPriceUzs: 8000.0,
        cheapestSource: "Chorsu ziravorchilar qatori",
        buyingTips: "Osh va sho‘rvalar uchun saralangan zira va murch",
        usedForMeals: ['🌙 Kechki', '🌤 Tushlik'],
      ),
      XonadoshGroceryItem(
        key: 'greens',
        nameUz: "Ko‘katlar (Kashnich, ukrop, petrushka)",
        category: "Sabzavot",
        unit: "bog'",
        quantity: (5 * scale).roundToDouble(),
        unitPriceUzs: 2500,
        minPriceUzs: 2000,
        maxPriceUzs: 3500,
        totalPriceUzs: ((5 * scale).round() * 2500).toDouble(),
        cheapestSource: "Chorsu ko‘katlar rastasi",
        buyingTips: "5 ta bog‘ birgalikda olinganda 8 000–10 000 so‘m",
        usedForMeals: ['🌤 Tushlik', '🌙 Kechki'],
      ),
      XonadoshGroceryItem(
        key: 'milk',
        nameUz: "Sut (Pasterizatsiyalangan)",
        category: "Sut & Tuxum",
        unit: 'litr',
        quantity: double.parse((1.2 * scale).toStringAsFixed(2)),
        unitPriceUzs: 10000,
        minPriceUzs: 8500,
        maxPriceUzs: 12000,
        totalPriceUzs: (1.2 * scale * 10000).roundToDouble(),
        cheapestSource: "Mahalliy sut do‘koni / Ferma savdo nuqtasi",
        buyingTips: "Ertalabki bo‘tqa va sutli choy uchun",
        usedForMeals: ['🌅 Nonushta'],
      ),
      XonadoshGroceryItem(
        key: 'cucumber',
        nameUz: "Bodring (Mayda / Tillo)",
        category: "Sabzavot",
        unit: 'kg',
        quantity: double.parse((1.0 * scale).toStringAsFixed(2)),
        unitPriceUzs: 9000,
        minPriceUzs: 7000,
        maxPriceUzs: 13000,
        totalPriceUzs: (1.0 * scale * 9000).roundToDouble(),
        cheapestSource: "Chorsu / Qo‘yliq dehqon bozori",
        buyingTips: "Nonushta va lanchboks salati uchun yangi bodring",
        usedForMeals: ['🌤 Tushlik', '🌅 Nonushta'],
      ),
    ];

    double totalCost = 0.0;
    for (final it in fallbackItems) {
      totalCost += it.totalPriceUzs;
    }

    final perPerson = (totalCost / roommateCount).round();
    final perPersonDaily = (perPerson / 7).round();

    return XonadoshGroceryCalculation(
      roommateCount: roommateCount,
      days: 7,
      mealsPerDay: 3,
      totalMealSlots: 21,
      totalCostUzs: totalCost.round(),
      perPersonUzs: perPerson,
      perPersonDailyUzs: perPersonDaily,
      perPersonDailyUsd: double.parse((perPersonDaily / 12800).toStringAsFixed(2)),
      cheapestMarket: 'Qo‘yliq ulgurji dehqon bozori (Shanba/Yakshanba 07:00–09:00)',
      shoppingDay: 'Shanba ertalab (Navbatchi xonadoshlar)',
      items: fallbackItems,
      byCategorySummary: [
        {'category': "Go'sht", 'total_uzs': (3.8 * scale * 45000).round(), 'item_count': 1},
        {'category': "Non mahsulotlari", 'total_uzs': totalBreadCost, 'item_count': 2},
        {'category': "Sut & Tuxum", 'total_uzs': ((64 * scale).round() * 1600 + 1.2 * scale * 10000).round(), 'item_count': 2},
        {'category': "Sabzavot", 'total_uzs': (3.4 * scale * 14000 + 4.1 * scale * 6000 + 3.4 * scale * 4000).round(), 'item_count': 4},
      ],
      breadBreakdown: {
        'breakfast_lunch_buxanka': (28 * scale).round(),
        'dinner_buxanka': (8 * scale).round(),
        'dinner_patir': patirCount,
        'total_buxanka': buxankaCount,
        'total_patir': patirCount,
        'weekly_total_bread_spend': totalBreadCost,
      },
    );
  }

  // ── Local offline caches (API ishlamaganda ham to‘liq funksionallik) ──
  Map<String, dynamic>? _karmaCache;
  Map<String, dynamic>? _pollsCache;
  Map<String, dynamic>? _financesCache;

  static const _kKarmaPref = 'xd_karma_v1';
  static const _kPollsPref = 'xd_polls_v1';
  static const _kFinancesPref = 'xd_finances_v1';

  Future<void> _saveJson(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> _defaultBadges() => [
        {
          'key': 'cleanliness_master',
          'name': 'Tozalik ustasi',
          'icon': '🧹',
          'description': 'Xonani chinnidek toza tutgani uchun'
        },
        {
          'key': 'chef_pro',
          'name': 'Mohir oshpaz',
          'icon': '👨‍🍳',
          'description': 'Mazali taomlar tayyorlagani uchun'
        },
        {
          'key': 'ontime_payer',
          'name': 'Vaqtida to‘lovchi',
          'icon': '⏱',
          'description': 'Ijara va kommunalni o‘z vaqtida to‘lagani uchun'
        },
        {
          'key': 'quiet_peacekeeper',
          'name': 'Tinchlik posboni',
          'icon': '🤫',
          'description': 'Kechasi osoyishtalikni saqlagani uchun'
        },
        {
          'key': 'helpful_friend',
          'name': 'Do‘stona xonadosh',
          'icon': '🤝',
          'description': 'Yordamga shay va ishonchli bo‘lgani uchun'
        },
        {
          'key': 'wake_up_hero',
          'name': 'Tonggi uyg‘otuvchi',
          'icon': '⏰',
          'description': 'Darsga kechikmaslik uchun uyg‘otgani uchun'
        },
      ];

  Map<String, dynamic> _rebuildKarmaLeaderboard(Map<String, dynamic> cache) {
    final roommates = (cache['roommates'] as List?)?.map((e) => e.toString()).toList() ??
        ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];
    final history = (cache['history'] as List?) ?? [];
    final stats = <String, Map<String, dynamic>>{};
    for (final name in roommates) {
      stats[name] = {
        'name': name,
        'total_points': 0,
        'badges_count': 0,
        'badges_summary': <String, Map<String, dynamic>>{},
        'recent_praises': <Map<String, dynamic>>[],
      };
    }
    for (final raw in history) {
      if (raw is! Map) continue;
      final r = Map<String, dynamic>.from(raw);
      final to = (r['to_name'] ?? '').toString();
      if (to.isEmpty) continue;
      stats.putIfAbsent(
        to,
        () => {
          'name': to,
          'total_points': 0,
          'badges_count': 0,
          'badges_summary': <String, Map<String, dynamic>>{},
          'recent_praises': <Map<String, dynamic>>[],
        },
      );
      final pts = (r['points'] as num?)?.toInt() ?? 1;
      final bKey = (r['badge_key'] ?? 'helpful_friend').toString();
      final bName = (r['badge_name'] ?? 'Do‘stona xonadosh').toString();
      stats[to]!['total_points'] = (stats[to]!['total_points'] as int) + pts;
      stats[to]!['badges_count'] = (stats[to]!['badges_count'] as int) + 1;
      final summary = stats[to]!['badges_summary'] as Map<String, Map<String, dynamic>>;
      summary.putIfAbsent(bKey, () => {'key': bKey, 'name': bName, 'count': 0});
      summary[bKey]!['count'] = (summary[bKey]!['count'] as int) + 1;
      final praises = stats[to]!['recent_praises'] as List<Map<String, dynamic>>;
      if (praises.length < 3) {
        praises.add({
          'from_name': r['from_name'] ?? '',
          'badge_name': bName,
          'comment': r['comment'] ?? '',
          'created_at': r['created_at'] ?? '',
        });
      }
    }
    final leaderboard = stats.values.map((m) {
      final summary = (m['badges_summary'] as Map<String, Map<String, dynamic>>).values.toList();
      return {
        'name': m['name'],
        'total_points': m['total_points'],
        'badges_count': m['badges_count'],
        'badges_summary': summary,
        'recent_praises': m['recent_praises'],
      };
    }).toList()
      ..sort((a, b) => (b['total_points'] as int).compareTo(a['total_points'] as int));
    cache['leaderboard'] = leaderboard;
    return cache;
  }

  Map<String, dynamic> _defaultKarma(String groupCode) {
    final history = [
      {
        'id': 1,
        'from_name': 'Azizbek',
        'to_name': 'Jasur',
        'badge_key': 'chef_pro',
        'badge_name': 'Mohir oshpaz',
        'points': 3,
        'comment': 'Dushanba kungi palov juda mazali chiqdi!',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 2,
        'from_name': 'Jasur',
        'to_name': 'Bekzod',
        'badge_key': 'cleanliness_master',
        'badge_name': 'Tozalik ustasi',
        'points': 2,
        'comment': 'Oshxona va zalni chinnidek yuvib qo‘ydi',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 3,
        'from_name': 'Sardor',
        'to_name': 'Azizbek',
        'badge_key': 'ontime_payer',
        'badge_name': 'Vaqtida to‘lovchi',
        'points': 3,
        'comment': 'Wi-Fi va svet pulini 1-bo‘lib to‘ladi',
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 4,
        'from_name': 'Bekzod',
        'to_name': 'Sardor',
        'badge_key': 'quiet_peacekeeper',
        'badge_name': 'Tinchlik posboni',
        'points': 2,
        'comment': 'Imtihon oldidan kechasi juda sokin muhit yaratdi',
        'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      },
      {
        'id': 5,
        'from_name': 'Jasur',
        'to_name': 'Azizbek',
        'badge_key': 'helpful_friend',
        'badge_name': 'Do‘stona xonadosh',
        'points': 2,
        'comment': 'Bozorlik yuklarini ko‘tarishda yordam berdi',
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
    ];
    return _rebuildKarmaLeaderboard({
      'ok': true,
      'group_code': groupCode,
      'available_badges': _defaultBadges(),
      'roommates': ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'],
      'history': history,
      'leaderboard': <Map<String, dynamic>>[],
    });
  }

  Map<String, dynamic> _defaultPolls(String groupCode) {
    final polls = [
      {
        'id': 1,
        'title': 'Kechasi 23:00 dan keyin mehmon chaqirmaslik qoidasi',
        'description':
            'Dars va imtihon mavsumida har kim to‘liq uxlab dam olishi uchun 23:00 dan so‘ng begona mehmonlarni chaqirmaslikni taklif qilaman.',
        'category': 'rules',
        'status': 'passed',
        'votes_yes': 3,
        'votes_no': 1,
        'votes_neutral': 0,
        'total_votes': 4,
        'yes_percent': 75,
        'no_percent': 25,
        'neutral_percent': 0,
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Har yakshanba umumiy "Generalka" tozalik kuni qilaylik',
        'description':
            'Yakshanba soat 10:00 da 4 kishi birgalikda 1 soat hamma xonalarni chuqur tozalasa, hafta davomida xona doim tartibli turadi.',
        'category': 'cleaning',
        'status': 'active',
        'votes_yes': 2,
        'votes_no': 0,
        'votes_neutral': 1,
        'total_votes': 3,
        'yes_percent': 67,
        'no_percent': 0,
        'neutral_percent': 33,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 3,
        'title': 'Wi-Fi tezligini oshirish va yangi tarifga o‘tish',
        'description':
            'Hozirgi internet 30 Mbps, kechqurun hammamiz ulanganda sekinlashyapti. 100 Mbps tarifga o‘tsak kishi boshiga oyiga atigi 12 000 so‘m qo‘shiladi.',
        'category': 'general',
        'status': 'active',
        'votes_yes': 2,
        'votes_no': 1,
        'votes_neutral': 1,
        'total_votes': 4,
        'yes_percent': 50,
        'no_percent': 25,
        'neutral_percent': 25,
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ];
    return {
      'ok': true,
      'group_code': groupCode,
      'active_count': polls.where((p) => p['status'] == 'active').length,
      'polls': polls,
    };
  }

  Map<String, dynamic> _rebuildFinanceSummary(Map<String, dynamic> cache) {
    final all = <Map<String, dynamic>>[
      ...((cache['rent_items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ...((cache['utility_items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ...((cache['expense_items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    ];
    int totalSpend = 0;
    int totalPending = 0;
    int rentTotal = 0;
    int utilTotal = 0;
    int expTotal = 0;
    final debts = <String, Map<String, dynamic>>{};

    for (final item in all) {
      final amt = (item['amount_uzs'] as num?)?.toInt() ?? 0;
      totalSpend += amt;
      final type = (item['type'] ?? '').toString();
      if (type == 'rent') {
        rentTotal += amt;
      } else if (type == 'utility') {
        utilTotal += amt;
      } else {
        expTotal += amt;
      }

      final splits = ((item['splits'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      int paidSum = 0;
      int pendingSum = 0;
      for (final s in splits) {
        final sAmt = (s['amount_uzs'] as num?)?.toInt() ?? 0;
        final isPaid = s['is_paid'] == true || s['is_paid'] == 1;
        if (isPaid) {
          paidSum += sAmt;
        } else {
          pendingSum += sAmt;
          totalPending += sAmt;
          final creditor = (item['paid_by'] ?? '').toString();
          final debtor = (s['name'] ?? '').toString();
          if (creditor.isNotEmpty &&
              creditor != 'Uy egasiga' &&
              debtor.isNotEmpty &&
              debtor != creditor) {
            final key = '$debtor->$creditor';
            debts.putIfAbsent(
              key,
              () => {
                'debtor': debtor,
                'creditor': creditor,
                'amount_uzs': 0,
                'reason': item['title'] ?? '',
              },
            );
            debts[key]!['amount_uzs'] =
                (debts[key]!['amount_uzs'] as int) + sAmt;
          }
        }
      }
      item['paid_amount_uzs'] = paidSum;
      item['pending_amount_uzs'] = pendingSum;
      item['status'] = pendingSum == 0
          ? 'settled'
          : (paidSum > 0 ? 'partially_paid' : 'pending');
      item['splits'] = splits;
    }

    cache['rent_items'] = all.where((e) => e['type'] == 'rent').toList();
    cache['utility_items'] = all.where((e) => e['type'] == 'utility').toList();
    cache['expense_items'] =
        all.where((e) => e['type'] == 'expense_split' || e['type'] == 'debt').toList();
    cache['all_items'] = all;
    cache['debt_balances'] = debts.values.toList();
    cache['summary'] = {
      'total_spend_uzs': totalSpend,
      'total_pending_uzs': totalPending,
      'rent_total_uzs': rentTotal,
      'utility_total_uzs': utilTotal,
      'expense_total_uzs': expTotal,
    };
    return cache;
  }

  Map<String, dynamic> _defaultFinances(String groupCode) {
    final rent = {
      'id': 1,
      'type': 'rent',
      'title': 'Oylik ijara to‘lovi (Joriy oy)',
      'amount_uzs': 4000000,
      'paid_by': 'Uy egasiga',
      'category': 'rent',
      'due_date': 'Har oyning 5-sanasi',
      'status': 'partially_paid',
      'paid_amount_uzs': 3000000,
      'pending_amount_uzs': 1000000,
      'splits': [
        {'name': 'Jasur', 'amount_uzs': 1000000, 'is_paid': true},
        {'name': 'Azizbek', 'amount_uzs': 1000000, 'is_paid': true},
        {'name': 'Bekzod', 'amount_uzs': 1000000, 'is_paid': false},
        {'name': 'Sardor', 'amount_uzs': 1000000, 'is_paid': true},
      ],
      'notes': 'Bekzod stipendiyasi tushishi bilan to‘laydi',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    };
    final electricity = {
      'id': 2,
      'type': 'utility',
      'title': 'Svet & Elektr energiyasi (Hisoblagich)',
      'amount_uzs': 180000,
      'paid_by': 'Jasur',
      'category': 'electricity',
      'due_date': '10-kungacha',
      'status': 'partially_paid',
      'paid_amount_uzs': 90000,
      'pending_amount_uzs': 90000,
      'splits': [
        {'name': 'Jasur', 'amount_uzs': 45000, 'is_paid': true},
        {'name': 'Azizbek', 'amount_uzs': 45000, 'is_paid': true},
        {'name': 'Bekzod', 'amount_uzs': 45000, 'is_paid': false},
        {'name': 'Sardor', 'amount_uzs': 45000, 'is_paid': false},
      ],
      'notes': 'Jasur Click orqali to‘lab qo‘ydi',
      'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    };
    final wifi = {
      'id': 3,
      'type': 'utility',
      'title': 'Optik Wi-Fi Internet (100 Mbps)',
      'amount_uzs': 140000,
      'paid_by': 'Sardor',
      'category': 'internet',
      'due_date': '1-kungacha',
      'status': 'settled',
      'paid_amount_uzs': 140000,
      'pending_amount_uzs': 0,
      'splits': [
        {'name': 'Jasur', 'amount_uzs': 35000, 'is_paid': true},
        {'name': 'Azizbek', 'amount_uzs': 35000, 'is_paid': true},
        {'name': 'Bekzod', 'amount_uzs': 35000, 'is_paid': true},
        {'name': 'Sardor', 'amount_uzs': 35000, 'is_paid': true},
      ],
      'notes': 'Hamma to‘liq hisob-kitob qildi',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    };
    final grocery = {
      'id': 4,
      'type': 'expense_split',
      'title': 'Katta bozorlik (Go‘sht, yog‘, guruch, sabzavot)',
      'amount_uzs': 320000,
      'paid_by': 'Azizbek',
      'category': 'grocery_shared',
      'due_date': 'Tezkor',
      'status': 'partially_paid',
      'paid_amount_uzs': 240000,
      'pending_amount_uzs': 80000,
      'splits': [
        {'name': 'Jasur', 'amount_uzs': 80000, 'is_paid': true},
        {'name': 'Azizbek', 'amount_uzs': 80000, 'is_paid': true},
        {'name': 'Bekzod', 'amount_uzs': 80000, 'is_paid': false},
        {'name': 'Sardor', 'amount_uzs': 80000, 'is_paid': true},
      ],
      'notes': 'Qo‘yliq bozoridan olingan oziq-ovqatlar',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    };

    return _rebuildFinanceSummary({
      'ok': true,
      'group_code': groupCode,
      'rent_items': [rent],
      'utility_items': [electricity, wifi],
      'expense_items': [grocery],
      'all_items': [rent, electricity, wifi, grocery],
      'debt_balances': <Map<String, dynamic>>[],
      'summary': <String, dynamic>{},
    });
  }

  /// 12. Obro' va Karma
  Future<XonadoshKarmaData> getKarma({String groupCode = 'home_default'}) async {
    if (_karmaCache != null) {
      return XonadoshKarmaData.fromJson(_karmaCache!);
    }
    try {
      final res = await _api.getKarma(groupCode: groupCode);
      if (res['ok'] == true) {
        _karmaCache = Map<String, dynamic>.from(res);
        await _saveJson(_kKarmaPref, _karmaCache!);
        return XonadoshKarmaData.fromJson(_karmaCache!);
      }
    } catch (_) {}

    final local = await _loadJson(_kKarmaPref);
    _karmaCache = local ?? _defaultKarma(groupCode);
    if (local == null) await _saveJson(_kKarmaPref, _karmaCache!);
    return XonadoshKarmaData.fromJson(_karmaCache!);
  }

  Future<Map<String, dynamic>> giveKarma(Map<String, dynamic> data) async {
    try {
      final res = await _api.giveKarma(data);
      if (res['ok'] == true) {
        _karmaCache = null;
        return res;
      }
    } catch (_) {}

    final groupCode = (data['group_code'] ?? 'home_default').toString();
    _karmaCache ??= (await _loadJson(_kKarmaPref)) ?? _defaultKarma(groupCode);
    final history = List<Map<String, dynamic>>.from(
      ((_karmaCache!['history'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final toName = (data['to_name'] ?? '').toString();
    final fromName = (data['from_name'] ?? 'Xonadosh').toString();
    if (toName.isEmpty) {
      return {'ok': false, 'error': 'Xonadosh tanlanishi shart'};
    }
    if (toName.toLowerCase() == fromName.toLowerCase()) {
      return {'ok': false, 'error': 'O‘zingizga obro‘ bera olmaysiz!'};
    }
    final badgeName = (data['badge_name'] ?? 'Do‘stona xonadosh').toString();
    final points = (data['points'] as num?)?.toInt() ?? 1;
    history.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'from_name': fromName,
      'to_name': toName,
      'badge_key': data['badge_key'] ?? 'helpful_friend',
      'badge_name': badgeName,
      'points': points,
      'comment': data['comment'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
    _karmaCache!['history'] = history;
    final rms = List<String>.from(
      ((_karmaCache!['roommates'] as List?) ?? []).map((e) => e.toString()),
    );
    if (!rms.contains(toName)) rms.add(toName);
    _karmaCache!['roommates'] = rms;
    _rebuildKarmaLeaderboard(_karmaCache!);
    await _saveJson(_kKarmaPref, _karmaCache!);
    return {
      'ok': true,
      'message': '🎉 ${toName}ga "$badgeName" nishoni va +$points obro‘ berildi!',
    };
  }

  /// 13. Anonim masalalar & Ovoz berish
  Future<XonadoshPollsData> getPolls({String groupCode = 'home_default'}) async {
    if (_pollsCache != null) {
      return XonadoshPollsData.fromJson(_pollsCache!);
    }
    try {
      final res = await _api.getPolls(groupCode: groupCode);
      if (res['ok'] == true) {
        _pollsCache = Map<String, dynamic>.from(res);
        await _saveJson(_kPollsPref, _pollsCache!);
        return XonadoshPollsData.fromJson(_pollsCache!);
      }
    } catch (_) {}

    final local = await _loadJson(_kPollsPref);
    _pollsCache = local ?? _defaultPolls(groupCode);
    if (local == null) await _saveJson(_kPollsPref, _pollsCache!);
    return XonadoshPollsData.fromJson(_pollsCache!);
  }

  Future<Map<String, dynamic>> createPoll(Map<String, dynamic> data) async {
    try {
      final res = await _api.createPoll(data);
      if (res['ok'] == true) {
        _pollsCache = null;
        return res;
      }
    } catch (_) {}

    final groupCode = (data['group_code'] ?? 'home_default').toString();
    _pollsCache ??= (await _loadJson(_kPollsPref)) ?? _defaultPolls(groupCode);
    final polls = List<Map<String, dynamic>>.from(
      ((_pollsCache!['polls'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) {
      return {'ok': false, 'error': 'Masala sarlavhasi kiritilishi shart'};
    }
    final id = DateTime.now().millisecondsSinceEpoch;
    polls.insert(0, {
      'id': id,
      'title': title,
      'description': (data['description'] ?? '').toString(),
      'category': (data['category'] ?? 'rules').toString(),
      'status': 'active',
      'votes_yes': 0,
      'votes_no': 0,
      'votes_neutral': 0,
      'total_votes': 0,
      'yes_percent': 0,
      'no_percent': 0,
      'neutral_percent': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    _pollsCache!['polls'] = polls;
    _pollsCache!['active_count'] = polls.where((p) => p['status'] == 'active').length;
    await _saveJson(_kPollsPref, _pollsCache!);
    return {
      'ok': true,
      'message': 'Anonim masala muvaffaqiyatli o‘rtaga tashlandi!',
      'poll_id': id,
    };
  }

  Future<Map<String, dynamic>> votePoll({
    required int pollId,
    required String vote,
    String? voterHash,
    String groupCode = 'home_default',
  }) async {
    try {
      final res = await _api.votePoll(
        pollId: pollId,
        vote: vote,
        voterHash: voterHash,
        groupCode: groupCode,
      );
      if (res['ok'] == true) {
        _pollsCache = null;
        return res;
      }
    } catch (_) {}

    _pollsCache ??= (await _loadJson(_kPollsPref)) ?? _defaultPolls(groupCode);
    final polls = List<Map<String, dynamic>>.from(
      ((_pollsCache!['polls'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final idx = polls.indexWhere((p) => (p['id'] as num?)?.toInt() == pollId);
    if (idx < 0) return {'ok': false, 'error': 'Masala topilmadi'};
    final p = polls[idx];
    if ((p['status'] ?? '') != 'active') {
      return {'ok': false, 'error': 'Bu masala bo‘yicha ovoz berish yakunlangan'};
    }
    var yes = (p['votes_yes'] as num?)?.toInt() ?? 0;
    var no = (p['votes_no'] as num?)?.toInt() ?? 0;
    var neu = (p['votes_neutral'] as num?)?.toInt() ?? 0;
    if (vote == 'yes') {
      yes++;
    } else if (vote == 'no') {
      no++;
    } else {
      neu++;
    }
    final total = yes + no + neu;
    p['votes_yes'] = yes;
    p['votes_no'] = no;
    p['votes_neutral'] = neu;
    p['total_votes'] = total;
    p['yes_percent'] = total > 0 ? ((yes / total) * 100).round() : 0;
    p['no_percent'] = total > 0 ? ((no / total) * 100).round() : 0;
    p['neutral_percent'] = total > 0 ? ((neu / total) * 100).round() : 0;
    if (total >= 3) {
      if (yes > no) {
        p['status'] = 'passed';
      } else if (no > yes) {
        p['status'] = 'rejected';
      }
    }
    polls[idx] = p;
    _pollsCache!['polls'] = polls;
    _pollsCache!['active_count'] = polls.where((x) => x['status'] == 'active').length;
    await _saveJson(_kPollsPref, _pollsCache!);
    return {
      'ok': true,
      'message': 'Ovozingiz anonim tarzda qabul qilindi!',
      'poll_id': pollId,
      'user_vote': vote,
    };
  }

  Future<Map<String, dynamic>> closePoll({
    required int pollId,
    String status = 'closed',
    String groupCode = 'home_default',
  }) async {
    try {
      final res = await _api.closePoll(
        pollId: pollId,
        status: status,
        groupCode: groupCode,
      );
      if (res['ok'] == true) {
        _pollsCache = null;
        return res;
      }
    } catch (_) {}

    _pollsCache ??= (await _loadJson(_kPollsPref)) ?? _defaultPolls(groupCode);
    final polls = List<Map<String, dynamic>>.from(
      ((_pollsCache!['polls'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final idx = polls.indexWhere((p) => (p['id'] as num?)?.toInt() == pollId);
    if (idx >= 0) {
      polls[idx]['status'] = status;
      _pollsCache!['polls'] = polls;
      _pollsCache!['active_count'] =
          polls.where((x) => x['status'] == 'active').length;
      await _saveJson(_kPollsPref, _pollsCache!);
    }
    return {'ok': true, 'message': 'Masala yakunlandi'};
  }

  /// 14. Moliya, Ijara, Kommunal va Qarz
  Future<XonadoshFinancesData> getFinances({String groupCode = 'home_default'}) async {
    if (_financesCache != null) {
      return XonadoshFinancesData.fromJson(_financesCache!);
    }
    try {
      final res = await _api.getFinances(groupCode: groupCode);
      if (res['ok'] == true) {
        _financesCache = Map<String, dynamic>.from(res);
        await _saveJson(_kFinancesPref, _financesCache!);
        return XonadoshFinancesData.fromJson(_financesCache!);
      }
    } catch (_) {}

    final local = await _loadJson(_kFinancesPref);
    _financesCache = local ?? _defaultFinances(groupCode);
    if (local == null) await _saveJson(_kFinancesPref, _financesCache!);
    return XonadoshFinancesData.fromJson(_financesCache!);
  }

  Future<Map<String, dynamic>> addFinance(Map<String, dynamic> data) async {
    try {
      final res = await _api.addFinance(data);
      if (res['ok'] == true) {
        _financesCache = null;
        return res;
      }
    } catch (_) {}

    final groupCode = (data['group_code'] ?? 'home_default').toString();
    _financesCache ??=
        (await _loadJson(_kFinancesPref)) ?? _defaultFinances(groupCode);
    final type = (data['type'] ?? 'expense_split').toString();
    final title = (data['title'] ?? '').toString().trim();
    final amount = (data['amount_uzs'] as num?)?.toInt() ?? 0;
    final paidBy = (data['paid_by'] ?? 'Jasur').toString();
    if (title.isEmpty || amount <= 0) {
      return {'ok': false, 'error': 'To‘lov nomi va summa kiritilishi shart'};
    }
    final members = ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];
    final per = (amount / members.length).round();
    final splits = members
        .map(
          (m) => {
            'name': m,
            'amount_uzs': per,
            'is_paid': m == paidBy &&
                paidBy != 'Uy egasiga' &&
                (type == 'expense_split' || type == 'utility' || type == 'debt'),
          },
        )
        .toList();
    final item = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': type,
      'title': title,
      'amount_uzs': amount,
      'paid_by': paidBy,
      'category': (data['category'] ?? 'general').toString(),
      'due_date': (data['due_date'] ?? 'Joriy oy').toString(),
      'status': 'pending',
      'paid_amount_uzs': 0,
      'pending_amount_uzs': amount,
      'splits': splits,
      'notes': (data['notes'] ?? '').toString(),
      'created_at': DateTime.now().toIso8601String(),
    };
    final bucket = type == 'rent'
        ? 'rent_items'
        : (type == 'utility' ? 'utility_items' : 'expense_items');
    final list = List<Map<String, dynamic>>.from(
      ((_financesCache![bucket] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    list.insert(0, item);
    _financesCache![bucket] = list;
    _rebuildFinanceSummary(_financesCache!);
    await _saveJson(_kFinancesPref, _financesCache!);
    return {
      'ok': true,
      'message': 'To‘lov/xarajat qo‘shildi va xonadoshlar o‘rtasida taqsimlandi!',
      'finance_id': item['id'],
    };
  }

  Future<Map<String, dynamic>> toggleFinancePaid({
    required int financeId,
    required String memberName,
    required bool isPaid,
    String groupCode = 'home_default',
  }) async {
    try {
      final res = await _api.toggleFinancePaid(
        financeId: financeId,
        memberName: memberName,
        isPaid: isPaid,
        groupCode: groupCode,
      );
      if (res['ok'] == true) {
        _financesCache = null;
        return res;
      }
    } catch (_) {}

    _financesCache ??=
        (await _loadJson(_kFinancesPref)) ?? _defaultFinances(groupCode);
    bool found = false;
    for (final key in ['rent_items', 'utility_items', 'expense_items']) {
      final list = List<Map<String, dynamic>>.from(
        ((_financesCache![key] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      for (var i = 0; i < list.length; i++) {
        if ((list[i]['id'] as num?)?.toInt() != financeId) continue;
        final splits = List<Map<String, dynamic>>.from(
          ((list[i]['splits'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        for (final s in splits) {
          if ((s['name'] ?? '').toString().toLowerCase() ==
              memberName.toLowerCase()) {
            s['is_paid'] = isPaid;
            found = true;
          }
        }
        list[i]['splits'] = splits;
      }
      _financesCache![key] = list;
    }
    if (!found) return {'ok': false, 'error': 'To‘lov topilmadi'};
    _rebuildFinanceSummary(_financesCache!);
    await _saveJson(_kFinancesPref, _financesCache!);
    return {
      'ok': true,
      'message':
          'To‘lov holati yangilandi ($memberName: ${isPaid ? 'To‘ladi' : 'To‘lanmagan'})',
    };
  }

  Future<Map<String, dynamic>> deleteFinance({
    required int financeId,
    String groupCode = 'home_default',
  }) async {
    try {
      final res = await _api.deleteFinance(
        financeId: financeId,
        groupCode: groupCode,
      );
      if (res['ok'] == true) {
        _financesCache = null;
        return res;
      }
    } catch (_) {}

    _financesCache ??=
        (await _loadJson(_kFinancesPref)) ?? _defaultFinances(groupCode);
    for (final key in ['rent_items', 'utility_items', 'expense_items']) {
      final list = List<Map<String, dynamic>>.from(
        ((_financesCache![key] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      list.removeWhere((e) => (e['id'] as num?)?.toInt() == financeId);
      _financesCache![key] = list;
    }
    _rebuildFinanceSummary(_financesCache!);
    await _saveJson(_kFinancesPref, _financesCache!);
    return {'ok': true, 'message': 'To‘lov o‘chirildi'};
  }

  Future<Map<String, dynamic>> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  }) =>
      _api.submitReport(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
}
