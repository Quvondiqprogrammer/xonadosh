import 'package:flutter/material.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/features/xonadosh/data/xonadosh_locations.dart';

String formatListingMoney(double amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
}

String formatListingDistanceKm(double km) {
  if (km < 0.1) return '<0.1 km';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.toStringAsFixed(0)} km';
}

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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photo = item.photos.isNotEmpty ? item.photos.first : null;
    final currSymbol = XonadoshLocationData.currencySymbols[item.currency] ?? item.currency;
    final periodLabel = item.pricePeriod == 'month'
        ? l10n.xonadoshPeriodMonth
        : (item.pricePeriod == 'day'
            ? l10n.xonadoshPeriodDay
            : (item.pricePeriod == 'year' ? l10n.xonadoshPeriodYear : l10n.xonadoshPeriodTotal));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: XonaDoshStyles.cardDecoration(isDark),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: photo != null
                      ? Image.network(
                          photo,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor(item.type),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel(item.type, l10n),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _roundIconButton(
                        icon: Icons.flag_outlined,
                        tooltip: l10n.reportAction,
                        onTap: onReport,
                      ),
                      const SizedBox(width: 6),
                      _roundIconButton(
                        icon: bookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        tooltip: l10n.commonSave,
                        color: bookmarked ? const Color(0xFFF43F5E) : Colors.white,
                        onTap: onBookmark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${formatListingMoney(item.price)} $currSymbol',
                              style: const TextStyle(
                                color: XonaDoshColors.emeraldDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ $periodLabel',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: onCall,
                        icon: const Icon(Icons.call_rounded, size: 16),
                        tooltip: l10n.xonadoshCallShort,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          backgroundColor: XonaDoshColors.emerald.withValues(alpha: 0.12),
                          foregroundColor: XonaDoshColors.emeraldDark,
                        ),
                      ),
                      if (onTelegram != null) ...[
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: onTelegram,
                          icon: const Icon(Icons.send_rounded, size: 15),
                          tooltip: l10n.xonadoshTelegram,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            foregroundColor: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _specsLine(item, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _metaChip(
                        isDark,
                        Icons.location_on_outlined,
                        item.district.isNotEmpty ? item.district : item.city,
                      ),
                      if ((item.nearestMetro ?? '').trim().isNotEmpty)
                        _metaChip(
                          isDark,
                          Icons.subway_outlined,
                          l10n.xonadoshNearMetro(item.nearestMetro!.trim()),
                        ),
                      if (item.nearestUniversityShort != null ||
                          item.distanceToUniversityKm != null)
                        _metaChip(
                          isDark,
                          Icons.school_outlined,
                          _uniChipLabel(item, l10n),
                        ),
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

  String _specsLine(XonadoshListing item, AppLocalizations l10n) {
    final rooms = '${item.roomsCount} ${l10n.xonadoshRoomsShort}';
    final area = '${item.areaSqm.toStringAsFixed(0)} m²';
    final floor = '${item.floor}/${item.totalFloors} ${l10n.xonadoshFloorShort}';
    return '$rooms · $area · $floor';
  }

  String _uniChipLabel(XonadoshListing item, AppLocalizations l10n) {
    final short = (item.nearestUniversityShort ?? '').trim();
    final dist = item.distanceToUniversityKm;
    if (short.isNotEmpty && dist != null) {
      return '$short · ${l10n.xonadoshKmAway(formatListingDistanceKm(dist))}';
    }
    if (short.isNotEmpty) return short;
    if (dist != null) return l10n.xonadoshKmAway(formatListingDistanceKm(dist));
    return l10n.xonadoshUniFallback;
  }

  Widget _metaChip(bool isDark, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 180,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.apartment_rounded, size: 48, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'roommate_wanted':
        return XonaDoshColors.accentPurple;
      case 'sell':
        return XonaDoshColors.amber;
      case 'buy':
        return const Color(0xFF0284C7);
      default:
        return XonaDoshColors.emerald;
    }
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'roommate_wanted':
        return l10n.xonadoshNeedRoommate;
      case 'sell':
        return l10n.xonadoshForSale;
      case 'buy':
        return l10n.xonadoshSearchTag;
      default:
        return l10n.xonadoshRentHouse;
    }
  }
}
