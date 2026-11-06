import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_response.dart';

/// XonaDosh feature API (HTTPS `honadosh.uz`).
class XonadoshApiClient {
  XonadoshApiClient(this._api);

  final ApiClient _api;

  Dio get _dio => _api.dio;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? q,
  ]) async {
    try {
      final res = await _dio.get<dynamic>(
        path,
        queryParameters: q == null ? null : ApiResponse.compactQuery(q),
      );
      return ApiResponse.parse(res.data, status: res.statusCode);
    } on DioException catch (e) {
      return _mapError(e);
    } catch (e) {
      return {'ok': false, 'error': 'Dastur xatosi: $e'};
    }
  }

  Future<Map<String, dynamic>> _post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post<dynamic>(path, data: data);
      return ApiResponse.parse(res.data, status: res.statusCode);
    } on DioException catch (e) {
      return _mapError(e);
    } catch (e) {
      return {'ok': false, 'error': 'Dastur xatosi: $e'};
    }
  }

  Map<String, dynamic> _mapError(DioException e) {
    return ApiResponse.parse(
      e.response?.data,
      status: e.response?.statusCode,
      fallbackError: e.message ?? 'Tarmoq xatosi',
    );
  }

  Future<Map<String, dynamic>> getUniversities({String? city, String? query}) =>
      _get('api/xonadosh_universities_get.php', {
        if (city != null && city.isNotEmpty) 'city': city,
        if (query != null && query.isNotEmpty) 'q': query,
      });

  Future<Map<String, dynamic>> getListings({
    int? universityId,
    String? type,
    String? gender,
    String? city,
    String? district,
    int? rooms,
    double? minPrice,
    double? maxPrice,
    String? query,
    int? listingId,
    bool? noBroker,
    bool? utilitiesIncluded,
    bool? subsidyOnly,
    bool? womenOnly,
    double? maxDistanceKm,
    int? maxCommuteMin,
    int limit = 30,
    int offset = 0,
  }) => _get('api/xonadosh_listings_get.php', {
    'university_id': ?universityId,
    if (type != null && type.isNotEmpty) 'type': type,
    if (gender != null && gender.isNotEmpty) 'gender': gender,
    if (city != null && city.isNotEmpty) 'city': city,
    if (district != null && district.isNotEmpty) 'district': district,
    'rooms': ?rooms,
    'min_price': ?minPrice,
    'max_price': ?maxPrice,
    if (query != null && query.isNotEmpty) 'q': query,
    if (noBroker == true) 'no_broker': 1,
    if (utilitiesIncluded == true) 'utilities_included': 1,
    if (subsidyOnly == true) 'subsidy_only': 1,
    if (womenOnly == true) 'women_only': 1,
    'max_distance_km': ?maxDistanceKm,
    'max_commute_min': ?maxCommuteMin,
    'id': ?listingId,
    'limit': limit,
    'offset': offset,
  });

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) =>
      _post('api/xonadosh_listing_create.php', data: data);

  /// Multipart photo upload (web + mobile). Returns `{ok, url}`.
  Future<Map<String, dynamic>> uploadPhoto({
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
  }) async {
    try {
      final form = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post<dynamic>(
        'api/xonadosh_upload.php',
        data: form,
        options: Options(
          // Let Dio attach multipart boundary (do not keep JSON Content-Type).
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return ApiResponse.parse(res.data, status: res.statusCode);
    } on DioException catch (e) {
      return _mapError(e);
    } catch (e) {
      return {'ok': false, 'error': 'Dastur xatosi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteListing(int listingId) =>
      _post('api/xonadosh_listing_delete.php', data: {'listing_id': listingId});

  Future<Map<String, dynamic>> calculateCommute({
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    int? universityId,
    int? listingId,
  }) => _get('api/xonadosh_commute_calc.php', {
    'from_lat': ?fromLat,
    'from_lng': ?fromLng,
    'to_lat': ?toLat,
    'to_lng': ?toLng,
    'university_id': ?universityId,
    'listing_id': ?listingId,
  });

  Future<Map<String, dynamic>> getProfiles({
    String? username,
    int? universityId,
    String? gender,
    String? query,
  }) => _get('api/xonadosh_profiles.php', {
    if (username != null && username.isNotEmpty) 'username': username,
    'university_id': ?universityId,
    if (gender != null && gender.isNotEmpty) 'gender': gender,
    if (query != null && query.isNotEmpty) 'q': query,
  });

  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> data) =>
      _post('api/xonadosh_profiles.php', data: data);

  Future<Map<String, dynamic>> getMatchingRoommates({
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
  }) => _get('api/xonadosh_match.php', {
    if (username != null && username.isNotEmpty) 'username': username,
    'university_id': ?universityId,
    if (gender != null && gender.isNotEmpty) 'gender': gender,
    if (sleepSchedule != null && sleepSchedule.isNotEmpty)
      'sleep_schedule': sleepSchedule,
    if (cleanliness != null && cleanliness.isNotEmpty)
      'cleanliness': cleanliness,
    if (studyHabit != null && studyHabit.isNotEmpty) 'study_habit': studyHabit,
    if (cookingHabit != null && cookingHabit.isNotEmpty)
      'cooking_habit': cookingHabit,
    if (smokingHabit != null && smokingHabit.isNotEmpty)
      'smoking_habit': smokingHabit,
    'budget_min': ?budgetMin,
    'budget_max': ?budgetMax,
    if (lang != null && lang.isNotEmpty) 'lang': lang,
  });

  Future<Map<String, dynamic>> getChores({String groupCode = 'home_default'}) =>
      _get('api/xonadosh_chores.php', {'group_code': groupCode});

  Future<Map<String, dynamic>> toggleChoreDone({
    required int choreId,
    required bool isCompleted,
    String groupCode = 'home_default',
  }) => _post(
    'api/xonadosh_chores.php',
    data: {
      'action': 'toggle_done',
      'chore_id': choreId,
      'is_completed': isCompleted ? 1 : 0,
      'group_code': groupCode,
    },
  );

  Future<Map<String, dynamic>> addChore(Map<String, dynamic> data) =>
      _post('api/xonadosh_chores.php', data: {...data, 'action': 'add'});

  Future<Map<String, dynamic>> assignChore({
    required int choreId,
    required String assignedName,
    String groupCode = 'home_default',
  }) => _post(
    'api/xonadosh_chores.php',
    data: {
      'action': 'assign',
      'chore_id': choreId,
      'assigned_name': assignedName,
      'group_code': groupCode,
    },
  );

  Future<Map<String, dynamic>> getRecipesAndMealPlan({
    String groupCode = 'home_default',
  }) => _get('api/xonadosh_recipes.php', {'group_code': groupCode});

  Future<Map<String, dynamic>> setMealPlan(Map<String, dynamic> data) =>
      _post('api/xonadosh_recipes.php', data: {...data, 'action': 'set_plan'});

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> data) => _post(
    'api/xonadosh_recipes.php',
    data: {...data, 'action': 'create_recipe'},
  );

  Future<Map<String, dynamic>> calculateGrocery({
    int roommateCount = 4,
    List<int>? recipeIds,
    String groupCode = 'home_default',
  }) => _get('api/xonadosh_grocery_calc.php', {
    'roommates': roommateCount,
    'roommate_count': roommateCount,
    if (recipeIds != null && recipeIds.isNotEmpty)
      'recipe_ids': recipeIds.join(','),
    'group_code': groupCode,
  });

  /// 12. Obro' va Karma baholash tizimi
  Future<Map<String, dynamic>> getKarma({String groupCode = 'home_default'}) =>
      _get('api/xonadosh_karma.php', {'group_code': groupCode});

  Future<Map<String, dynamic>> giveKarma(Map<String, dynamic> data) =>
      _post('api/xonadosh_karma.php', data: {...data, 'action': 'give_karma'});

  /// 13. Anonim masalalar va ovoz berish
  Future<Map<String, dynamic>> getPolls({String groupCode = 'home_default'}) =>
      _get('api/xonadosh_polls.php', {'group_code': groupCode});

  Future<Map<String, dynamic>> createPoll(Map<String, dynamic> data) =>
      _post('api/xonadosh_polls.php', data: {...data, 'action': 'create_poll'});

  Future<Map<String, dynamic>> votePoll({
    required int pollId,
    required String vote,
    String? voterHash,
    String groupCode = 'home_default',
  }) => _post(
    'api/xonadosh_polls.php',
    data: {
      'action': 'vote',
      'poll_id': pollId,
      'vote': vote,
      ...?voterHash != null ? {'voter_hash': voterHash} : null,
      'group_code': groupCode,
    },
  );

  Future<Map<String, dynamic>> closePoll({
    required int pollId,
    String status = 'closed',
    String groupCode = 'home_default',
  }) => _post(
    'api/xonadosh_polls.php',
    data: {
      'action': 'close_poll',
      'poll_id': pollId,
      'status': status,
      'group_code': groupCode,
    },
  );

  /// 14. Moliya, Ijara, Kommunal va Qarz hisob-kitoblari
  Future<Map<String, dynamic>> getFinances({
    String groupCode = 'home_default',
  }) => _get('api/xonadosh_finances.php', {'group_code': groupCode});

  Future<Map<String, dynamic>> addFinance(Map<String, dynamic> data) => _post(
    'api/xonadosh_finances.php',
    data: {...data, 'action': 'add_expense'},
  );

  Future<Map<String, dynamic>> toggleFinancePaid({
    required int financeId,
    required String memberName,
    required bool isPaid,
    String groupCode = 'home_default',
  }) => _post(
    'api/xonadosh_finances.php',
    data: {
      'action': 'toggle_member_paid',
      'finance_id': financeId,
      'member_name': memberName,
      'is_paid': isPaid ? 1 : 0,
      'group_code': groupCode,
    },
  );

  Future<Map<String, dynamic>> deleteFinance({
    required int financeId,
    String groupCode = 'home_default',
  }) => _post(
    'api/xonadosh_finances.php',
    data: {
      'action': 'delete_finance',
      'finance_id': financeId,
      'group_code': groupCode,
    },
  );

  /// UGC moderation report (requires auth).
  Future<Map<String, dynamic>> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  }) => _post(
    'api/report.php',
    data: {'target_type': targetType, 'target_id': targetId, 'reason': reason},
  );

  /// 15. Kraud-moderatsiya: Yashirin makler haqida 1-tap xabar berish
  Future<Map<String, dynamic>> reportBroker({
    required int listingId,
    String? reason,
  }) => _post(
    'api/xonadosh_report_broker.php',
    data: {
      'listing_id': listingId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    },
  );

  /// 16. E'lonni 1 bosishda yana 72 soatga uzaytirish (fresh TTL)
  Future<Map<String, dynamic>> renewListing({required int listingId}) =>
      _post('api/xonadosh_listing_renew.php', data: {'listing_id': listingId});

  /// 17. Raqamli Xonadoshlik Kodeksi (House Rules)
  Future<Map<String, dynamic>> getHouseRulesAgreement({
    String groupCode = 'home_default',
  }) => _get('api/xonadosh_house_rules.php', {'group_code': groupCode});

  Future<Map<String, dynamic>> saveHouseRulesAgreement({
    required String groupCode,
    required String quietHoursStart,
    required int rentDueDay,
    required String guestPolicy,
    required String commonGroceries,
    required int moveOutNoticeDays,
    bool confirm = false,
  }) => _post(
    'api/xonadosh_house_rules.php',
    data: {
      'group_code': groupCode,
      'quiet_hours_start': quietHoursStart,
      'rent_due_day': rentDueDay,
      'guest_policy': guestPolicy,
      'common_groceries': commonGroceries,
      'move_out_notice_days': moveOutNoticeDays,
      'confirm': confirm ? 1 : 0,
    },
  );

  /// 18. Xonadosh Jamoasi (Coliving Squads)
  Future<Map<String, dynamic>> getSquads({
    int? universityId,
    String? gender,
    String? district,
    String status = 'recruiting',
  }) => _get('api/xonadosh_squads.php', {
    'target_university_id': ?universityId,
    if (gender != null && gender.isNotEmpty) 'gender': gender,
    if (district != null && district.isNotEmpty) 'district': district,
    'status': status,
  });

  Future<Map<String, dynamic>> createSquad({
    required String name,
    int? targetUniversityId,
    String? targetUniversityName,
    String? targetDistrict,
    required double myBudgetUzs,
    String targetGender = 'any',
    int lookingForCount = 3,
    String? description,
    String? phone,
  }) => _post(
    'api/xonadosh_squads.php',
    data: {
      'action': 'create',
      'name': name,
      'target_university_id': ?targetUniversityId,
      'target_university_name': ?targetUniversityName,
      'target_district': ?targetDistrict,
      'my_budget_uzs': myBudgetUzs,
      'target_gender': targetGender,
      'looking_for_count': lookingForCount,
      'description': ?description,
      'phone': ?phone,
    },
  );

  Future<Map<String, dynamic>> joinSquad({
    required int squadId,
    required double memberBudgetUzs,
  }) => _post(
    'api/xonadosh_squads.php',
    data: {
      'action': 'join',
      'squad_id': squadId,
      'member_budget_uzs': memberBudgetUzs,
    },
  );
}
