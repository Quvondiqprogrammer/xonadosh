import 'package:flutter/material.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/features/xonadosh/data/xonadosh_locations.dart';

String formatListingMoney(double amount) {
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
}

String formatListingDistanceKm(double km) {
  if (km < 0.1) return '<0.1 km';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.toStringAsFixed(0)} km';
}

/// Visual-First, 3-Second Intuitive Clean Listing Card (Airbnb style)
class XonadoshListingCard extends StatelessWidget {
  const XonadoshListingCard({
    super.key,
    required this.item,
    required this.bookmarked,
    required this.onTap,
    required this.onBookmark,
    required this.onReport,
    required this.onCall,
    this.onTelegram,
  });

  final XonadoshListing item;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onReport;
  final VoidCallback onCall;
  final VoidCallback? onTelegram;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photo = item.photos.isNotEmpty ? item.photos.first : null;
    final currSymbol =
        XonadoshLocationData.currencySymbols[item.currency] ?? item.currency;

    // Time estimate to nearest uni (approx 12 km/h bike/metro, 4 km/h walking)
    final uniDistance = item.distanceToUniversityKm;
    final uniName = item.nearestUniversityShort ?? 'OTM';
    final estMinutes = uniDistance != null
        ? (uniDistance <= 1.5
            ? (uniDistance * 12).round()
            : (uniDistance * 3.5).round())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: XonaDoshStyles.cardDecoration(isDark, radius: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Photo Container (190px rounded)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  photo != null
                      ? Image.network(
                          photo,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(isDark),
                        )
                      : _placeholder(isDark),

                  // Top gradient shadow
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top-Left Badges: [🛡️ Maklersiz], [🌸 Faqat qizlar]
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.isNoBroker)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Maklersiz',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.isWomenOnly) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.female_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Faqat qizlar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Top-Right: Bookmark Heart & Report Flag
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onReport,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onBookmark,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              bookmarked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: bookmarked
                                  ? const Color(0xFFF43F5E)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-Right of photo: [🎓 TATUgacha 12 daq]
                  if ((estMinutes != null && estMinutes > 0) ||
                      (item.distanceToUniversityKm != null &&
                          item.distanceToUniversityKm! > 0))
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.distanceToUniversityKm != null &&
                                      item.distanceToUniversityKm! > 0
                                  ? '$uniName • ${estMinutes ?? 12} daq (${formatListingDistanceKm(item.distanceToUniversityKm!)} km)'
                                  : '$uniName • $estMinutes daq',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Card Content (STRICTLY 3 VISUAL ROWS)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty) ...[
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Row 1: Price (Left) + Availability / Roommates needed (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${formatListingMoney(item.price)} $currSymbol',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF2DD4BF)
                                  : XonaDoshColors.emeraldDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ oyiga',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? XonaDoshColors.slate400
                                  : XonaDoshColors.slate500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.6)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.type == 'roommate_wanted'
                              ? '🔥 Xonadosh kerak'
                              : '🛏️ ${item.roomsCount} xonali',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 2: Location & Metro
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark
                            ? XonaDoshColors.slate400
                            : XonaDoshColors.slate500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              item.district.isNotEmpty
                                  ? item.district
                                  : item.city,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? XonaDoshColors.slate300
                                    : XonaDoshColors.slate700,
                              ),
                            ),
                            if ((item.nearestMetro ?? '').trim().isNotEmpty)
                              Text(
                                ' • Metro ${(item.nearestMetro ?? '').trim()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? XonaDoshColors.slate300
                                      : XonaDoshColors.slate700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Key Micro-Chips (Wi-Fi, Washer, Utilities, etc.)
                  Row(
                    children: [
                      _microFeature(Icons.meeting_room_outlined, '${item.roomsCount} xona', isDark),
                      const SizedBox(width: 12),
                      _microFeature(Icons.wifi_rounded, 'Wi-Fi', isDark),
                      const SizedBox(width: 12),
                      _microFeature(Icons.local_laundry_service_outlined, 'Kir mashina', isDark),
                      if (item.utilitiesIncluded) ...[
                        const SizedBox(width: 12),
                        _microFeature(Icons.bolt_rounded, 'Kommunal ichida', isDark),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _microFeature(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate600,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      height: 190,
      width: double.infinity,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 40,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}
