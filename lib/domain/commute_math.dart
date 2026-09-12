import 'dart:math' as math;

/// Pure Haversine + road factor (mirrors PHP `xonadosh_commute_calc.php`).
class CommuteMath {
  CommuteMath._();

  static const double earthRadiusKm = 6371.0;
  static const double roadFactor = 1.25;

  /// Great-circle distance in km, rounded to 2 decimals (same as PHP).
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _round2(earthRadiusKm * c);
  }

  /// Crow-flight distance floored at 0.2 km, then × 1.25 road factor.
  static double roadDistanceKm(double straightKm) {
    final dist = math.max(0.2, straightKm);
    return _round2(dist * roadFactor);
  }

  static double roadDistanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return roadDistanceKm(haversineKm(lat1, lon1, lat2, lon2));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  static double _round2(double v) => (v * 100).round() / 100.0;
}
