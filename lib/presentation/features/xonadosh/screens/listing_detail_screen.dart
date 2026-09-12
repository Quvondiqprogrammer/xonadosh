import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/block_user_action.dart';
import 'package:xonadosh/presentation/common/contact_actions.dart';
import 'package:xonadosh/presentation/common/report_content_dialog.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class XonadoshListingDetailScreen extends ConsumerStatefulWidget {
  const XonadoshListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  @override
  ConsumerState<XonadoshListingDetailScreen> createState() =>
      _XonadoshListingDetailScreenState();
}

class _XonadoshListingDetailScreenState
    extends ConsumerState<XonadoshListingDetailScreen> {
  int _currentPhotoIndex = 0;
  XonadoshUniversity? _selectedUni;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listingAsync = ref.watch(xonadoshListingDetailProvider(widget.listingId));
    final unisAsync = ref.watch(xonadoshUniversitiesProvider);
    final unis = unisAsync.valueOrNull ?? [];

    return Scaffold(
      body: listingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: XonaDoshColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(context.l10n.xonadoshErrGeneric('$err')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(xonadoshListingDetailProvider(widget.listingId)),
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (item) {
          if (item == null) {
            return Center(child: Text(context.l10n.xonadoshListingNotFound));
          }

          final photos = item.photos.isNotEmpty
              ? item.photos
              : ['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800'];

          return CustomScrollView(
            slivers: [
              // Sliver App Bar with Image Carousel
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    tooltip: context.l10n.commonBack,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go(AppRoutes.shell);
                      }
                    },
                  ),
                ),
                actions: [
                  if (_isOwnListing(ref, item))
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                        tooltip: context.l10n.xonadoshDeleteListing,
                        onPressed: () => _confirmDeleteListing(context, ref, item),
                      ),
                    )
                  else if (item.username.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.block_rounded, color: Colors.white, size: 18),
                        tooltip: context.l10n.blockUser,
                        onPressed: () => confirmAndBlockUser(
                          context,
                          ref,
                          username: item.username,
                          popAfter: true,
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                      tooltip: context.l10n.reportAction,
                      onPressed: () => showReportContentDialog(
                        context,
                        ref,
                        targetType: ReportTargetType.listing,
                        targetId: '${item.id}',
                        subjectLabel: context.l10n.reportContentSubjectListing(item.title),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      tooltip: context.l10n.commonShare,
                      onPressed: () {
                        ContactActions.shareText(
                          context,
                          context.l10n.xonadoshShareListing(
                            item.title,
                            _formatMoney(item.price),
                            item.currency,
                            item.district,
                            item.address,
                            item.phoneNumber,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: photos.length,
                        onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                        itemBuilder: (context, idx) {
                          return Image.network(
                            photos[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                              child: const Icon(Icons.apartment_rounded, size: 64, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black54, Colors.transparent, Colors.black87],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Photo Counter Badge
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPhotoIndex + 1} / ${photos.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Type Badge
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(item.type),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getTypeLabel(context, item.type),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title & Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${_formatMoney(item.price)} ${item.currency}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: XonaDoshColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' / ${item.pricePeriod == 'month' ? context.l10n.xonadoshMonth : context.l10n.xonadoshTotal}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.targetGender != 'any')
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: XonaDoshColors.accentPurple.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.targetGender == 'boys'
                                    ? context.l10n.xonadoshBoysOnly
                                    : context.l10n.xonadoshGirlsOnly,
                                style: const TextStyle(
                                  color: XonaDoshColors.accentPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Key Specs Grid
                    _buildSpecGrid(context, item, isDark),

                    const SizedBox(height: 14),

                    // Location Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: XonaDoshColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: XonaDoshColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.city} • ${item.district}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.address,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Commute & Transit Calculator Card (with dynamic university selector)
                    _buildCommuteCalculatorSection(context, item, unis, isDark),

                    const SizedBox(height: 20),

                    // Amenities
                    if (item.amenities.isNotEmpty) ...[
                      Text(
                        context.l10n.xonadoshAmenitiesTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.amenities.map((a) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getAmenityIcon(a), size: 16, color: XonaDoshColors.primary),
                                const SizedBox(width: 6),
                                Text(a, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    if (item.description.isNotEmpty) ...[
                      Text(
                        context.l10n.xonadoshDescriptionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Landlord / Author Card
                    _buildAuthorCard(item, isDark),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: _buildBottomContactBar(context, ref, isDark),
    );
  }

  Widget _buildCommuteCalculatorSection(
    BuildContext context,
    XonadoshListing item,
    List<XonadoshUniversity> unis,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    // If user selected a custom uni, fetch dynamic commute
    final activeUni = _selectedUni ??
        (item.nearestUniversityId != null
            ? unis.where((u) => u.id == item.nearestUniversityId).firstOrNull
            : unis.firstOrNull);

    final dynamicCommuteAsync = activeUni != null
        ? ref.watch(xonadoshCommuteProvider((
            listingId: item.id,
            uniId: activeUni.id,
          )))
        : null;

    final commute = dynamicCommuteAsync?.valueOrNull ?? item.commute;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.xonadoshTransportAnalysis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              if (commute != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: XonaDoshColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${commute.distanceKm} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: XonaDoshColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Interactive Destination University Selector
          if (unis.isNotEmpty) ...[
            DropdownButtonFormField<XonadoshUniversity>(
              initialValue: activeUni,
              decoration: InputDecoration(
                labelText: context.l10n.xonadoshSelectDestUni,
                prefixIcon: const Icon(Icons.school_rounded, color: XonaDoshColors.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              isExpanded: true,
              items: unis.map((u) {
                return DropdownMenuItem(
                  value: u,
                  child: Text(
                    '${u.shortName} (${u.district})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
              onChanged: (newUni) {
                setState(() => _selectedUni = newUni);
              },
            ),
            const SizedBox(height: 14),
          ],

          // Modes Breakdown List
          if (commute != null) ...[
            _buildModeItem(
              icon: Icons.directions_subway_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: context.l10n.xonadoshMetro,
              subtitle: commute.metro.station ?? context.l10n.xonadoshNearbyStop,
              timeMin: commute.metro.timeMin,
              singleFare: commute.metro.fareUzs,
              monthlyBudget: commute.metro.monthlyBudgetUzs,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildModeItem(
              icon: Icons.directions_bus_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: context.l10n.xonadoshBus,
              subtitle: context.l10n.xonadoshPublicTransit,
              timeMin: commute.bus.timeMin,
              singleFare: commute.bus.fareUzs,
              monthlyBudget: commute.bus.monthlyBudgetUzs,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int timeMin,
    required int singleFare,
    required int monthlyBudget,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withAlpha(120) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? XonaDoshColors.primary.withAlpha(80)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: XonaDoshColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.xonadoshRecommendBadge,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '~ $timeMin ${context.l10n.xonadoshEstimatedTimeMinutes}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              Text(
                singleFare > 0
                    ? context.l10n.xonadoshFareMonthly(
                        _formatMoney(singleFare.toDouble()),
                        context.l10n.currencyUzsSuffix,
                        _formatMoney(monthlyBudget.toDouble()),
                      )
                    : context.l10n.xonadoshFree,
                style: TextStyle(
                  color: singleFare > 0 ? (isDark ? Colors.grey[400] : Colors.grey[700]) : XonaDoshColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGrid(BuildContext context, XonadoshListing item, bool isDark) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildSpecColumn(Icons.meeting_room_outlined, '${item.roomsCount} ${l10n.xonadoshRoomsShort}', l10n.xonadoshRoomsCount)),
          _buildSpecDivider(),
          Expanded(child: _buildSpecColumn(Icons.layers_outlined, '${item.floor}/${item.totalFloors}', l10n.xonadoshFloor)),
          _buildSpecDivider(),
          Expanded(child: _buildSpecColumn(Icons.square_foot_outlined, '${item.areaSqm.toStringAsFixed(0)} m²', l10n.xonadoshAreaShort)),
          _buildSpecDivider(),
          Expanded(child: _buildSpecColumn(Icons.location_city_outlined, item.district, l10n.xonadoshDistrictShort)),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(XonadoshListing item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: XonaDoshColors.primary.withAlpha(25),
            child: Text(
              item.ownerName.isNotEmpty ? item.ownerName[0].toUpperCase() : 'M',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: XonaDoshColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ownerName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.phoneNumber,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (item.telegramHandle != null && item.telegramHandle!.isNotEmpty)
            Text(
              item.telegramHandle!,
              style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomContactBar(BuildContext context, WidgetRef ref, bool isDark) {
    final listingAsync = ref.watch(xonadoshListingDetailProvider(widget.listingId));
    final item = listingAsync.valueOrNull;
    if (item == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: () => ContactActions.callPhone(context, item.phoneNumber),
                onLongPress: () => ContactActions.showContactSheet(
                  context,
                  phone: item.phoneNumber,
                  telegramHandle: item.telegramHandle,
                ),
                icon: const Icon(Icons.call_rounded, size: 20),
                label: Text(
                  context.l10n.xonadoshCallBtn,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: XonaDoshColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            if (item.telegramHandle != null && item.telegramHandle!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => ContactActions.openTelegram(context, item.telegramHandle),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Telegram',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('wi-fi') || n.contains('wifi') || n.contains('internet')) return Icons.wifi_rounded;
    if (n.contains('kir') || n.contains('mashina')) return Icons.local_laundry_service_rounded;
    if (n.contains('muz') || n.contains('xolod')) return Icons.kitchen_rounded;
    if (n.contains('kondit') || n.contains('havo')) return Icons.ac_unit_rounded;
    if (n.contains('mebel') || n.contains('krovat')) return Icons.chair_rounded;
    if (n.contains('suv') || n.contains('isitish')) return Icons.water_drop_rounded;
    if (n.contains('balkon')) return Icons.balcony_rounded;
    if (n.contains('televizor') || n.contains('tv')) return Icons.tv_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'roommate_wanted':
        return XonaDoshColors.accentPurple;
      case 'sell':
        return const Color(0xFFF59E0B);
      default:
        return XonaDoshColors.primary;
    }
  }

  String _getTypeLabel(BuildContext context, String type) {
    switch (type) {
      case 'roommate_wanted':
        return context.l10n.xonadoshTypeRoommateNeeded;
      case 'sell':
        return context.l10n.xonadoshTypeForSale;
      case 'buy':
        return context.l10n.xonadoshTypeLookingRent;
      default:
        return context.l10n.xonadoshTypeForRent;
    }
  }

  Widget _buildSpecColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: XonaDoshColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpecDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.withAlpha(60),
    );
  }

  bool _isOwnListing(WidgetRef ref, XonadoshListing item) {
    final me = ref.read(sessionManagerProvider).username?.trim().toLowerCase();
    final owner = item.username.trim().toLowerCase();
    return me != null && me.isNotEmpty && owner.isNotEmpty && me == owner;
  }

  Future<void> _confirmDeleteListing(
    BuildContext context,
    WidgetRef ref,
    XonadoshListing item,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.xonadoshDeleteListing, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(l10n.xonadoshDeleteListingBody, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ref.read(xonadoshRepositoryProvider).deleteListing(item.id);
    if (!context.mounted) return;
    if (res['ok'] == true) {
      ref.invalidate(xonadoshListingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.xonadoshListingDeleted)),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(AppRoutes.shell);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error']?.toString() ?? l10n.errorGeneric)),
      );
    }
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}
