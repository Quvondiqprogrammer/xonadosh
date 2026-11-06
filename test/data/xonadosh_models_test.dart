import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';

void main() {
  test('recipe ingredients parse from untyped nested maps', () {
    final recipe = XonadoshRecipe.fromJson({
      'id': 7,
      'name_uz': 'Osh',
      'ingredients': [
        {
          'key': 'rice',
          'name_uz': 'Guruch',
          'amount_per_person': 0.2,
          'unit': 'kg',
        },
        {'name': 'Yog‘', 'qty_per_person': '0.05'},
      ],
    });
    expect(recipe.ingredients, hasLength(2));
    expect(recipe.ingredients.first.nameUz, 'Guruch');
    expect(recipe.ingredients.first.qtyPerPerson, 0.2);
  });

  test('grocery items parse from untyped nested maps', () {
    final calc = XonadoshGroceryCalculation.fromJson({
      'ok': true,
      'roommates': 4,
      'grocery_list': [
        {
          'item_key': 'eggs',
          'name_uz': 'Tuxum',
          'qty_needed': 12,
          'avg_price_uzs': 1600,
          'total_cost_uzs': 19200,
        },
      ],
      'summary': {
        'total_cost_uzs': 19200,
        'per_person_uzs': 4800,
        'by_category': [
          {'category': 'Sut', 'total_uzs': 19200},
        ],
      },
    });
    expect(calc.items, hasLength(1));
    expect(calc.items.first.nameUz, 'Tuxum');
    expect(calc.totalCostUzs, 19200);
    expect(calc.byCategorySummary, hasLength(1));
  });

  test('listing commute parses from untyped nested maps', () {
    final listing = XonadoshListing.fromJson({
      'id': 1,
      'username': 'ali',
      'title': 'Uy',
      'commute': {
        'distance_km': 2.5,
        'modes': {
          'metro': {'name': 'Metro', 'time_min': 18},
          'bus': {'name': 'Avtobus'},
          'taxi': {'name': 'Taksi'},
          'walk': {'name': 'Piyoda'},
        },
      },
    });
    expect(listing.commute, isNotNull);
    expect(listing.commute!.distanceKm, 2.5);
    expect(listing.commute!.metro.timeMin, 18);
  });

  test('listing parses is_no_broker and utilities_included flags', () {
    final listing = XonadoshListing.fromJson({
      'id': 2,
      'username': 'owner_tashkent',
      'title': 'Chilonzor 3 xona',
      'is_no_broker': true,
      'utilities_included': 1,
      'amenities': ['wi-fi', 'bez_makler', 'konditsioner'],
    });
    expect(listing.isNoBroker, isTrue);
    expect(listing.utilitiesIncluded, isTrue);

    final modified = listing.copyWith(isNoBroker: false);
    expect(modified.isNoBroker, isFalse);
    expect(modified.utilitiesIncluded, isTrue);
  });

  test('house rule serializes and toggles correctly', () {
    final rule = XonadoshHouseRule(
      id: 'rule_1',
      title: 'Tinchlik soatlari',
      description: 'Soat 23:00 dan keyin baland ovozda gapirmaslik',
      category: 'quiet_hours',
      icon: 'bedtime',
      isActive: true,
    );

    final json = rule.toJson();
    expect(json['id'], 'rule_1');
    expect(json['is_active'], isTrue);
    expect(json['category'], 'quiet_hours');

    final restored = XonadoshHouseRule.fromJson(json);
    expect(restored.id, 'rule_1');
    expect(restored.title, 'Tinchlik soatlari');
    expect(restored.isActive, isTrue);

    final toggled = restored.copyWith(isActive: false);
    expect(toggled.isActive, isFalse);
  });

  test('profile parses and preserves looking_for_text and avatar_url', () {
    final profile = XonadoshProfile.fromJson({
      'id': 1,
      'username': 'quvondiq_dev',
      'full_name': 'Quvondiq',
      'avatar_url': 'https://example.com/avatar.jpg',
      'looking_for_text': '2 kishilik xona qidiryapman, Chilonzor atrofida',
      'budget_min': 500000,
      'budget_max': 1200000,
      'sleep_schedule': 'early_bird',
      'cleanliness': 'strict',
      'study_habit': 'silent',
      'compatibility_score': 95,
    });

    expect(profile.username, 'quvondiq_dev');
    expect(profile.fullName, 'Quvondiq');
    expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
    expect(
      profile.lookingForText,
      '2 kishilik xona qidiryapman, Chilonzor atrofida',
    );
    expect(profile.budgetMin, 500000);
    expect(profile.budgetMax, 1200000);
    expect(profile.compatibilityScore, 95);

    final copy = profile.copyWith(lookingForText: 'Yangilangan qidiruv matni');
    expect(copy.lookingForText, 'Yangilangan qidiruv matni');
    expect(copy.avatarUrl, 'https://example.com/avatar.jpg');
  });

  test('chore duty parses and serializes correctly', () {
    final chore = XonadoshChore.fromJson({
      'id': 42,
      'group_code': 'tashkent_flat_1',
      'title': 'Oshxona polini yuvish',
      'chore_type': 'cleaning',
      'day_of_week': 'dushanba',
      'assigned_name': 'Jasur',
      'is_completed': 1,
      'notes': 'Maxsus tozalagich bilan',
    });

    expect(chore.id, 42);
    expect(chore.groupCode, 'tashkent_flat_1');
    expect(chore.title, 'Oshxona polini yuvish');
    expect(chore.choreType, 'cleaning');
    expect(chore.dayOfWeek, 'dushanba');
    expect(chore.assignedName, 'Jasur');
    expect(chore.isCompleted, isTrue);
    expect(chore.notes, 'Maxsus tozalagich bilan');
  });

  test('meal plan parses and formats schedule slots correctly', () {
    final meal = XonadoshMealPlan.fromJson({
      'id': 10,
      'day_of_week': 'payshanba',
      'meal_time': 'dinner',
      'meal_time_label': '🌙 Kechki ovqat',
      'recipe_id': 3,
      'recipe_name': 'Osh',
      'cook_name': 'Sardor',
      'prep_schedule': '19:00 - 19:30',
      'eating_schedule': '19:30 - 20:15',
      'cleanup_schedule': '20:15 - 20:30',
      'bread_count': 1.0,
      'tea_type': "Ko'k choy",
      'prep_time_min': 45,
      'cost_level': 'budget',
      'calories_kcal': 650,
    });

    expect(meal.id, 10);
    expect(meal.dayOfWeek, 'payshanba');
    expect(meal.mealTime, 'dinner');
    expect(meal.mealTimeLabel, '🌙 Kechki ovqat');
    expect(meal.recipeName, 'Osh');
    expect(meal.cookName, 'Sardor');
    expect(meal.prepTimeMin, 45);
    expect(meal.caloriesKcal, 650);
  });

  test('karma data parses leaderboard and available badges correctly', () {
    final karma = XonadoshKarmaData.fromJson({
      'ok': true,
      'group_code': 'home_default',
      'available_badges': [
        {
          'key': 'chef_pro',
          'name': 'Mohir oshpaz',
          'icon': '👨‍🍳',
          'description': 'Mazali taomlar uchun',
        },
      ],
      'roommates': ['Jasur', 'Azizbek'],
      'leaderboard': [
        {
          'name': 'Jasur',
          'total_points': 5,
          'badges_count': 2,
          'badges_summary': [
            {'key': 'chef_pro', 'name': 'Mohir oshpaz', 'count': 2},
          ],
          'recent_praises': [
            {
              'from_name': 'Azizbek',
              'badge_name': 'Mohir oshpaz',
              'comment': 'Ajoyib osh',
              'created_at': '2026-10-24 12:00:00',
            },
          ],
        },
      ],
      'history': [],
    });

    expect(karma.groupCode, 'home_default');
    expect(karma.availableBadges, hasLength(1));
    expect(karma.availableBadges.first.name, 'Mohir oshpaz');
    expect(karma.leaderboard, hasLength(1));
    expect(karma.leaderboard.first.name, 'Jasur');
    expect(karma.leaderboard.first.totalPoints, 5);
  });

  test('polls data parses active and passed proposals correctly', () {
    final polls = XonadoshPollsData.fromJson({
      'ok': true,
      'group_code': 'home_default',
      'polls': [
        {
          'id': 1,
          'title': 'Oshxonaga qo‘shimcha choynak olish',
          'description': 'Eski choynak singan, yangisini olish taklifi',
          'category': 'supplies',
          'status': 'passed',
          'votes_yes': 3,
          'votes_no': 0,
          'votes_neutral': 1,
          'user_vote': 'yes',
        },
      ],
    });

    expect(polls.groupCode, 'home_default');
    expect(polls.polls, hasLength(1));
    final p = polls.polls.first;
    expect(p.id, 1);
    expect(p.title, 'Oshxonaga qo‘shimcha choynak olish');
    expect(p.status, 'passed');
    expect(p.votesYes, 3);
    expect(p.totalVotes, 4);
    expect(p.yesPercent, 75);
  });

  test('finances data parses items, splits and debt balances correctly', () {
    final finances = XonadoshFinancesData.fromJson({
      'ok': true,
      'group_code': 'home_default',
      'summary': {
        'total_spend_uzs': 4000000,
        'total_pending_uzs': 1000000,
        'rent_total_uzs': 4000000,
        'utility_total_uzs': 0,
        'expense_total_uzs': 0,
      },
      'debt_balances': [
        {
          'debtor': 'Bekzod',
          'creditor': 'Jasur',
          'amount_uzs': 1000000,
          'reason': 'Ijara',
        },
      ],
      'rent_items': [
        {
          'id': 1,
          'type': 'rent',
          'title': 'Mart oyi ijarasi',
          'amount_uzs': 4000000,
          'paid_by': 'Jasur',
          'category': 'rent',
          'due_date': '5-mart',
          'status': 'partially_paid',
          'paid_amount_uzs': 3000000,
          'pending_amount_uzs': 1000000,
          'splits': [
            {'name': 'Jasur', 'amount_uzs': 1000000, 'is_paid': true},
            {'name': 'Bekzod', 'amount_uzs': 1000000, 'is_paid': false},
          ],
        },
      ],
      'utility_items': [],
      'expense_items': [],
    });

    expect(finances.groupCode, 'home_default');
    expect(finances.totalSpendUzs, 4000000);
    expect(finances.totalPendingUzs, 1000000);
    expect(finances.debtBalances, hasLength(1));
    expect(finances.debtBalances.first.debtor, 'Bekzod');
    expect(finances.debtBalances.first.amountUzs, 1000000);
    expect(finances.rentItems, hasLength(1));
    expect(finances.rentItems.first.splits, hasLength(2));
    expect(finances.rentItems.first.splits.first.isPaid, isTrue);
    expect(finances.rentItems.first.splits.last.isPaid, isFalse);
  });
}
