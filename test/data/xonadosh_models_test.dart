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
    expect(profile.lookingForText, '2 kishilik xona qidiryapman, Chilonzor atrofida');
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
}
