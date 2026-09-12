import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/domain/commute_math.dart';

void main() {
  test('haversine between nearby Tashkent points is small', () {
    // Approx 1 km east of center
    final km = CommuteMath.haversineKm(41.311081, 69.240562, 41.311081, 69.2525);
    expect(km, greaterThan(0.5));
    expect(km, lessThan(2.0));
  });

  test('road factor multiplies by 1.25 with 0.2 floor', () {
    expect(CommuteMath.roadDistanceKm(1.0), 1.25);
    expect(CommuteMath.roadDistanceKm(0.1), closeTo(0.25, 0.001));
  });

  test('identical coords still apply floor then road factor', () {
    final road = CommuteMath.roadDistanceBetween(
      41.311081,
      69.240562,
      41.311081,
      69.240562,
    );
    expect(road, 0.25); // max(0.2, 0) * 1.25
  });
}
