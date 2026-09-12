import 'dart:convert';

/// Helper methods for robust JSON parsing
double _numToDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

int _numToInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

Map<String, dynamic>? _asStringKeyMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

/// OTM (Universitet / Institut) modeli
class XonadoshUniversity {
  const XonadoshUniversity({
    required this.id,
    required this.nameUz,
    required this.shortName,
    required this.city,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.nearestMetro,
    this.metroDistanceM,
  });

  final int id;
  final String nameUz;
  final String shortName;
  final String city;
  final String district;
  final String address;
  final double latitude;
  final double longitude;
  final String? nearestMetro;
  final int? metroDistanceM;

  factory XonadoshUniversity.fromJson(Map<String, dynamic> json) {
    return XonadoshUniversity(
      id: _numToInt(json['id']),
      nameUz: (json['name_uz'] ?? '').toString(),
      shortName: (json['short_name'] ?? '').toString(),
      city: (json['city'] ?? 'Toshkent').toString(),
      district: (json['district'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: _numToDouble(json['latitude'], 41.311081),
      longitude: _numToDouble(json['longitude'], 69.240562),
      nearestMetro: json['nearest_metro']?.toString(),
      metroDistanceM: json['metro_distance_m'] != null
          ? _numToInt(json['metro_distance_m'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_uz': nameUz,
        'short_name': shortName,
        'city': city,
        'district': district,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'nearest_metro': nearestMetro,
        'metro_distance_m': metroDistanceM,
      };
}

/// Transport va yo'nalish rejimi hisobi (Metro, Avtobus, Taksi, Piyoda)
class XonadoshCommuteMode {
  const XonadoshCommuteMode({
    required this.name,
    required this.timeMin,
    required this.fareUzs,
    required this.monthlyBudgetUzs,
    required this.icon,
    this.description = '',
    this.caloriesKcal = 0,
    this.station,
    this.recommended = false,
  });

  final String name;
  final int timeMin;
  final int fareUzs;
  final int monthlyBudgetUzs;
  final String icon;
  final String description;
  final int caloriesKcal;
  final String? station;
  final bool recommended;

  factory XonadoshCommuteMode.fromJson(Map<String, dynamic> json) {
    return XonadoshCommuteMode(
      name: (json['name'] ?? '').toString(),
      timeMin: _numToInt(json['time_min'], 15),
      fareUzs: _numToInt(json['fare_uzs'], 1700),
      monthlyBudgetUzs: _numToInt(json['monthly_budget_uzs'] ?? json['monthly_uzs'], 74800),
      icon: (json['icon'] ?? 'directions_bus').toString(),
      description: (json['description'] ?? '').toString(),
      caloriesKcal: _numToInt(json['calories_kcal'], 0),
      station: json['station']?.toString(),
      recommended: json['recommended'] == true,
    );
  }
}

/// Uydan OTMgacha to'liq transport kalkulyatori hisobi
class XonadoshCommuteEstimate {
  const XonadoshCommuteEstimate({
    required this.distanceKm,
    required this.metro,
    required this.bus,
    required this.taxi,
    required this.walk,
    this.bicycle,
    this.monthlyMetroSavingUzs = 0,
  });

  final double distanceKm;
  final XonadoshCommuteMode metro;
  final XonadoshCommuteMode bus;
  final XonadoshCommuteMode taxi;
  final XonadoshCommuteMode walk;
  final XonadoshCommuteMode? bicycle;
  final int monthlyMetroSavingUzs;

  factory XonadoshCommuteEstimate.fromJson(Map<String, dynamic> json) {
    final dist = _numToDouble(json['distance_km'] ?? json['distance']?['road_km'], 1.5);
    final modes = _asStringKeyMap(json['modes']) ?? json;

    return XonadoshCommuteEstimate(
      distanceKm: dist,
      metro: XonadoshCommuteMode.fromJson(_asStringKeyMap(modes['metro']) ?? {}),
      bus: XonadoshCommuteMode.fromJson(_asStringKeyMap(modes['bus']) ?? {}),
      taxi: XonadoshCommuteMode.fromJson(_asStringKeyMap(modes['taxi']) ?? {}),
      walk: XonadoshCommuteMode.fromJson(_asStringKeyMap(modes['walk']) ?? {}),
      bicycle: _asStringKeyMap(modes['bicycle']) != null
          ? XonadoshCommuteMode.fromJson(_asStringKeyMap(modes['bicycle'])!)
          : null,
      monthlyMetroSavingUzs: _numToInt(json['summary']?['monthly_metro_saving_uzs'], 0),
    );
  }
}

/// Uy-joy va ijara e'loni modeli
class XonadoshListing {
  const XonadoshListing({
    required this.id,
    this.userId,
    required this.username,
    required this.ownerName,
    required this.phoneNumber,
    this.telegramHandle,
    required this.type, // rent, roommate_wanted, sell, buy
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.pricePeriod, // month, day, total
    required this.city,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.nearestUniversityId,
    this.nearestUniversityName,
    this.nearestUniversityShort,
    this.distanceToUniversityKm,
    this.nearestMetro,
    required this.roomsCount,
    required this.floor,
    required this.totalFloors,
    required this.areaSqm,
    required this.targetGender, // boys, girls, family, any
    required this.targetTenant,
    required this.amenities,
    required this.photos,
    required this.status,
    this.viewsCount = 0,
    this.createdAt,
    this.commute,
  });

  final int id;
  final int? userId;
  final String username;
  final String ownerName;
  final String phoneNumber;
  final String? telegramHandle;
  final String type;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String pricePeriod;
  final String city;
  final String district;
  final String address;
  final double latitude;
  final double longitude;
  final int? nearestUniversityId;
  final String? nearestUniversityName;
  final String? nearestUniversityShort;
  final double? distanceToUniversityKm;
  final String? nearestMetro;
  final int roomsCount;
  final int floor;
  final int totalFloors;
  final double areaSqm;
  final String targetGender;
  final String targetTenant;
  final List<String> amenities;
  final List<String> photos;
  final String status;
  final int viewsCount;
  final String? createdAt;
  final XonadoshCommuteEstimate? commute;

  factory XonadoshListing.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.startsWith('[')) {
        try {
          final dec = jsonDecode(val);
          if (dec is List) return dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return XonadoshListing(
      id: _numToInt(json['id']),
      userId: json['user_id'] != null ? _numToInt(json['user_id']) : null,
      username: (json['username'] ?? '').toString(),
      ownerName: (json['owner_name'] ?? 'Uy egasi').toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      telegramHandle: json['telegram_handle']?.toString(),
      type: (json['type'] ?? 'rent').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _numToDouble(json['price']),
      currency: (json['currency'] ?? 'UZS').toString(),
      pricePeriod: (json['price_period'] ?? 'month').toString(),
      city: (json['city'] ?? 'Toshkent').toString(),
      district: (json['district'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: _numToDouble(json['latitude'], 41.311081),
      longitude: _numToDouble(json['longitude'], 69.240562),
      nearestUniversityId: json['nearest_university_id'] != null
          ? _numToInt(json['nearest_university_id'])
          : null,
      nearestUniversityName: json['nearest_university_name']?.toString(),
      nearestUniversityShort: json['nearest_university_short']?.toString(),
      distanceToUniversityKm: json['distance_to_university_km'] != null
          ? _numToDouble(json['distance_to_university_km'])
          : null,
      nearestMetro: json['nearest_metro']?.toString(),
      roomsCount: _numToInt(json['rooms_count'], 2),
      floor: _numToInt(json['floor'], 1),
      totalFloors: _numToInt(json['total_floors'], 4),
      areaSqm: _numToDouble(json['area_sqm'], 50.0),
      targetGender: (json['target_gender'] ?? 'any').toString(),
      targetTenant: (json['target_tenant'] ?? 'Talabalar uchun').toString(),
      amenities: parseList(json['amenities'] ?? json['amenities_json']),
      photos: parseList(json['photos'] ?? json['photos_json']),
      status: (json['status'] ?? 'active').toString(),
      viewsCount: _numToInt(json['views_count'], 0),
      createdAt: json['created_at']?.toString(),
      commute: _asStringKeyMap(json['commute']) != null
          ? XonadoshCommuteEstimate.fromJson(_asStringKeyMap(json['commute'])!)
          : null,
    );
  }
}

/// Talabalar anketasi va xonadosh profili
class XonadoshProfile {
  const XonadoshProfile({
    required this.id,
    this.userId,
    required this.username,
    required this.fullName,
    required this.phoneNumber,
    this.telegramHandle,
    this.avatarUrl,
    required this.gender,
    this.age = 20,
    this.universityId,
    this.universityName,
    this.universityShort,
    this.faculty,
    this.courseYear = 2,
    this.budgetMin = 500000.0,
    this.budgetMax = 1200000.0,
    this.targetDistrict = '',
    this.sleepSchedule = 'flexible', // early_bird, night_owl, flexible
    this.cleanliness = 'strict', // strict, moderate, relaxed
    this.studyHabit = 'silent', // silent, group, flexible
    this.cookingHabit = 'rotates', // cooks_self, eats_out, rotates
    this.smokingHabit = 'no', // no, yes
    this.socialHabit = 'balanced',
    this.aboutMe = '',
    this.lookingForText = '',
    this.status = 'looking',
    this.compatibilityScore,
    this.compatibilityLevel,
    this.matchReasons = const [],
  });

  final int id;
  final int? userId;
  final String username;
  final String fullName;
  final String phoneNumber;
  final String? telegramHandle;
  final String? avatarUrl;
  final String gender;
  final int age;
  final int? universityId;
  final String? universityName;
  final String? universityShort;
  final String? faculty;
  final int courseYear;
  final double budgetMin;
  final double budgetMax;
  final String targetDistrict;
  final String sleepSchedule;
  final String cleanliness;
  final String studyHabit;
  final String cookingHabit;
  final String smokingHabit;
  final String socialHabit;
  final String aboutMe;
  final String lookingForText;
  final String status;
  final int? compatibilityScore;
  final String? compatibilityLevel;
  final List<String> matchReasons;

  factory XonadoshProfile.fromJson(Map<String, dynamic> json) {
    final prof = _asStringKeyMap(json['profile']) ?? json;

    final reasonsRaw = json['match_reasons'];
    final reasons = <String>[];
    if (reasonsRaw is List) {
      for (final r in reasonsRaw) {
        if (r != null) reasons.add(r.toString());
      }
    }

    return XonadoshProfile(
      id: _numToInt(prof['id']),
      userId: prof['user_id'] != null ? _numToInt(prof['user_id']) : null,
      username: (prof['username'] ?? '').toString(),
      fullName: (prof['full_name'] ?? 'Talaba').toString(),
      phoneNumber: (prof['phone_number'] ?? '').toString(),
      telegramHandle: prof['telegram_handle']?.toString(),
      avatarUrl: prof['avatar_url']?.toString(),
      gender: (prof['gender'] ?? 'male').toString(),
      age: _numToInt(prof['age'], 20),
      universityId: prof['university_id'] != null
          ? _numToInt(prof['university_id'])
          : null,
      universityName: prof['university_name']?.toString(),
      universityShort: prof['university_short']?.toString(),
      faculty: prof['faculty']?.toString(),
      courseYear: _numToInt(prof['course_year'], 2),
      budgetMin: _numToDouble(prof['budget_min'], 500000.0),
      budgetMax: _numToDouble(prof['budget_max'], 1200000.0),
      targetDistrict: (prof['target_district'] ?? '').toString(),
      sleepSchedule: (prof['sleep_schedule'] ?? 'flexible').toString(),
      cleanliness: (prof['cleanliness'] ?? 'strict').toString(),
      studyHabit: (prof['study_habit'] ?? 'silent').toString(),
      cookingHabit: (prof['cooking_habit'] ?? 'rotates').toString(),
      smokingHabit: (prof['smoking_habit'] ?? 'no').toString(),
      socialHabit: (prof['social_habit'] ?? 'balanced').toString(),
      aboutMe: (prof['about_me'] ?? '').toString(),
      lookingForText: (prof['looking_for_text'] ?? '').toString(),
      status: (prof['status'] ?? 'looking').toString(),
      compatibilityScore: json['compatibility_score'] != null
          ? _numToInt(json['compatibility_score'])
          : null,
      compatibilityLevel: json['compatibility_level']?.toString(),
      matchReasons: reasons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'telegram_handle': telegramHandle,
      'avatar_url': avatarUrl,
      'gender': gender,
      'age': age,
      'university_id': universityId,
      'university_name': universityName,
      'university_short': universityShort,
      'faculty': faculty,
      'course_year': courseYear,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'target_district': targetDistrict,
      'sleep_schedule': sleepSchedule,
      'cleanliness': cleanliness,
      'study_habit': studyHabit,
      'cooking_habit': cookingHabit,
      'smoking_habit': smokingHabit,
      'social_habit': socialHabit,
      'about_me': aboutMe,
      'looking_for_text': lookingForText,
      'status': status,
      if (compatibilityScore != null) 'compatibility_score': compatibilityScore,
      if (compatibilityLevel != null) 'compatibility_level': compatibilityLevel,
      'match_reasons': matchReasons,
    };
  }

  XonadoshProfile copyWith({
    int? id,
    int? userId,
    String? username,
    String? fullName,
    String? phoneNumber,
    String? telegramHandle,
    String? avatarUrl,
    String? gender,
    int? age,
    int? universityId,
    String? universityName,
    String? universityShort,
    String? faculty,
    int? courseYear,
    double? budgetMin,
    double? budgetMax,
    String? targetDistrict,
    String? sleepSchedule,
    String? cleanliness,
    String? studyHabit,
    String? cookingHabit,
    String? smokingHabit,
    String? socialHabit,
    String? aboutMe,
    String? lookingForText,
    String? status,
    int? compatibilityScore,
    String? compatibilityLevel,
    List<String>? matchReasons,
  }) {
    return XonadoshProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegramHandle: telegramHandle ?? this.telegramHandle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      universityId: universityId ?? this.universityId,
      universityName: universityName ?? this.universityName,
      universityShort: universityShort ?? this.universityShort,
      faculty: faculty ?? this.faculty,
      courseYear: courseYear ?? this.courseYear,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      targetDistrict: targetDistrict ?? this.targetDistrict,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      cleanliness: cleanliness ?? this.cleanliness,
      studyHabit: studyHabit ?? this.studyHabit,
      cookingHabit: cookingHabit ?? this.cookingHabit,
      smokingHabit: smokingHabit ?? this.smokingHabit,
      socialHabit: socialHabit ?? this.socialHabit,
      aboutMe: aboutMe ?? this.aboutMe,
      lookingForText: lookingForText ?? this.lookingForText,
      status: status ?? this.status,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      compatibilityLevel: compatibilityLevel ?? this.compatibilityLevel,
      matchReasons: matchReasons ?? this.matchReasons,
    );
  }
}

/// Navbatchilik (Chore / Duty) modeli
class XonadoshChore {
  const XonadoshChore({
    required this.id,
    required this.groupCode,
    required this.title,
    required this.choreType, // cleaning, dishes, cooking, trash, shopping
    required this.dayOfWeek, // dushanba ... yakshanba
    required this.assignedName,
    required this.isCompleted,
    this.notes = '',
  });

  final int id;
  final String groupCode;
  final String title;
  final String choreType;
  final String dayOfWeek;
  final String assignedName;
  final bool isCompleted;
  final String notes;

  XonadoshChore copyWith({bool? isCompleted, String? assignedName}) {
    return XonadoshChore(
      id: id,
      groupCode: groupCode,
      title: title,
      choreType: choreType,
      dayOfWeek: dayOfWeek,
      assignedName: assignedName ?? this.assignedName,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes,
    );
  }

  factory XonadoshChore.fromJson(Map<String, dynamic> json) {
    return XonadoshChore(
      id: _numToInt(json['id']),
      groupCode: (json['group_code'] ?? 'home_default').toString(),
      title: (json['title'] ?? '').toString(),
      choreType: (json['chore_type'] ?? 'cleaning').toString(),
      dayOfWeek: (json['day_of_week'] ?? 'dushanba').toString(),
      assignedName: (json['assigned_name'] ?? 'Xonadosh').toString(),
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1 || json['is_completed']?.toString() == '1',
      notes: (json['notes'] ?? '').toString(),
    );
  }
}

/// Retsept masallig'i
class XonadoshRecipeIngredient {
  const XonadoshRecipeIngredient({
    required this.key,
    required this.name,
    required this.qtyPerPerson,
    required this.unit,
  });

  final String key;
  final String name;
  final double qtyPerPerson;
  final String unit;

  String get nameUz => name;

  factory XonadoshRecipeIngredient.fromJson(Map<String, dynamic> json) {
    return XonadoshRecipeIngredient(
      key: (json['key'] ?? '').toString(),
      name: (json['name_uz'] ?? json['name'] ?? '').toString(),
      qtyPerPerson: _numToDouble(json['amount_per_person'] ?? json['qty_per_person'], 0.1),
      unit: (json['unit'] ?? 'kg').toString(),
    );
  }
}

/// Talaba retsepti modeli
class XonadoshRecipe {
  const XonadoshRecipe({
    required this.id,
    required this.nameUz,
    required this.category,
    required this.prepTimeMin,
    required this.costLevel, // budget, medium, premium
    required this.ingredients,
    required this.instructionsUz,
    this.caloriesKcal = 500,
    this.imageUrl,
  });

  final int id;
  final String nameUz;
  final String category;
  final int prepTimeMin;
  final String costLevel;
  final List<XonadoshRecipeIngredient> ingredients;
  final String instructionsUz;
  final int caloriesKcal;
  final String? imageUrl;

  factory XonadoshRecipe.fromJson(Map<String, dynamic> json) {
    final ingsRaw = json['ingredients'];
    final ings = <XonadoshRecipeIngredient>[];
    if (ingsRaw is List) {
      for (final i in ingsRaw) {
        final map = _asStringKeyMap(i);
        if (map != null) {
          ings.add(XonadoshRecipeIngredient.fromJson(map));
        }
      }
    }

    return XonadoshRecipe(
      id: _numToInt(json['id']),
      nameUz: (json['name_uz'] ?? '').toString(),
      category: (json['category'] ?? 'Milliy').toString(),
      prepTimeMin: _numToInt(json['prep_time_min'], 30),
      costLevel: (json['cost_level'] ?? 'budget').toString(),
      ingredients: ings,
      instructionsUz: (json['instructions_uz'] ?? '').toString(),
      caloriesKcal: _numToInt(json['calories_kcal'], 500),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

/// Haftalik taomlar menyusi elementi (3 mahal/kun)
class XonadoshMealPlan {
  const XonadoshMealPlan({
    required this.id,
    required this.dayOfWeek,
    required this.mealTime,
    this.mealTimeLabel,
    this.recipeId,
    required this.recipeName,
    required this.cookName,
    this.notes = '',
    this.recipeImage,
    this.prepTimeMin = 30,
    this.costLevel = 'budget',
    this.caloriesKcal = 400,
    this.prepSchedule = '',
    this.eatingSchedule = '',
    this.cleanupSchedule = '',
    this.breadCount = 0.5,
    this.teaType = "Ko'k choy (95-nav)",
  });

  final int id;
  final String dayOfWeek;
  final String mealTime; // breakfast | lunch | dinner
  final String? mealTimeLabel; // 🌅 Nonushta | 🌤 Tushlik | 🌙 Kechki ovqat
  final int? recipeId;
  final String recipeName;
  final String cookName;
  final String notes;
  final String? recipeImage;
  final int prepTimeMin;
  final String costLevel;
  final int caloriesKcal;

  // New schedule fields
  final String prepSchedule;    // e.g. '07:30 – 07:45'
  final String eatingSchedule;  // e.g. '07:45 – 08:15'
  final String cleanupSchedule; // e.g. '08:15 – 08:25'
  final double breadCount;      // per person, e.g. 0.5
  final String teaType;         // e.g. "Ko'k choy (95-nav)"

  String get mealEmoji => switch (mealTime) {
    'breakfast' => '🌅',
    'lunch'     => '🌤',
    'dinner'    => '🌙',
    _           => '🍽',
  };

  String get mealLabel => switch (mealTime) {
    'breakfast' => 'Nonushta',
    'lunch'     => 'Tushlik',
    'dinner'    => 'Kechki ovqat',
    _           => mealTime,
  };

  String get fullMealLabel => '$mealEmoji $mealLabel';

  factory XonadoshMealPlan.fromJson(Map<String, dynamic> json) {
    return XonadoshMealPlan(
      id: _numToInt(json['id']),
      dayOfWeek: (json['day_of_week'] ?? 'dushanba').toString(),
      mealTime: (json['meal_time'] ?? 'dinner').toString(),
      mealTimeLabel: json['meal_time_label']?.toString(),
      recipeId: json['recipe_id'] != null ? _numToInt(json['recipe_id']) : null,
      recipeName: (json['recipe_name'] ?? 'Kechki ovqat').toString(),
      cookName: (json['cook_name'] ?? 'Xonadosh').toString(),
      notes: (json['notes'] ?? '').toString(),
      recipeImage: json['recipe_image']?.toString(),
      prepTimeMin: _numToInt(json['prep_time_min'], 30),
      costLevel: (json['cost_level'] ?? 'budget').toString(),
      caloriesKcal: _numToInt(json['calories_kcal'], 400),
      prepSchedule: (json['prep_schedule'] ?? '').toString(),
      eatingSchedule: (json['eating_schedule'] ?? '').toString(),
      cleanupSchedule: (json['cleanup_schedule'] ?? '').toString(),
      breadCount: _numToDouble(json['bread_count'], 0.5),
      teaType: (json['tea_type'] ?? "Ko'k choy (95-nav)").toString(),
    );
  }
}

/// Bozorlik mahsuloti modeli (Real narxlar + Eng arzon manba)
class XonadoshGroceryItem {
  XonadoshGroceryItem({
    required this.key,
    required this.nameUz,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.unitPriceUzs,
    required this.minPriceUzs,
    required this.maxPriceUzs,
    required this.totalPriceUzs,
    this.cheapestSource = 'Chorsu bozor',
    this.buyingTips = '',
    this.usedForMeals = const [],
    this.isBought = false,
  });

  final String key;
  final String nameUz;
  final String category;
  final String unit;
  final double quantity;
  final double unitPriceUzs;    // o'rtacha narx
  final double minPriceUzs;     // eng past narx
  final double maxPriceUzs;     // eng yuqori narx
  final double totalPriceUzs;
  final String cheapestSource;  // e.g. 'Chorsu parrandachilik paviloni'
  final String buyingTips;      // e.g. '10 kg qutida 40 000 so'm/kg'
  final List<String> usedForMeals; // ['🌅 Nonushta', '🌙 Kechki']
  bool isBought;

  factory XonadoshGroceryItem.fromJson(Map<String, dynamic> json) {
    final mealsRaw = json['used_for_meals'];
    final mealsList = <String>[];
    if (mealsRaw is List) {
      for (final m in mealsRaw) { if (m != null) mealsList.add(m.toString()); }
    }
    return XonadoshGroceryItem(
      key: (json['item_key'] ?? json['key'] ?? '').toString(),
      nameUz: (json['name_uz'] ?? '').toString(),
      category: (json['category'] ?? 'Asosiy').toString(),
      unit: (json['unit'] ?? 'kg').toString(),
      quantity: _numToDouble(json['qty_needed'] ?? json['quantity'], 1.0),
      unitPriceUzs: _numToDouble(json['avg_price_uzs'] ?? json['unit_price_uzs'], 10000.0),
      minPriceUzs: _numToDouble(json['min_price_uzs'], 0.0),
      maxPriceUzs: _numToDouble(json['max_price_uzs'], 0.0),
      totalPriceUzs: _numToDouble(json['total_cost_uzs'] ?? json['total_price_uzs'], 10000.0),
      cheapestSource: (json['cheapest_source'] ?? json['bazaar'] ?? 'Chorsu bozor').toString(),
      buyingTips: (json['buying_tips'] ?? '').toString(),
      usedForMeals: mealsList,
      isBought: json['is_bought'] == true,
    );
  }
}

/// 1 haftalik bozorlik hisobi (3 mahal/kun hisob)
class XonadoshGroceryCalculation {
  const XonadoshGroceryCalculation({
    required this.roommateCount,
    required this.days,
    required this.mealsPerDay,
    required this.totalMealSlots,
    required this.totalCostUzs,
    required this.perPersonUzs,
    required this.perPersonDailyUzs,
    required this.perPersonDailyUsd,
    required this.cheapestMarket,
    required this.shoppingDay,
    required this.items,
    required this.byCategorySummary,
    required this.breadBreakdown,
  });

  final int roommateCount;
  final int days;
  final int mealsPerDay;
  final int totalMealSlots;
  final int totalCostUzs;
  final int perPersonUzs;
  final int perPersonDailyUzs;
  final double perPersonDailyUsd;
  final String cheapestMarket;
  final String shoppingDay;
  final List<XonadoshGroceryItem> items;
  final List<Map<String, dynamic>> byCategorySummary;
  final Map<String, dynamic> breadBreakdown;

  // Compatibility getters for old code
  int get recipesIncludedCount => totalMealSlots;
  double get totalEstimatedUzs => totalCostUzs.toDouble();
  double get splitPerRoommateUzs => perPersonUzs.toDouble();

  factory XonadoshGroceryCalculation.fromJson(Map<String, dynamic> json) {
    final groceryRaw = json['grocery_list'] ?? json['items'] ?? [];
    final itemsList = <XonadoshGroceryItem>[];
    if (groceryRaw is List) {
      for (final it in groceryRaw) {
        final map = _asStringKeyMap(it);
        if (map != null) {
          itemsList.add(XonadoshGroceryItem.fromJson(map));
        }
      }
    }

    final sumMap = _asStringKeyMap(json['summary']) ?? {};
    final catRaw = sumMap['by_category'] ?? [];
    final catList = <Map<String, dynamic>>[];
    if (catRaw is List) {
      for (final c in catRaw) {
        final map = _asStringKeyMap(c);
        if (map != null) catList.add(map);
      }
    }
    final breadRaw = _asStringKeyMap(json['bread_breakdown']) ?? {};

    return XonadoshGroceryCalculation(
      roommateCount: _numToInt(json['roommates'] ?? json['roommate_count'], 4),
      days: _numToInt(json['days'], 7),
      mealsPerDay: _numToInt(json['meals_per_day'], 3),
      totalMealSlots: _numToInt(json['total_meal_slots'], 21),
      totalCostUzs: _numToInt(sumMap['total_cost_uzs'], 0),
      perPersonUzs: _numToInt(sumMap['per_person_uzs'], 0),
      perPersonDailyUzs: _numToInt(sumMap['per_person_daily_uzs'], 0),
      perPersonDailyUsd: _numToDouble(sumMap['per_person_daily_usd'], 0.0),
      cheapestMarket: (sumMap['cheapest_market'] ?? "Qo'yliq ulgurji bozor").toString(),
      shoppingDay: (sumMap['shopping_day'] ?? 'Shanba').toString(),
      items: itemsList,
      byCategorySummary: catList,
      breadBreakdown: Map<String, dynamic>.from(breadRaw),
    );
  }
}

/// ==========================================
/// 12. OBRO' & KARMA BAHOLASH MODELLARI
/// ==========================================
class XonadoshKarmaBadge {
  const XonadoshKarmaBadge({
    required this.key,
    required this.name,
    required this.icon,
    required this.description,
  });

  final String key;
  final String name;
  final String icon;
  final String description;

  factory XonadoshKarmaBadge.fromJson(Map<String, dynamic> json) {
    return XonadoshKarmaBadge(
      key: (json['key'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? '⭐').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class XonadoshKarmaPraise {
  const XonadoshKarmaPraise({
    required this.fromName,
    required this.badgeName,
    required this.comment,
    required this.createdAt,
  });

  final String fromName;
  final String badgeName;
  final String comment;
  final String createdAt;

  factory XonadoshKarmaPraise.fromJson(Map<String, dynamic> json) {
    return XonadoshKarmaPraise(
      fromName: (json['from_name'] ?? '').toString(),
      badgeName: (json['badge_name'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class XonadoshKarmaMember {
  const XonadoshKarmaMember({
    required this.name,
    required this.totalPoints,
    required this.badgesCount,
    required this.badgesSummary,
    required this.recentPraises,
  });

  final String name;
  final int totalPoints;
  final int badgesCount;
  final List<Map<String, dynamic>> badgesSummary;
  final List<XonadoshKarmaPraise> recentPraises;

  factory XonadoshKarmaMember.fromJson(Map<String, dynamic> json) {
    final bRaw = json['badges_summary'];
    final bList = <Map<String, dynamic>>[];
    if (bRaw is List) {
      for (final b in bRaw) {
        final map = _asStringKeyMap(b);
        if (map != null) bList.add(map);
      }
    }

    final pRaw = json['recent_praises'];
    final pList = <XonadoshKarmaPraise>[];
    if (pRaw is List) {
      for (final p in pRaw) {
        final map = _asStringKeyMap(p);
        if (map != null) {
          pList.add(XonadoshKarmaPraise.fromJson(map));
        }
      }
    }

    return XonadoshKarmaMember(
      name: (json['name'] ?? '').toString(),
      totalPoints: _numToInt(json['total_points'], 0),
      badgesCount: _numToInt(json['badges_count'], 0),
      badgesSummary: bList,
      recentPraises: pList,
    );
  }
}

class XonadoshKarmaData {
  const XonadoshKarmaData({
    required this.groupCode,
    required this.availableBadges,
    required this.roommates,
    required this.leaderboard,
  });

  final String groupCode;
  final List<XonadoshKarmaBadge> availableBadges;
  final List<String> roommates;
  final List<XonadoshKarmaMember> leaderboard;

  factory XonadoshKarmaData.fromJson(Map<String, dynamic> json) {
    final badgesRaw = json['available_badges'] as List? ?? [];
    final badgesList = badgesRaw
        .map((e) => XonadoshKarmaBadge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rmRaw = json['roommates'] as List? ?? [];
    final rmList = rmRaw.map((e) => e.toString()).toList();

    final leadRaw = json['leaderboard'] as List? ?? [];
    final leadList = leadRaw
        .map((e) => XonadoshKarmaMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return XonadoshKarmaData(
      groupCode: (json['group_code'] ?? 'home_default').toString(),
      availableBadges: badgesList,
      roommates: rmList,
      leaderboard: leadList,
    );
  }
}

/// ==========================================
/// 13. ANONIM MASALALAR & OVOZ BERISH MODELLARI
/// ==========================================
class XonadoshPoll {
  const XonadoshPoll({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.votesYes,
    required this.votesNo,
    required this.votesNeutral,
    required this.totalVotes,
    required this.yesPercent,
    required this.noPercent,
    required this.neutralPercent,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String status; // 'active', 'passed', 'rejected', 'closed'
  final int votesYes;
  final int votesNo;
  final int votesNeutral;
  final int totalVotes;
  final int yesPercent;
  final int noPercent;
  final int neutralPercent;
  final String createdAt;

  bool get isActive => status == 'active';
  bool get isPassed => status == 'passed';
  bool get isRejected => status == 'rejected';

  factory XonadoshPoll.fromJson(Map<String, dynamic> json) {
    return XonadoshPoll(
      id: _numToInt(json['id'], 0),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'rules').toString(),
      status: (json['status'] ?? 'active').toString(),
      votesYes: _numToInt(json['votes_yes'], 0),
      votesNo: _numToInt(json['votes_no'], 0),
      votesNeutral: _numToInt(json['votes_neutral'], 0),
      totalVotes: _numToInt(json['total_votes'], 0),
      yesPercent: _numToInt(json['yes_percent'], 0),
      noPercent: _numToInt(json['no_percent'], 0),
      neutralPercent: _numToInt(json['neutral_percent'], 0),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class XonadoshPollsData {
  const XonadoshPollsData({
    required this.groupCode,
    required this.activeCount,
    required this.polls,
  });

  final String groupCode;
  final int activeCount;
  final List<XonadoshPoll> polls;

  factory XonadoshPollsData.fromJson(Map<String, dynamic> json) {
    final pollsRaw = json['polls'] as List? ?? [];
    final pList = pollsRaw
        .map((e) => XonadoshPoll.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return XonadoshPollsData(
      groupCode: (json['group_code'] ?? 'home_default').toString(),
      activeCount: _numToInt(json['active_count'], 0),
      polls: pList,
    );
  }
}

/// ==========================================
/// 14. MOLIYA, IJARA, KOMMUNAL & QARZ MODELLARI
/// ==========================================
class XonadoshFinanceSplit {
  XonadoshFinanceSplit({
    required this.name,
    required this.amountUzs,
    required this.isPaid,
  });

  final String name;
  final int amountUzs;
  bool isPaid;

  factory XonadoshFinanceSplit.fromJson(Map<String, dynamic> json) {
    return XonadoshFinanceSplit(
      name: (json['name'] ?? '').toString(),
      amountUzs: _numToInt(json['amount_uzs'], 0),
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
    );
  }
}

class XonadoshFinanceItem {
  const XonadoshFinanceItem({
    required this.id,
    required this.type,
    required this.title,
    required this.amountUzs,
    required this.paidBy,
    required this.category,
    required this.dueDate,
    required this.status,
    required this.paidAmountUzs,
    required this.pendingAmountUzs,
    required this.splits,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final String type; // 'rent', 'utility', 'expense_split', 'debt'
  final String title;
  final int amountUzs;
  final String paidBy;
  final String category;
  final String dueDate;
  final String status; // 'pending', 'partially_paid', 'settled'
  final int paidAmountUzs;
  final int pendingAmountUzs;
  final List<XonadoshFinanceSplit> splits;
  final String notes;
  final String createdAt;

  bool get isSettled => status == 'settled';

  factory XonadoshFinanceItem.fromJson(Map<String, dynamic> json) {
    final sRaw = json['splits'] as List? ?? [];
    final sList = sRaw
        .map((e) => XonadoshFinanceSplit.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return XonadoshFinanceItem(
      id: _numToInt(json['id'], 0),
      type: (json['type'] ?? 'expense_split').toString(),
      title: (json['title'] ?? '').toString(),
      amountUzs: _numToInt(json['amount_uzs'], 0),
      paidBy: (json['paid_by'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      dueDate: (json['due_date'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      paidAmountUzs: _numToInt(json['paid_amount_uzs'], 0),
      pendingAmountUzs: _numToInt(json['pending_amount_uzs'], 0),
      splits: sList,
      notes: (json['notes'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class XonadoshDebtBalance {
  const XonadoshDebtBalance({
    required this.debtor,
    required this.creditor,
    required this.amountUzs,
    required this.reason,
  });

  final String debtor;
  final String creditor;
  final int amountUzs;
  final String reason;

  factory XonadoshDebtBalance.fromJson(Map<String, dynamic> json) {
    return XonadoshDebtBalance(
      debtor: (json['debtor'] ?? '').toString(),
      creditor: (json['creditor'] ?? '').toString(),
      amountUzs: _numToInt(json['amount_uzs'], 0),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class XonadoshFinancesData {
  const XonadoshFinancesData({
    required this.groupCode,
    required this.totalSpendUzs,
    required this.totalPendingUzs,
    required this.rentTotalUzs,
    required this.utilityTotalUzs,
    required this.expenseTotalUzs,
    required this.debtBalances,
    required this.rentItems,
    required this.utilityItems,
    required this.expenseItems,
  });

  final String groupCode;
  final int totalSpendUzs;
  final int totalPendingUzs;
  final int rentTotalUzs;
  final int utilityTotalUzs;
  final int expenseTotalUzs;
  final List<XonadoshDebtBalance> debtBalances;
  final List<XonadoshFinanceItem> rentItems;
  final List<XonadoshFinanceItem> utilityItems;
  final List<XonadoshFinanceItem> expenseItems;

  factory XonadoshFinancesData.fromJson(Map<String, dynamic> json) {
    final sumMap = _asStringKeyMap(json['summary']) ?? {};

    final dRaw = json['debt_balances'] as List? ?? [];
    final dList = dRaw
        .map((e) => XonadoshDebtBalance.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rRaw = json['rent_items'] as List? ?? [];
    final rList = rRaw
        .map((e) => XonadoshFinanceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final uRaw = json['utility_items'] as List? ?? [];
    final uList = uRaw
        .map((e) => XonadoshFinanceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final eRaw = json['expense_items'] as List? ?? [];
    final eList = eRaw
        .map((e) => XonadoshFinanceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return XonadoshFinancesData(
      groupCode: (json['group_code'] ?? 'home_default').toString(),
      totalSpendUzs: _numToInt(sumMap['total_spend_uzs'], 0),
      totalPendingUzs: _numToInt(sumMap['total_pending_uzs'], 0),
      rentTotalUzs: _numToInt(sumMap['rent_total_uzs'], 0),
      utilityTotalUzs: _numToInt(sumMap['utility_total_uzs'], 0),
      expenseTotalUzs: _numToInt(sumMap['expense_total_uzs'], 0),
      debtBalances: dList,
      rentItems: rList,
      utilityItems: uList,
      expenseItems: eList,
    );
  }
}

