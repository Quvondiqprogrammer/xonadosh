import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';

void main() {
  test('recipe ingredients parse from untyped nested maps', () {
    final recipe = XonadoshRecipe.fromJson({
      'id': 7,
      'name_uz': 'Osh',
      'ingredients': [
        {'key': 'rice', 'name_uz': 'Guruch', 'amount_per_person': 0.2, 'unit': 'kg'},
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
}
