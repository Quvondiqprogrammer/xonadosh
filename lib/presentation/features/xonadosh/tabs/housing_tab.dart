import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/api/bookmark_store.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/contact_actions.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';
import '../data/xonadosh_locations.dart';

class XonadoshHousingTab extends ConsumerStatefulWidget {
  const XonadoshHousingTab({super.key});

  @override
  ConsumerState<XonadoshHousingTab> createState() => _XonadoshHousingTabState();
}

class _XonadoshHousingTabState extends ConsumerState<XonadoshHousingTab> {
  final _searchController = TextEditingController();
  final _bookmarkStore = BookmarkStore();
  final Set<int> _bookmarkedIds = {};
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final ids = await _bookmarkStore.load();
    if (!mounted) return;
    setState(() {
      _bookmarkedIds
        ..clear()
        ..addAll(ids);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int _countActiveFilters({
    required String? city,
    required String? district,
    required XonadoshUniversity? uni,
    required String gender,
    required double? minPrice,
    required double? maxPrice,
  }) {
    int count = 0;
    if (city != null) count++;
    if (district != null) count++;
    if (uni != null) count++;
    if (gender != 'any') count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listingsAsync = ref.watch(xonadoshListingsProvider);
    final selectedUni = ref.watch(xonadoshSelectedUniProvider);
    final selectedType = ref.watch(xonadoshTypeFilterProvider);
    final selectedGender = ref.watch(xonadoshGenderFilterProvider);
    final selectedCity = ref.watch(xonadoshCityProvider);
    final selectedDistrict = ref.watch(xonadoshDistrictProvider);
    final minPrice = ref.watch(xonadoshMinPriceProvider);
    final maxPrice = ref.watch(xonadoshMaxPriceProvider);

    final activeFilterCount = _countActiveFilters(
      city: selectedCity,
      district: selectedDistrict,
      uni: selectedUni,
      gender: selectedGender,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    return Scaffold(
      body: RefreshIndicator(
        color: XonaDoshColors.emerald,
        onRefresh: () async {
          ref.invalidate(xonadoshListingsProvider);
          ref.invalidate(xonadoshUniversitiesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Top App Bar / Search & Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar + Filter Button + Map Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) {
                                setState(() {});
                                _searchDebounce?.cancel();
                                _searchDebounce = Timer(
                                  const Duration(milliseconds: 400),
                                  () {
                                    if (!mounted) return;
                                    ref.read(xonadoshSearchQueryProvider.notifier).state =
                                        v.trim().isEmpty ? null : v.trim();
                                  },
                                );
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: l10n.xonadoshSearchPlaceholder,
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, color: XonaDoshColors.emerald, size: 22),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(xonadoshSearchQueryProvider.notifier).state = null;
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Filters button with badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => _openFilterSheet(context),
                              icon: const Icon(Icons.tune_rounded, size: 20),
                              tooltip: 'Filtrlar',
                              style: IconButton.styleFrom(
                                backgroundColor: activeFilterCount > 0
                                    ? XonaDoshColors.emerald.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                foregroundColor: activeFilterCount > 0
                                    ? XonaDoshColors.emeraldDark
                                    : (isDark ? Colors.white : const Color(0xFF334155)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: activeFilterCount > 0
                                        ? XonaDoshColors.emerald
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ),
                            if (activeFilterCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: XonaDoshColors.emerald,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$activeFilterCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 6),

                        // Map icon button
                        IconButton.filled(
                          onPressed: () => context.push(AppRoutes.xonadoshMap),
                          icon: const Icon(Icons.map_rounded, size: 20),
                          tooltip: l10n.xonadoshMapHomesAndUnis,
                          style: IconButton.styleFrom(
                            backgroundColor: XonaDoshColors.emerald,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Category Pill Tabs (Barchasi, Ijara, Sherik, Sotuv, Qidiruv)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildTypeChip('all', l10n.commonAll, Icons.apps_rounded, selectedType),
                          const SizedBox(width: 6),
                          _buildTypeChip('rent', 'Ijara', Icons.home_rounded, selectedType),
                          const SizedBox(width: 6),
                          _buildTypeChip('roommate_wanted', 'Sheriklik', Icons.people_rounded, selectedType),
                          const SizedBox(width: 6),
                          _buildTypeChip('sell', 'Sotuv', Icons.local_offer_rounded, selectedType),
                          const SizedBox(width: 6),
                          _buildTypeChip('buy', 'Qidiruv', Icons.search_rounded, selectedType),
                        ],
                      ),
                    ),

                    // Active Filters Summary Strip (Removable badges)
                    if (activeFilterCount > 0) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            if (selectedCity != null)
                              _buildActiveFilterBadge(
                                '📍 $selectedCity',
                                () => ref.read(xonadoshCityProvider.notifier).state = null,
                              ),
                            if (selectedDistrict != null)
                              _buildActiveFilterBadge(
                                '🏙️ $selectedDistrict',
                                () => ref.read(xonadoshDistrictProvider.notifier).state = null,
                              ),
                            if (selectedUni != null)
                              _buildActiveFilterBadge(
                                '🎓 ${selectedUni.shortName}',
                                () => ref.read(xonadoshSelectedUniProvider.notifier).state = null,
                              ),
                            if (selectedGender != 'any')
                              _buildActiveFilterBadge(
                                selectedGender == 'boys' ? '👨 Yigitlar' : '👩 Qizlar',
                                () => ref.read(xonadoshGenderFilterProvider.notifier).state = 'any',
                              ),
                            if (minPrice != null || maxPrice != null)
                              _buildActiveFilterBadge(
                                '💰 Narx filtri',
                                () {
                                  ref.read(xonadoshMinPriceProvider.notifier).state = null;
                                  ref.read(xonadoshMaxPriceProvider.notifier).state = null;
                                },
                              ),
                            TextButton.icon(
                              onPressed: () {
                                ref.read(xonadoshCityProvider.notifier).state = null;
                                ref.read(xonadoshDistrictProvider.notifier).state = null;
                                ref.read(xonadoshSelectedUniProvider.notifier).state = null;
                                ref.read(xonadoshGenderFilterProvider.notifier).state = 'any';
                                ref.read(xonadoshMinPriceProvider.notifier).state = null;
                                ref.read(xonadoshMaxPriceProvider.notifier).state = null;
                              },
                              icon: const Icon(Icons.clear_all_rounded, size: 16, color: Color(0xFFEF4444)),
                              label: Text(
                                l10n.xonadoshClearFilter,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Listings Stream
            listingsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: XonaDoshColors.emerald),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(context.l10n.xonadoshErrGeneric('$err'), textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(xonadoshListingsProvider),
                          child: Text(context.l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (listings) {
                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: XonaDoshColors.emerald.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.home_work_outlined, size: 52, color: XonaDoshColors.emerald),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.xonadoshNoListingsTitle,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.xonadoshNoListingsSubtitle,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(xonadoshSearchQueryProvider.notifier).state = null;
                                ref.read(xonadoshCityProvider.notifier).state = null;
                                ref.read(xonadoshDistrictProvider.notifier).state = null;
                                ref.read(xonadoshTypeFilterProvider.notifier).state = 'all';
                                ref.read(xonadoshGenderFilterProvider.notifier).state = 'any';
                                ref.read(xonadoshSelectedUniProvider.notifier).state = null;
                                ref.read(xonadoshMinPriceProvider.notifier).state = null;
                                ref.read(xonadoshMaxPriceProvider.notifier).state = null;
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(l10n.xonadoshViewAllListings),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = listings[index];
                        return _buildListingCard(context, item, isDark);
                      },
                      childCount: listings.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.xonadoshCreateListing);
        },
        backgroundColor: XonaDoshColors.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_rounded),
        label: Text(l10n.xonadoshPostListing, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, String selectedType) {
    final isSelected = selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ref.read(xonadoshTypeFilterProvider.notifier).state = type,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F766E) : const Color(0xFF0D9488))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBadge(String text, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: XonaDoshColors.emeraldLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: XonaDoshColors.emerald.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: XonaDoshColors.emeraldDark,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 16, color: XonaDoshColors.emeraldDark),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, XonadoshListing item, bool isDark) {
    final l10n = context.l10n;
    final photo = item.photos.isNotEmpty ? item.photos.first : null;
    final currSymbol = XonadoshLocationData.currencySymbols[item.currency] ?? item.currency;

    final periodLabel = item.pricePeriod == 'month'
        ? l10n.xonadoshPeriodMonth
        : (item.pricePeriod == 'day'
            ? l10n.xonadoshPeriodDay
            : (item.pricePeriod == 'year' ? l10n.xonadoshPeriodYear : l10n.xonadoshPeriodTotal));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.push('${AppRoutes.shell}/listing/${item.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with clean subtle badges
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
                          errorBuilder: (_, _, _) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),

                // Top Left: Clean Type Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(item.type),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(item.type, l10n),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Top Right: Bookmark Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () async {
                      final next = await _bookmarkStore.toggle(item.id);
                      if (!mounted) return;
                      setState(() {
                        _bookmarkedIds
                          ..clear()
                          ..addAll(next);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _bookmarkedIds.contains(item.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _bookmarkedIds.contains(item.id)
                            ? const Color(0xFFF43F5E)
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body: Clean hierarchy, fast to scan
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Price & Quick Action buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_formatMoney(item.price)} $currSymbol',
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
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quick call & telegram action icons
                      IconButton.filledTonal(
                        onPressed: () => ContactActions.callPhone(context, item.phoneNumber),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        tooltip: 'Qo‘ng‘iroq',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          backgroundColor: XonaDoshColors.emerald.withValues(alpha: 0.12),
                          foregroundColor: XonaDoshColors.emeraldDark,
                        ),
                      ),
                      if (item.telegramHandle != null && item.telegramHandle!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () => ContactActions.openTelegram(context, item.telegramHandle),
                          icon: const Icon(Icons.send_rounded, size: 15),
                          tooltip: 'Telegram',
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

                  // Title
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // District & Specs line
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.district.isNotEmpty ? item.district : item.city} · ${item.roomsCount} xona · ${item.areaSqm.toStringAsFixed(0)} m² · ${item.floor}/${item.totalFloors}-qavat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (item.nearestUniversityShort != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🎓 ${item.nearestUniversityShort}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                        ),
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

  Widget _buildPlaceholder() {
    return Container(
      height: 185,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.apartment_rounded, size: 48, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Color _getTypeColor(String type) {
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

  String _getTypeLabel(String type, dynamic l10n) {
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

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(ref: ref),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  const _FilterBottomSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedCity = ref.watch(xonadoshCityProvider);
    final selectedDistrict = ref.watch(xonadoshDistrictProvider);
    final selectedUni = ref.watch(xonadoshSelectedUniProvider);
    final selectedGender = ref.watch(xonadoshGenderFilterProvider);
    final unisAsync = ref.watch(xonadoshUniversitiesProvider);

    final currentRegion = selectedCity != null
        ? XonadoshLocationData.regions.where((r) => r.name == selectedCity).firstOrNull
        : null;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Qidiruv filtrlari',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(xonadoshCityProvider.notifier).state = null;
                      ref.read(xonadoshDistrictProvider.notifier).state = null;
                      ref.read(xonadoshSelectedUniProvider.notifier).state = null;
                      ref.read(xonadoshGenderFilterProvider.notifier).state = 'any';
                      ref.read(xonadoshMinPriceProvider.notifier).state = null;
                      ref.read(xonadoshMaxPriceProvider.notifier).state = null;
                    },
                    child: Text(
                      l10n.xonadoshClearFilter,
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Region / Viloyat
                  const Text('📍 Viloyat / Shahar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(l10n.xonadoshAllRegions),
                          selected: selectedCity == null,
                          onSelected: (_) {
                            ref.read(xonadoshCityProvider.notifier).state = null;
                            ref.read(xonadoshDistrictProvider.notifier).state = null;
                          },
                        ),
                        const SizedBox(width: 6),
                        ...XonadoshLocationData.regions.map((r) {
                          final isSelected = selectedCity == r.name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${r.flag} ${r.name}'),
                              selected: isSelected,
                              onSelected: (sel) {
                                ref.read(xonadoshCityProvider.notifier).state = sel ? r.name : null;
                                ref.read(xonadoshDistrictProvider.notifier).state = null;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // 2. Districts (if region chosen)
                  if (currentRegion != null) ...[
                    const SizedBox(height: 16),
                    const Text('🏙️ Tuman / Hudud', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text(l10n.xonadoshAllDistricts),
                            selected: selectedDistrict == null,
                            onSelected: (_) => ref.read(xonadoshDistrictProvider.notifier).state = null,
                          ),
                          const SizedBox(width: 6),
                          ...currentRegion.districts.map((d) {
                            final isSel = selectedDistrict == d;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(d),
                                selected: isSel,
                                onSelected: (sel) =>
                                    ref.read(xonadoshDistrictProvider.notifier).state = sel ? d : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 3. Universitet
                  const Text('🎓 Yaqin Universitet / Institut', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  unisAsync.when(
                    loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, _) => const SizedBox(),
                    data: (unis) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(l10n.xonadoshAllUniversities),
                              selected: selectedUni == null,
                              onSelected: (_) => ref.read(xonadoshSelectedUniProvider.notifier).state = null,
                            ),
                            const SizedBox(width: 6),
                            ...unis.map((u) {
                              final isSel = selectedUni?.id == u.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(u.shortName),
                                  selected: isSel,
                                  onSelected: (sel) =>
                                      ref.read(xonadoshSelectedUniProvider.notifier).state = sel ? u : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 4. Byudjet / Narx oralig'i
                  const Text('💰 Oylik byudjet (so‘m)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Istalgan narx'),
                        selected: ref.watch(xonadoshMinPriceProvider) == null && ref.watch(xonadoshMaxPriceProvider) == null,
                        onSelected: (_) {
                          ref.read(xonadoshMinPriceProvider.notifier).state = null;
                          ref.read(xonadoshMaxPriceProvider.notifier).state = null;
                        },
                      ),
                      ChoiceChip(
                        label: const Text('1 mln gacha'),
                        selected: ref.watch(xonadoshMinPriceProvider) == null && ref.watch(xonadoshMaxPriceProvider) == 1000000,
                        onSelected: (sel) {
                          ref.read(xonadoshMinPriceProvider.notifier).state = null;
                          ref.read(xonadoshMaxPriceProvider.notifier).state = sel ? 1000000 : null;
                        },
                      ),
                      ChoiceChip(
                        label: const Text('1 – 2 mln'),
                        selected: ref.watch(xonadoshMinPriceProvider) == 1000000 && ref.watch(xonadoshMaxPriceProvider) == 2000000,
                        onSelected: (sel) {
                          ref.read(xonadoshMinPriceProvider.notifier).state = sel ? 1000000 : null;
                          ref.read(xonadoshMaxPriceProvider.notifier).state = sel ? 2000000 : null;
                        },
                      ),
                      ChoiceChip(
                        label: const Text('2 – 3.5 mln'),
                        selected: ref.watch(xonadoshMinPriceProvider) == 2000000 && ref.watch(xonadoshMaxPriceProvider) == 3500000,
                        onSelected: (sel) {
                          ref.read(xonadoshMinPriceProvider.notifier).state = sel ? 2000000 : null;
                          ref.read(xonadoshMaxPriceProvider.notifier).state = sel ? 3500000 : null;
                        },
                      ),
                      ChoiceChip(
                        label: const Text('3.5 mln+'),
                        selected: ref.watch(xonadoshMinPriceProvider) == 3500000 && ref.watch(xonadoshMaxPriceProvider) == null,
                        onSelected: (sel) {
                          ref.read(xonadoshMinPriceProvider.notifier).state = sel ? 3500000 : null;
                          ref.read(xonadoshMaxPriceProvider.notifier).state = null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 5. Jins / Kimlar uchun
                  const Text('👥 Kimlar uchun', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.commonAll),
                        selected: selectedGender == 'any',
                        onSelected: (_) => ref.read(xonadoshGenderFilterProvider.notifier).state = 'any',
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.man_rounded, size: 16),
                        label: Text(l10n.xonadoshForBoys),
                        selected: selectedGender == 'boys',
                        onSelected: (_) => ref.read(xonadoshGenderFilterProvider.notifier).state = 'boys',
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.woman_rounded, size: 16),
                        label: Text(l10n.xonadoshForGirls),
                        selected: selectedGender == 'girls',
                        onSelected: (_) => ref.read(xonadoshGenderFilterProvider.notifier).state = 'girls',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Natijalarni ko‘rish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
