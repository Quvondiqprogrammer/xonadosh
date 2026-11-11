import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/contact_actions.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import '../widgets/xonadosh_create_recipe_sheet.dart';
import '../widgets/xonadosh_recipe_picker_sheet.dart';

class XonadoshColivingTab extends ConsumerStatefulWidget {
  const XonadoshColivingTab({super.key});

  @override
  ConsumerState<XonadoshColivingTab> createState() =>
      _XonadoshColivingTabState();
}

class _XonadoshColivingTabState extends ConsumerState<XonadoshColivingTab> {
  // 0: 🧹 Navbat va Uy, 1: 💰 Umumiy Kassa, 2: 🍲 Oshxona va Bozor
  int _activeSubTab = 0;
  int _kitchenSubIndex = 0;

  /// Moliya filtri: all | due | rent | utility | expense
  String _financeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Pre-warm polls & karma providers in background
    ref.watch(xonadoshPollsProvider);
    ref.watch(xonadoshKarmaProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            color: theme.scaffoldBackgroundColor,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSubTabSegment(0, 'Navbatchilik', isDark),
                  ),
                  Expanded(
                    child: _buildSubTabSegment(1, 'Umumiy Kassa', isDark),
                  ),
                  Expanded(
                    child: _buildSubTabSegment(2, 'Oshxona & Bozor', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Quick House Tools Strip (Xonadon Tezkor Asboblari)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final groupCode = ref.watch(colivingGroupCodeProvider);
                    final displayName = groupCode == 'home_default'
                        ? 'Namunaviy Uy'
                        : groupCode;
                    return _buildQuickPill(
                      icon: Icons.home_work_rounded,
                      label: 'Uy: $displayName',
                      color: XonaDoshColors.primary,
                      isDark: isDark,
                      onTap: () => _openHouseManagementModal(context, isDark),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.gavel_rounded,
                  label: 'Uy Qoidalari',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                  onTap: () => _openHouseRulesModal(context),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.how_to_vote_rounded,
                  label: 'Ovoz berish',
                  color: XonaDoshColors.primary,
                  isDark: isDark,
                  onTap: () => _openPollsModal(context, isDark),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.star_rounded,
                  label: 'Obro‘ (Karma)',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: () => _openKarmaModal(context, isDark),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.add_rounded,
                  label: 'Tezkor qo‘shish',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _openQuickAddSheet(context, isDark),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.electric_bolt_rounded,
                  label: 'Hisoblagichlar',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: () => _openUtilityMeterModal(context, isDark),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.no_meals_rounded,
                  label: 'Bugun yemayman',
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                  onTap: () => _openOptOutMealModal(context, isDark),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Navbat almashish',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () => _openChoreSwapModal(context, isDark),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  icon: Icons.account_balance_rounded,
                  label: '50% Kompensatsiya',
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                  onTap: () => _openStudentSubsidyModal(context, isDark),
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (_activeSubTab) {
                0 => _buildDutyRosterView(context, isDark),
                1 => _buildFinancesView(context, isDark),
                2 => _buildKitchenAndGroceryView(context, isDark),
                _ => _buildDutyRosterView(context, isDark),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickAddSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tezkor qo‘shish',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _buildQuickAddTile(
                  icon: Icons.cleaning_services_rounded,
                  color: XonaDoshColors.primary,
                  title: 'Yangi navbatchilik vazifasi',
                  subtitle: 'Xonadon tartibi yoki tozalik biriktirish',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddChoreDialog(context);
                  },
                  isDark: isDark,
                ),
                _buildQuickAddTile(
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Yangi xarajat yoki kommunal',
                  subtitle: 'Ijara, svet, gaz yoki bozorlik xarajati',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddFinanceDialog(context);
                  },
                  isDark: isDark,
                ),
                _buildQuickAddTile(
                  icon: Icons.how_to_vote_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Yangi masala (ovoz berish)',
                  subtitle: 'Anonim ovoz berish uchun mavzu kiritish',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreatePollDialog(context);
                  },
                  isDark: isDark,
                ),
                _buildQuickAddTile(
                  icon: Icons.restaurant_menu_rounded,
                  color: const Color(0xFFD97706),
                  title: 'Yangi taom retsepti',
                  subtitle: 'Haftalik taomnoma uchun retsept qo‘shish',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreateRecipeSheet(context);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAddTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSubTabSegment(int index, String label, bool isDark) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _activeSubTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F766E) : XonaDoshColors.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: XonaDoshColors.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildKitchenAndGroceryView(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kitchenSubIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _kitchenSubIndex == 0
                          ? (isDark
                                ? const Color(0xFF0F766E)
                                : XonaDoshColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Haftalik Taomnoma',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _kitchenSubIndex == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _kitchenSubIndex == 0
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kitchenSubIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _kitchenSubIndex == 1
                          ? (isDark
                                ? const Color(0xFF0F766E)
                                : XonaDoshColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Bozorlik va Narxlar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _kitchenSubIndex == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _kitchenSubIndex == 1
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _kitchenSubIndex == 0
              ? _buildMealPlanView(context, isDark)
              : _buildGroceryView(context, isDark),
        ),
      ],
    );
  }

  void _openPollsModal(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: Consumer(builder: (c, ref, _) => _buildPollsView(c, isDark)),
      ),
    );
  }

  void _openKarmaModal(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: Consumer(builder: (c, ref, _) => _buildKarmaView(c, isDark)),
      ),
    );
  }

  // ==========================================
  // 1. NAVBATCHILIK (DUTY ROSTER) VIEW
  // ==========================================
  String _getLocalizedDayName(String day, dynamic l10n) {
    switch (day.toLowerCase()) {
      case 'dushanba':
        return l10n.xonadoshDayMonday;
      case 'seshanba':
        return l10n.xonadoshDayTuesday;
      case 'chorshanba':
        return l10n.xonadoshDayWednesday;
      case 'payshanba':
        return l10n.xonadoshDayThursday;
      case 'juma':
        return l10n.xonadoshDayFriday;
      case 'shanba':
        return l10n.xonadoshDaySaturday;
      case 'yakshanba':
        return l10n.xonadoshDaySunday;
      default:
        return day;
    }
  }

  Widget _buildDutyRosterView(BuildContext context, bool isDark) {
    final choresAsync = ref.watch(xonadoshChoresProvider);

    return choresAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: XonaDoshColors.emerald),
      ),
      error: (err, _) =>
          Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        final todayDuties = data.todayDuties;
        final allChores = data.allChores;
        final completedToday = todayDuties.where((c) => c.isCompleted).length;
        final totalToday = todayDuties.length;
        final todayProgress = totalToday > 0
            ? completedToday / totalToday
            : 0.0;
        final allTodayDone = totalToday > 0 && completedToday == totalToday;

        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async => ref.refresh(xonadoshChoresProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Today Duty Hero Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: allTodayDone
                        ? const Color(0xFF10B981)
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                    width: allTodayDone ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: XonaDoshColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.today_rounded,
                                  color: XonaDoshColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bugun: ${_getLocalizedDayName(data.todayDay, context.l10n)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Xonadon navbatchiligi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: allTodayDone
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15)
                                : XonaDoshColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$completedToday/$totalToday bajarildi',
                            style: TextStyle(
                              color: allTodayDone
                                  ? const Color(0xFF059669)
                                  : XonaDoshColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (totalToday > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: todayProgress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          color: allTodayDone
                              ? const Color(0xFF10B981)
                              : XonaDoshColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (todayDuties.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.spa_outlined,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.xonadoshNoDutyToday,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (allTodayDone)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFF059669),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bugungi barcha vazifalar to‘liq bajarildi!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...todayDuties.map(
                        (chore) =>
                            _buildChoreItem(chore, isDark, isToday: true),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Raqamli Kodeks pinned preview
              _buildHouseRulesPinnedCard(context, isDark),

              const SizedBox(height: 12),

              // Weekly Schedule Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Haftalik navbatchilik jadvali',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showAddChoreDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Vazifa qo‘shish',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Group chores by day
              ...[
                'dushanba',
                'seshanba',
                'chorshanba',
                'payshanba',
                'juma',
                'shanba',
                'yakshanba',
              ].map((day) {
                final dayChores = allChores
                    .where((c) => c.dayOfWeek == day)
                    .toList();
                final isToday = day == data.todayDay;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isToday
                              ? XonaDoshColors.emerald
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE8EEF3)),
                          width: isToday ? 1.6 : 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: isToday,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                          leading: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: isToday
                                ? XonaDoshColors.emerald
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                          ),
                          title: Row(
                            children: [
                              Text(
                                _getLocalizedDayName(day, context.l10n),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isToday
                                      ? XonaDoshColors.emerald
                                      : null,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: XonaDoshColors.emerald,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'BUGUN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${dayChores.length} ta vazifa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          children: [
                            if (dayChores.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Bu kunga vazifalar biriktirilmagan',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  0,
                                  10,
                                  8,
                                ),
                                child: Column(
                                  children: dayChores
                                      .map((c) => _buildChoreItem(c, isDark))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoreItem(
    XonadoshChore chore,
    bool isDark, {
    bool isToday = false,
  }) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return InkWell(
      onTap: () async {
        await ref
            .read(xonadoshRepositoryProvider)
            .toggleChoreDone(
              choreId: chore.id,
              isCompleted: !chore.isCompleted,
            );
        ref.invalidate(xonadoshChoresProvider);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: chore.isCompleted
                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: chore.isCompleted,
              activeColor: XonaDoshColors.emerald,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              visualDensity: VisualDensity.compact,
              onChanged: (val) async {
                await ref
                    .read(xonadoshRepositoryProvider)
                    .toggleChoreDone(
                      choreId: chore.id,
                      isCompleted: val ?? false,
                    );
                ref.invalidate(xonadoshChoresProvider);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chore.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: chore.isCompleted
                          ? (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8))
                          : null,
                      decoration: chore.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (chore.notes.isNotEmpty)
                    Text(
                      chore.notes,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _avatarInitial(chore.assignedName, XonaDoshColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    chore.assignedName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseRulesPinnedCard(BuildContext context, bool isDark) {
    final groupCode = ref.watch(colivingGroupCodeProvider);
    final rulesAsync = ref.watch(
      xonadoshHouseRulesAgreementProvider(groupCode),
    );
    final session = ref.watch(sessionManagerProvider);
    final myUsername = session.username ?? '';

    return rulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (rules) {
        final alreadyConfirmed = rules.confirmedBy.contains(myUsername);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rules.isAgreed
                  ? const Color(0xFF10B981)
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
              width: rules.isAgreed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Text('📜', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Xonadoshlik Kodeksi',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: rules.isAgreed
                          ? const Color(0xFF10B981).withAlpha(25)
                          : const Color(0xFFF59E0B).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rules.isAgreed
                          ? '✓ Tasdiqlangan'
                          : 'Kelishilmoqda (${rules.confirmedBy.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rules.isAgreed
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRuleRow(
                Icons.bedtime_outlined,
                'Sokinlik soati',
                '${rules.quietHoursStart} dan boshlab',
                isDark,
              ),
              _buildRuleRow(
                Icons.calendar_month_outlined,
                'Ijara to‘lovi',
                'Har oyning ${rules.rentDueDay}-sanasigacha',
                isDark,
              ),
              _buildRuleRow(
                Icons.group_outlined,
                'Mehmonlar',
                rules.guestPolicy,
                isDark,
              ),
              _buildRuleRow(
                Icons.shopping_bag_outlined,
                'Umumiy xarid',
                rules.commonGroceries,
                isDark,
              ),
              _buildRuleRow(
                Icons.moving_outlined,
                'Ko‘chish haqida',
                'Kamida ${rules.moveOutNoticeDays} kun oldin ogohlantirish',
                isDark,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditHouseRulesDialog(context, rules),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text(
                      'Tahrirlash',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  if (!alreadyConfirmed && myUsername.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final currentCode = ref.read(colivingGroupCodeProvider);
                          await ref
                              .read(xonadoshRepositoryProvider)
                              .saveHouseRulesAgreement(
                                groupCode: currentCode,
                                quietHoursStart: rules.quietHoursStart,
                                rentDueDay: rules.rentDueDay,
                                guestPolicy: rules.guestPolicy,
                                commonGroceries: rules.commonGroceries,
                                moveOutNoticeDays: rules.moveOutNoticeDays,
                                confirm: true,
                              );
                          ref.invalidate(
                            xonadoshHouseRulesAgreementProvider(currentCode),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '✓ Qoidalar qabul qilindi va tasdiqlandi!',
                                ),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Xatolik: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: const Text(
                        'Qabul qilish',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditHouseRulesDialog(
    BuildContext context,
    XonadoshHouseRulesAgreement rules,
  ) {
    final quietCtrl = TextEditingController(text: rules.quietHoursStart);
    final rentCtrl = TextEditingController(text: rules.rentDueDay.toString());
    final guestCtrl = TextEditingController(text: rules.guestPolicy);
    final groceriesCtrl = TextEditingController(text: rules.commonGroceries);
    final noticeCtrl = TextEditingController(
      text: rules.moveOutNoticeDays.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, size: 20, color: XonaDoshColors.primary),
            SizedBox(width: 8),
            Text(
              'Xonadoshlik Kodeksini tahrirlash',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quietCtrl,
                decoration: const InputDecoration(
                  labelText: '1. Sokinlik soati (boshlanishi)',
                  hintText: '23:00',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '2. Ijara to‘lov sanasi (oy kuni)',
                  hintText: '5',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: guestCtrl,
                decoration: const InputDecoration(
                  labelText: '3. Mehmon kelishi tartibi',
                  hintText: 'Oldindan guruhda ogohlantirish',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: groceriesCtrl,
                decoration: const InputDecoration(
                  labelText: '4. Umumiy bozorlik mahsulotlari',
                  hintText: 'Non, choy, shakar, yog‘',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noticeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '5. Ko‘chib ketish ogohlantirish (kun)',
                  hintText: '15',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final currentCode = ref.read(colivingGroupCodeProvider);
                await ref
                    .read(xonadoshRepositoryProvider)
                    .saveHouseRulesAgreement(
                      groupCode: currentCode,
                      quietHoursStart: quietCtrl.text.trim(),
                      rentDueDay: int.tryParse(rentCtrl.text.trim()) ?? 5,
                      guestPolicy: guestCtrl.text.trim(),
                      commonGroceries: groceriesCtrl.text.trim(),
                      moveOutNoticeDays:
                          int.tryParse(noticeCtrl.text.trim()) ?? 15,
                      confirm: true,
                    );
                ref.invalidate(
                  xonadoshHouseRulesAgreementProvider(currentCode),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Kodeks muvaffaqiyatli saqlandi!'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
                }
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInstantGroceryExpense(
    BuildContext context,
    XonadoshGroceryCalculation calc,
  ) async {
    final session = ref.read(sessionManagerProvider);
    final myName = session.user?.displayName ?? session.username ?? 'Navbatchi';
    final amount = calc.perPersonDailyUzs > 0
        ? calc.perPersonDailyUzs.toDouble()
        : 68000.0;

    try {
      await ref.read(xonadoshRepositoryProvider).addFinance({
        'title': 'Kunlik umumiy bozorlik',
        'type': 'expense_split',
        'amount': amount,
        'paid_by': myName,
        'roommates': [myName, 'Xonadoshlar'],
        'splits': [
          {'name': myName, 'amount': amount / 2, 'paid': 1},
          {'name': 'Xonadoshlar', 'amount': amount / 2, 'paid': 0},
        ],
        'group_code': ref.read(colivingGroupCodeProvider),
      });
      ref.invalidate(xonadoshFinancesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${_formatMoney(amount)} so‘m bozorlik xarajati umumiy hisob-kitobga kiritildi!',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    }
  }

  // ==========================================
  // 2. TAOMNOMA (MEAL PLAN) VIEW
  // ==========================================
  Widget _buildMealPlanView(BuildContext context, bool isDark) {
    final mealPlanAsync = ref.watch(xonadoshRecipesAndMealPlanProvider);

    return mealPlanAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: XonaDoshColors.emerald),
      ),
      error: (err, _) =>
          Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        final Map<String, List<XonadoshMealPlan>> grouped = {};
        for (final m in data.mealPlans) {
          grouped.putIfAbsent(m.dayOfWeek, () => []).add(m);
        }

        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async =>
              ref.refresh(xonadoshRecipesAndMealPlanProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Meal Plan Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.xonadosh7DayPlan,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showCreateRecipeSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        context.l10n.xonadoshAddNewRecipe,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              ...[
                'dushanba',
                'seshanba',
                'chorshanba',
                'payshanba',
                'juma',
                'shanba',
                'yakshanba',
              ].map((day) {
                final meals = grouped[day] ?? [];
                return _buildDayAccordionCard(context, day, meals, isDark);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayAccordionCard(
    BuildContext context,
    String day,
    List<XonadoshMealPlan> meals,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: day == 'dushanba',
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 0,
              ),
              leading: const Icon(
                Icons.restaurant_menu_rounded,
                size: 18,
                color: XonaDoshColors.emerald,
              ),
              title: Text(
                _getLocalizedDayName(day, context.l10n),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    children: ['breakfast', 'lunch', 'dinner'].map((mealTime) {
                      final plan = meals.firstWhere(
                        (m) => m.mealTime == mealTime,
                        orElse: () => XonadoshMealPlan(
                          id: 0,
                          dayOfWeek: day,
                          mealTime: mealTime,
                          recipeId: null,
                          recipeName: 'Taom tanlanmagan',
                          cookName: 'Navbatchi',
                          prepSchedule: '19:00 - 19:30',
                          eatingSchedule: '19:30 - 20:15',
                          cleanupSchedule: '20:15 - 20:30',
                          breadCount: 0.5,
                          teaType: "Ko'k choy (95-nav)",
                          caloriesKcal: 500,
                          prepTimeMin: 20,
                          costLevel: 'budget',
                        ),
                      );

                      final mealIconData = switch (mealTime) {
                        'breakfast' => Icons.wb_twilight_rounded,
                        'lunch' => Icons.wb_sunny_outlined,
                        _ => Icons.bedtime_outlined,
                      };
                      final mealIconColor = switch (mealTime) {
                        'breakfast' => const Color(0xFFF59E0B),
                        'lunch' => const Color(0xFFEAB308),
                        _ => const Color(0xFF6366F1),
                      };

                      final mealLabel = switch (mealTime) {
                        'breakfast' => 'Nonushta',
                        'lunch' => 'Tushlik',
                        _ => 'Kechki ovqat',
                      };

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: mealIconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                mealIconData,
                                size: 16,
                                color: mealIconColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mealLabel,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    plan.recipeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Oshpaz: ${plan.cookName} • ${plan.prepSchedule}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 20,
                                color: XonaDoshColors.emerald,
                              ),
                              onPressed: () => _showRecipePickerSheet(
                                context,
                                day,
                                mealTime,
                                plan.recipeName,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. BOZORLIK & REAL BOZOR NARXLARI VIEW
  // ==========================================
  Widget _buildGroceryView(BuildContext context, bool isDark) {
    final groceryAsync = ref.watch(xonadoshGroceryCalculationProvider);
    final roommateCount = ref.watch(xonadoshRoommateCountProvider);

    return groceryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: XonaDoshColors.emerald),
      ),
      error: (err, _) =>
          Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (calc) {
        if (calc == null) {
          return Center(child: Text(context.l10n.xonadoshCalcFailed));
        }

        final bread = calc.breadBreakdown;

        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async =>
              ref.refresh(xonadoshGroceryCalculationProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // 1. Roommates Count Stepper
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE8EEF3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group_rounded,
                      color: XonaDoshColors.emerald,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.xonadoshRoommatesCountLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: roommateCount > 1
                          ? () {
                              ref
                                  .read(xonadoshRoommateCountProvider.notifier)
                                  .state--;
                              ref.invalidate(
                                xonadoshGroceryCalculationProvider,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        context.l10n.xonadoshPeopleCount(roommateCount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: roommateCount < 10
                          ? () {
                              ref
                                  .read(xonadoshRoommateCountProvider.notifier)
                                  .state++;
                              ref.invalidate(
                                xonadoshGroceryCalculationProvider,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Main Budget Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.xonadoshWeeklyGrocerySummary,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${context.l10n.xonadosh21Meals7Days} ($roommateCount kishi)',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_formatMoney(calc.totalCostUzs.toDouble())} so‘m',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryTile(
                            context.l10n.xonadosh1PersonWeek,
                            '${_formatMoney(calc.perPersonUzs.toDouble())} so‘m',
                            XonaDoshColors.primary,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryTile(
                            context.l10n.xonadosh1PersonDay,
                            '~${_formatMoney(calc.perPersonDailyUzs.toDouble())} so‘m',
                            const Color(0xFFD97706),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: XonaDoshColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '📍 ${calc.cheapestMarket}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 1-Tap Bozorlik to Finance Button
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _handleInstantGroceryExpense(context, calc),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text(
                    'Bozorlik qildim (${_formatMoney(calc.perPersonDailyUzs.toDouble())} so‘m)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Bread Breakdown Card
              if (bread.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bakery_dining_rounded,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.xonadoshBreadCalcTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Qolipli buxanka (ertalab/kunduzi): ${bread['total_buxanka'] ?? bread['breakfast_lunch_buxanka'] ?? 0} dona',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF451A03),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tandir patir / Obi non (kechki ovqat): ${bread['total_patir'] ?? bread['dinner_patir'] ?? 0} dona',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF451A03),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jami haftalik non sarfi: ~${_formatMoney((bread['weekly_total_bread_spend'] as num?)?.toDouble() ?? 0)} so‘m',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // 4. Checklist Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.xonadoshGroceryListCount(calc.items.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final allChecked = calc.items.every((it) => it.isBought);
                      setState(() {
                        for (final it in calc.items) {
                          it.isBought = !allChecked;
                        }
                      });
                    },
                    child: Text(
                      calc.items.every((it) => it.isBought)
                          ? context.l10n.commonClear
                          : context.l10n.xonadoshAllBought,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 5. Expandable Item Cards
              ...calc.items.map(
                (it) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE8EEF3),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          leading: Checkbox(
                            value: it.isBought,
                            activeColor: XonaDoshColors.emerald,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) =>
                                setState(() => it.isBought = val ?? false),
                          ),
                          title: Text(
                            it.nameUz,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              decoration: it.isBought
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: it.isBought ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(
                            '${it.quantity} ${it.unit}  •  ~${_formatMoney(it.unitPriceUzs)} so‘m/${it.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          trailing: Text(
                            '${_formatMoney(it.totalPriceUzs)} so‘m',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: it.isBought
                                  ? Colors.grey
                                  : XonaDoshColors.emeraldDark,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (it.cheapestSource.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.storefront_rounded,
                                          size: 14,
                                          color: XonaDoshColors.emerald,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Eng arzon manba: ${it.cheapestSource}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: XonaDoshColors.emeraldDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (it.buyingTips.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.lightbulb_outline_rounded,
                                          size: 14,
                                          color: Color(0xFFF59E0B),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            it.buyingTips,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (it.minPriceUzs > 0 &&
                                      it.maxPriceUzs > 0) ...[
                                    Text(
                                      'Bozor narxlari oralig‘i: ${_formatMoney(it.minPriceUzs)} – ${_formatMoney(it.maxPriceUzs)} so‘m/${it.unit}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (it.usedForMeals.isNotEmpty) ...[
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: it.usedForMeals
                                          .map(
                                            (m) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF0F172A)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                m,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 4. MOLIYA, IJARA, KOMMUNAL VA QARZ VIEW
  // ==========================================
  Widget _buildFinancesView(BuildContext context, bool isDark) {
    final financesAsync = ref.watch(xonadoshFinancesProvider);

    return financesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: XonaDoshColors.emerald),
      ),
      error: (err, _) =>
          Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        final allItems = [
          ...data.rentItems,
          ...data.utilityItems,
          ...data.expenseItems,
        ];
        final dueCount = allItems.where((e) => !e.isSettled).length;
        final filtered = allItems.where((item) {
          return switch (_financeFilter) {
            'due' => !item.isSettled,
            'rent' => item.type == 'rent',
            'utility' => item.type == 'utility',
            'expense' => item.type == 'expense_split' || item.type == 'debt',
            _ => true,
          };
        }).toList();

        return Stack(
          children: [
            RefreshIndicator(
              color: XonaDoshColors.emerald,
              onRefresh: () async => ref.refresh(xonadoshFinancesProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // Katta Balans Kartasi (Splitwise style)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: data.totalPendingUzs > 0
                          ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                          : const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: data.totalPendingUzs > 0
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              data.totalPendingUzs > 0
                                  ? Icons.arrow_outward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: data.totalPendingUzs > 0
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.totalPendingUzs > 0
                                    ? "Siz ${_formatMoney(data.totalPendingUzs.toDouble())} so‘m qarzsiz"
                                    : "Barcha hisob-kitoblar toza (0 so‘m qarz)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: data.totalPendingUzs > 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                onPressed: () => _showAddFinanceDialog(context),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  '➕ Xarajat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: XonaDoshColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _shareFinancesReport(context, data),
                                icon: const Icon(Icons.share_rounded, size: 16),
                                label: const Text(
                                  'Hisobot',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Compact summary — numbers first, almost no prose
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _financeStat(
                                Icons.account_balance_wallet_rounded,
                                _formatMoney(data.totalSpendUzs.toDouble()),
                                'Jami',
                                XonaDoshColors.primary,
                                isDark,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _financeStat(
                                Icons.schedule_rounded,
                                _formatMoney(data.totalPendingUzs.toDouble()),
                                'Qarz',
                                const Color(0xFFEF4444),
                                isDark,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _financeStat(
                                Icons.check_circle_outline_rounded,
                                '$dueCount',
                                'Kutilmoqda',
                                const Color(0xFFF59E0B),
                                isDark,
                              ),
                            ),
                          ],
                        ),
                        if (data.totalSpendUzs > 0) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  ((data.totalSpendUzs - data.totalPendingUzs) /
                                          data.totalSpendUzs)
                                      .clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              color: XonaDoshColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(((data.totalSpendUzs - data.totalPendingUzs) / data.totalSpendUzs) * 100).round()}% to‘langan',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _shareTelegramReport(context, data),
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text(
                                  'Telegramga ulashish',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0284C7),
                                  side: const BorderSide(
                                    color: Color(0xFF0284C7),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showQuickSplitDialog(context),
                              icon: const Icon(
                                Icons.calculate_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Taqsimlash',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: XonaDoshColors.emerald,
                                side: const BorderSide(
                                  color: XonaDoshColors.emerald,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (data.debtBalances.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🤝 Xonadoshlar o‘rtasidagi balans',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${data.debtBalances.length} ta',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.debtBalances.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = data.debtBalances[i];
                          return Material(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () =>
                                  _showDebtPaymentSheet(context, d, isDark),
                              child: Container(
                                width: 175,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _avatarInitial(
                                          d.debtor,
                                          const Color(0xFFF59E0B),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                        _avatarInitial(
                                          d.creditor,
                                          XonaDoshColors.emerald,
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFF59E0B,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'To‘lash ›',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_formatMoney(d.amountUzs.toDouble())} so‘m',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                    Text(
                                      '${d.debtor} ➔ ${d.creditor}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _financeChip('all', 'Hammasi', allItems.length, isDark),
                        _financeChip('due', 'Qarzda', dueCount, isDark),
                        _financeChip(
                          'rent',
                          'Ijara',
                          data.rentItems.length,
                          isDark,
                        ),
                        _financeChip(
                          'utility',
                          'Kommunal',
                          data.utilityItems.length,
                          isDark,
                        ),
                        _financeChip(
                          'expense',
                          'Xarid',
                          data.expenseItems.length,
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bo‘sh',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(
                      (f) => _buildFinanceItemCard(context, f, isDark),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddFinanceDialog(context),
                backgroundColor: XonaDoshColors.emerald,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'To‘lov',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _financeStat(
    IconData icon,
    String value,
    String label,
    Color accent,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial(String name, Color color) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _financeChip(String key, String label, int count, bool isDark) {
    final selected = _financeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text('$label · $count'),
        onSelected: (_) => setState(() => _financeFilter = key),
        selectedColor: XonaDoshColors.emerald.withValues(
          alpha: isDark ? 0.25 : 0.15,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        side: BorderSide(
          color: selected
              ? XonaDoshColors.emerald
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: selected
              ? XonaDoshColors.emeraldDark
              : (isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  IconData _financeTypeIcon(String type) {
    return switch (type) {
      'rent' => Icons.home_rounded,
      'utility' => Icons.bolt_rounded,
      'debt' => Icons.handshake_rounded,
      _ => Icons.shopping_bag_rounded,
    };
  }

  Color _financeTypeColor(String type) {
    return switch (type) {
      'rent' => const Color(0xFF6366F1),
      'utility' => const Color(0xFFF59E0B),
      'debt' => const Color(0xFFEF4444),
      _ => XonaDoshColors.emerald,
    };
  }

  Widget _buildFinanceItemCard(
    BuildContext context,
    XonadoshFinanceItem item,
    bool isDark,
  ) {
    final paidRatio = item.amountUzs > 0
        ? (item.paidAmountUzs / item.amountUzs).clamp(0.0, 1.0)
        : 0.0;
    final typeColor = _financeTypeColor(item.type);
    final unpaid = item.splits.where((s) => !s.isPaid).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showFinanceDetailSheet(context, item, isDark),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _financeTypeIcon(item.type),
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                item.isSettled
                                    ? Icons.check_circle_rounded
                                    : Icons.timelapse_rounded,
                                size: 13,
                                color: item.isSettled
                                    ? XonaDoshColors.emerald
                                    : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isSettled
                                    ? 'Yopildi'
                                    : '${unpaid.length} kishi qarzdor',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.isSettled
                                      ? XonaDoshColors.emerald
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMoney(item.amountUzs.toDouble()),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'so‘m',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: paidRatio,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                    color: item.isSettled ? XonaDoshColors.emerald : typeColor,
                  ),
                ),
                const SizedBox(height: 10),
                // One-tap avatars for each roommate share
                Row(
                  children: [
                    ...item.splits.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final markingPaid = !s.isPaid;
                            await ref
                                .read(xonadoshRepositoryProvider)
                                .toggleFinancePaid(
                                  financeId: item.id,
                                  memberName: s.name,
                                  isPaid: markingPaid,
                                );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  markingPaid
                                      ? '${s.name} to‘ladi ✓'
                                      : '${s.name} — to‘lanmagan',
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: XonaDoshColors.emeraldDark,
                              ),
                            );
                            ref.invalidate(xonadoshFinancesProvider);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: s.isPaid
                                  ? XonaDoshColors.emerald.withValues(
                                      alpha: 0.12,
                                    )
                                  : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: s.isPaid
                                    ? XonaDoshColors.emerald.withValues(
                                        alpha: 0.4,
                                      )
                                    : (isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.isPaid
                                      ? Icons.check_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: s.isPaid
                                      ? XonaDoshColors.emerald
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: s.isPaid
                                        ? XonaDoshColors.emeraldDark
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF334155)),
                                    decoration: s.isPaid
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDebtPaymentSheet(
    BuildContext context,
    XonadoshDebtBalance debt,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qarzni to‘lash va yopish',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${debt.debtor} ➔ ${debt.creditor}ga',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_formatMoney(debt.amountUzs.toDouble())} so‘m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.credit_card_rounded,
                      size: 20,
                      color: XonaDoshColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Click / Payme / Uzum orqali ${debt.creditor}ga o‘tkazishingiz mumkin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(xonadoshRepositoryProvider).addFinance({
                      'type': 'debt',
                      'title':
                          'Qarz qaytarildi: ${debt.debtor} ➔ ${debt.creditor}',
                      'amount': debt.amountUzs,
                      'paid_by': debt.debtor,
                      'group_code': ref.read(colivingGroupCodeProvider),
                    });
                    ref.invalidate(xonadoshFinancesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ ${_formatMoney(debt.amountUzs.toDouble())} so‘m qarz to‘langani qayd etildi!',
                          ),
                          backgroundColor: XonaDoshColors.emeraldDark,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'To‘ladim deb belgilash',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: XonaDoshColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFinanceDetailSheet(
    BuildContext context,
    XonadoshFinanceItem item,
    bool isDark,
  ) {
    final typeColor = _financeTypeColor(item.type);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_financeTypeIcon(item.type), color: typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_formatMoney(item.amountUzs.toDouble())} so‘m',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.dueDate.isNotEmpty || item.paidBy.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (item.paidBy.isNotEmpty)
                      _metaPill(Icons.person_rounded, item.paidBy, isDark),
                    if (item.dueDate.isNotEmpty)
                      _metaPill(Icons.event_rounded, item.dueDate, isDark),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Ulushlar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...item.splits.map((s) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _avatarInitial(
                        s.name,
                        s.isPaid
                            ? XonaDoshColors.emerald
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _formatMoney(s.amountUzs.toDouble()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: s.isPaid
                              ? Colors.grey.withValues(alpha: 0.2)
                              : XonaDoshColors.emerald,
                          foregroundColor: s.isPaid
                              ? (isDark ? Colors.white70 : Colors.black54)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 34),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          await ref
                              .read(xonadoshRepositoryProvider)
                              .toggleFinancePaid(
                                financeId: item.id,
                                memberName: s.name,
                                isPaid: !s.isPaid,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          ref.invalidate(xonadoshFinancesProvider);
                        },
                        child: Text(
                          s.isPaid ? 'Bekor' : 'To‘ladi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _metaPill(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: XonaDoshColors.emerald),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. ANONIM MASALALAR & OVOZ BERISH VIEW
  // ==========================================
  Widget _buildPollsView(BuildContext context, bool isDark) {
    final pollsAsync = ref.watch(xonadoshPollsProvider);

    return pollsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: XonaDoshColors.emerald),
      ),
      error: (err, _) =>
          Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async => ref.refresh(xonadoshPollsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Masalalar (${data.polls.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Anonim',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showCreatePollDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'Yangi masala',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 6),

              if (data.polls.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Hozircha o‘rtaga tashlangan masalalar yo‘q'),
                  ),
                )
              else
                ...data.polls.map(
                  (poll) => _buildPollCard(context, poll, isDark),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollCard(BuildContext context, XonadoshPoll poll, bool isDark) {
    final statusBadgeColor = switch (poll.status) {
      'passed' => XonaDoshColors.primaryDark,
      'rejected' => const Color(0xFFDC2626),
      _ => XonaDoshColors.primary,
    };

    final statusText = switch (poll.status) {
      'passed' => '✅ Qabul qilindi',
      'rejected' => '❌ Rad etildi',
      _ => '🗳 Ovoz berish faol',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: poll.isActive
              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusBadgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${poll.totalVotes} ta ovoz',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            poll.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          if (poll.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              poll.description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Vote percentage bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (poll.yesPercent > 0)
                    Expanded(
                      flex: poll.yesPercent,
                      child: Container(color: XonaDoshColors.primary),
                    ),
                  if (poll.noPercent > 0)
                    Expanded(
                      flex: poll.noPercent,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  if (poll.neutralPercent > 0)
                    Expanded(
                      flex: poll.neutralPercent,
                      child: Container(color: const Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.thumb_up_rounded,
                      size: 13,
                      color: XonaDoshColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${poll.votesYes} (${poll.yesPercent}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: XonaDoshColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.thumb_down_rounded,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${poll.votesNo} (${poll.noPercent}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${poll.votesNeutral}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (poll.isActive) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: XonaDoshColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      foregroundColor: XonaDoshColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: () => _submitVote(poll.id, 'yes'),
                    icon: const Icon(Icons.thumb_up_rounded, size: 13),
                    label: const Text(
                      'Rozi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFFB91C1C),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: () => _submitVote(poll.id, 'no'),
                    icon: const Icon(Icons.thumb_down_rounded, size: 13),
                    label: const Text(
                      'Qarshi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: () => _submitVote(poll.id, 'neutral'),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 13,
                    ),
                    label: const Text(
                      'Betaraf',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitVote(int pollId, String vote) async {
    final res = await ref
        .read(xonadoshRepositoryProvider)
        .votePoll(pollId: pollId, vote: vote);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Ovozingiz qabul qilindi!',
          ),
          backgroundColor: XonaDoshColors.emeraldDark,
        ),
      );
      ref.invalidate(xonadoshPollsProvider);
    }
  }

  // ==========================================
  // 6. OBRO' & KARMA BAHOLASH VIEW
  // ==========================================
  Widget _buildKarmaView(BuildContext context, bool isDark) {
    final karmaAsync = ref.watch(xonadoshKarmaProvider);

    return karmaAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: XonaDoshColors.emerald),
      ),
      error: (err, _) =>
          Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async => ref.refresh(xonadoshKarmaProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Reyting jadvali',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showGiveKarmaDialog(
                        context,
                        data.roommates,
                        data.availableBadges,
                      ),
                      icon: const Icon(Icons.star_rounded, size: 16),
                      label: const Text(
                        'Ball berish',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Leaderboard members list
              ...data.leaderboard.asMap().entries.map((entry) {
                final idx = entry.key;
                final member = entry.value;

                final medal = switch (idx) {
                  0 => '🥇',
                  1 => '🥈',
                  2 => '🥉',
                  _ => '${idx + 1}',
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: idx == 0
                          ? const Color(0xFFF59E0B)
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE8EEF3)),
                      width: idx == 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${member.badgesCount} ta nishon olingan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${member.totalPoints} ball',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (member.badgesSummary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: member.badgesSummary
                              .map(
                                (b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${b['name']} (${b['count']})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (member.recentPraises.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 6),
                        Text(
                          '💬 Oxirgi izoh: "${member.recentPraises.first.comment}" — ${member.recentPraises.first.fromName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // DIALOGS & ACTION SHEETS
  // ==========================================
  Widget _buildSummaryTile(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChoreDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final personCtrl = TextEditingController(text: 'Jasur');
    String day = 'dushanba';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.l10n.xonadoshNewDuty,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshDutyTaskName,
                  hintText: context.l10n.xonadoshDutyTaskNameHint,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: personCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshDutyPersonInCharge,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: day,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshDutyDay,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'dushanba',
                    child: Text(context.l10n.xonadoshDayMonday),
                  ),
                  DropdownMenuItem(
                    value: 'seshanba',
                    child: Text(context.l10n.xonadoshDayTuesday),
                  ),
                  DropdownMenuItem(
                    value: 'chorshanba',
                    child: Text(context.l10n.xonadoshDayWednesday),
                  ),
                  DropdownMenuItem(
                    value: 'payshanba',
                    child: Text(context.l10n.xonadoshDayThursday),
                  ),
                  DropdownMenuItem(
                    value: 'juma',
                    child: Text(context.l10n.xonadoshDayFriday),
                  ),
                  DropdownMenuItem(
                    value: 'shanba',
                    child: Text(context.l10n.xonadoshDaySaturday),
                  ),
                  DropdownMenuItem(
                    value: 'yakshanba',
                    child: Text(context.l10n.xonadoshDaySunday),
                  ),
                ],
                onChanged: (val) =>
                    setDialogState(() => day = val ?? 'dushanba'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: XonaDoshColors.emerald,
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(xonadoshRepositoryProvider).addChore({
                  'title': titleCtrl.text.trim(),
                  'assigned_name': personCtrl.text.trim().isEmpty
                      ? 'Jasur'
                      : personCtrl.text.trim(),
                  'day_of_week': day,
                  'group_code': ref.read(colivingGroupCodeProvider),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(xonadoshChoresProvider);
              },
              child: Text(context.l10n.commonAdd),
            ),
          ],
        ),
      ),
    );
  }

  void _shareFinancesReport(BuildContext context, XonadoshFinancesData data) {
    final groupCode = ref.read(colivingGroupCodeProvider);
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final buffer = StringBuffer();
    buffer.writeln('📊 XONADOSH — UMUMIY KASSA HISOBOTI');
    buffer.writeln('🏠 Xonadon kodi: $groupCode');
    buffer.writeln('📅 Sana: $dateStr');
    buffer.writeln('');
    buffer.writeln(
      '💰 JAMI XARAJATLAR: ${_formatMoney(data.totalSpendUzs.toDouble())} so‘m',
    );
    if (data.rentTotalUzs > 0) {
      buffer.writeln(
        '  • Uy ijarasi: ${_formatMoney(data.rentTotalUzs.toDouble())} so‘m',
      );
    }
    if (data.utilityTotalUzs > 0) {
      buffer.writeln(
        '  • Kommunal to‘lovlar: ${_formatMoney(data.utilityTotalUzs.toDouble())} so‘m',
      );
    }
    if (data.expenseTotalUzs > 0) {
      buffer.writeln(
        '  • Bozorlik va ro‘zg‘or: ${_formatMoney(data.expenseTotalUzs.toDouble())} so‘m',
      );
    }
    buffer.writeln('');
    if (data.debtBalances.isNotEmpty) {
      buffer.writeln('⚖️ QARZDORLIK VA HISOB-KITOBLAR:');
      for (final debt in data.debtBalances) {
        buffer.writeln(
          '  👉 ${debt.debtor} ➔ ${debt.creditor}: ${_formatMoney(debt.amountUzs.toDouble())} so‘m',
        );
      }
    } else {
      buffer.writeln('✓ Barcha hisob-kitoblar toza, qarzlar yo‘q!');
    }
    buffer.writeln('');
    buffer.writeln('📲 XonaDosh orqali kuzatib boring:');
    buffer.writeln('https://xonadoshim.uz/join/$groupCode');

    ContactActions.shareText(context, buffer.toString());
  }

  void _showAddFinanceDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'utility';
    String paidBy = 'Jasur';
    final roommates = ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];

    final presets = <String, List<({String title, String amount})>>{
      'utility': [
        (title: 'Svet', amount: '180000'),
        (title: 'Gaz', amount: '90000'),
        (title: 'Suv', amount: '60000'),
        (title: 'Wi-Fi', amount: '140000'),
      ],
      'rent': [(title: 'Oylik ijara', amount: '4000000')],
      'expense_split': [
        (title: 'Bozorlik', amount: '320000'),
        (title: 'Uy jihozlari', amount: '150000'),
      ],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Yangi to‘lov',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _typePick(
                            'utility',
                            Icons.bolt_rounded,
                            'Kommunal',
                            type,
                            (v) {
                              setDialogState(() {
                                type = v;
                                titleCtrl.clear();
                                amountCtrl.clear();
                              });
                            },
                            isDark,
                          ),
                          const SizedBox(width: 6),
                          _typePick('rent', Icons.home_rounded, 'Ijara', type, (
                            v,
                          ) {
                            setDialogState(() {
                              type = v;
                              titleCtrl.clear();
                              amountCtrl.clear();
                            });
                          }, isDark),
                          const SizedBox(width: 6),
                          _typePick(
                            'expense_split',
                            Icons.shopping_bag_rounded,
                            'Xarid',
                            type,
                            (v) {
                              setDialogState(() {
                                type = v;
                                titleCtrl.clear();
                                amountCtrl.clear();
                              });
                            },
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (presets[type] ?? []).map((p) {
                          return ActionChip(
                            label: Text(p.title),
                            onPressed: () => setDialogState(() {
                              titleCtrl.text = p.title;
                              amountCtrl.text = p.amount;
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nomi',
                          hintText: 'Masalan: Svet',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Summa',
                          hintText: '180000',
                          suffixText: 'so‘m',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kim to‘ladi?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (type == 'rent')
                            ChoiceChip(
                              label: const Text('Uy egasi'),
                              selected: paidBy == 'Uy egasiga',
                              onSelected: (_) =>
                                  setDialogState(() => paidBy = 'Uy egasiga'),
                            ),
                          ...roommates.map(
                            (r) => ChoiceChip(
                              label: Text(r),
                              selected: paidBy == r,
                              onSelected: (_) =>
                                  setDialogState(() => paidBy = r),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: XonaDoshColors.emerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final amt =
                                int.tryParse(
                                  amountCtrl.text.replaceAll(RegExp(r'\D'), ''),
                                ) ??
                                0;
                            if (titleCtrl.text.trim().isEmpty || amt <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nom va summani kiriting'),
                                ),
                              );
                              return;
                            }
                            await ref
                                .read(xonadoshRepositoryProvider)
                                .addFinance({
                                  'type': type,
                                  'title': titleCtrl.text.trim(),
                                  'amount_uzs': amt,
                                  'paid_by': paidBy,
                                  'group_code': ref.read(colivingGroupCodeProvider),
                                });
                            if (ctx.mounted) Navigator.pop(ctx);
                            ref.invalidate(xonadoshFinancesProvider);
                          },
                          child: const Text(
                            'Saqlash va taqsimlash',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _typePick(
    String value,
    IconData icon,
    String label,
    String current,
    ValueChanged<String> onTap,
    bool isDark,
  ) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? XonaDoshColors.emerald.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? XonaDoshColors.emerald : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? XonaDoshColors.emerald : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? XonaDoshColors.emeraldDark : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'rules';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Yangi masala',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategoriya'),
                  items: const [
                    DropdownMenuItem(
                      value: 'rules',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gavel_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Xonadon qoidasi'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cleaning',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cleaning_services_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Tozalik va tartib'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'shopping',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Xaridlar va byudjet'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'guests',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Mehmonlar tartibi'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'general',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Umumiy taklif'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => category = val ?? 'rules'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Masala / Taklif sarlavhasi',
                    hintText:
                        'e.g. 23:00 dan keyin oshxonada shovqin qilmaslik',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Batafsil tushuntirish',
                    hintText: 'Nega bu masala muhimligini yozing...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(xonadoshRepositoryProvider).createPoll({
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'category': category,
                  'group_code': ref.read(colivingGroupCodeProvider),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(xonadoshPollsProvider);
              },
              child: const Text('Yuborish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiveKarmaDialog(
    BuildContext context,
    List<String> roommates,
    List<XonadoshKarmaBadge> badges,
  ) {
    String selectedRoommate = roommates.isNotEmpty
        ? roommates.first
        : 'Azizbek';
    String selectedBadgeKey = badges.isNotEmpty
        ? badges.first.key
        : 'cleanliness_master';
    String selectedBadgeName = badges.isNotEmpty
        ? badges.first.name
        : 'Tozalik ustasi';
    final commentCtrl = TextEditingController();
    int points = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Minnatdorchilik bildirish',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRoommate,
                  decoration: const InputDecoration(
                    labelText: 'Kimga obro‘ berasiz?',
                  ),
                  items:
                      (roommates.isEmpty
                              ? ['Jasur', 'Azizbek', 'Bekzod', 'Sardor']
                              : roommates)
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedRoommate = val ?? 'Azizbek'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedBadgeKey,
                  decoration: const InputDecoration(
                    labelText: 'Qanday nishon berasiz?',
                  ),
                  items:
                      (badges.isEmpty
                              ? [
                                  const XonadoshKarmaBadge(
                                    key: 'cleanliness_master',
                                    name: 'Tozalik ustasi',
                                    icon: '🧹',
                                    description: '',
                                  ),
                                  const XonadoshKarmaBadge(
                                    key: 'chef_pro',
                                    name: 'Mohir oshpaz',
                                    icon: '👨‍🍳',
                                    description: '',
                                  ),
                                  const XonadoshKarmaBadge(
                                    key: 'ontime_payer',
                                    name: 'Vaqtida to‘lovchi',
                                    icon: '⏱',
                                    description: '',
                                  ),
                                ]
                              : badges)
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.key,
                              child: Text('${b.icon} ${b.name}'),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    final found = badges.firstWhere(
                      (b) => b.key == val,
                      orElse: () => badges.first,
                    );
                    setDialogState(() {
                      selectedBadgeKey = val ?? 'cleanliness_master';
                      selectedBadgeName = found.name;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Ball miqdori:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...[1, 2, 3, 5].map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('+$p'),
                          selected: points == p,
                          onSelected: (val) => setDialogState(() => points = p),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Minnatdorchilik / Izoh',
                    hintText: 'Nima uchun minnatdorsiz?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              onPressed: () async {
                await ref.read(xonadoshRepositoryProvider).giveKarma({
                  'from_name': 'Xonadosh',
                  'to_name': selectedRoommate,
                  'badge_key': selectedBadgeKey,
                  'badge_name': selectedBadgeName,
                  'points': points,
                  'comment': commentCtrl.text.trim(),
                  'group_code': ref.read(colivingGroupCodeProvider),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(xonadoshKarmaProvider);
              },
              child: const Text('Yuborish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipePickerSheet(
    BuildContext context,
    String day,
    String mealTime,
    String currentRecipeName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => XonadoshRecipePickerSheet(
        dayOfWeek: day,
        mealTime: mealTime,
        currentRecipeName: currentRecipeName,
      ),
    );
  }

  void _showCreateRecipeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const XonadoshCreateRecipeSheet(),
    );
  }

  String _formatMoney(double amount) {
    final s = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  // ── Xonadon Boshqaruvi va Taklif Havolasi (Squad / House Invite) ──
  void _openHouseManagementModal(BuildContext context, bool isDark) {
    final joinCodeController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final groupCode = ref.watch(colivingGroupCodeProvider);
            final isDefault = groupCode == 'home_default';
            final shareUrl = 'https://xonadoshim.uz/join/$groupCode';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: XonaDoshColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.home_work_rounded,
                                color: XonaDoshColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Xonadon Boshqaruvi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    isDefault
                                        ? 'Namunaviy umumiy uy rejimi'
                                        : 'Faol jamoa: $groupCode',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Active House Code Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF0D9488).withValues(alpha: 0.3)
                                  : const Color(0xFF99F6E4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'XONADON TAKLIF KODI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: XonaDoshColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                groupCode,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  fontFamily: 'monospace',
                                  color: XonaDoshColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: groupCode),
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✓ Uy kodi nusxalandi!'),
                                              backgroundColor: Color(0xFF059669),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.copy_rounded, size: 16),
                                      label: const Text(
                                        'Kodni olish',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        ContactActions.shareText(
                                          context,
                                          'Salom! XonaDosh ilovasida bizning umumiy xonadonga qo‘shiling:\n$shareUrl\n\nYoki ilovada Uy kodi: $groupCode',
                                        );
                                      },
                                      icon: const Icon(Icons.share_rounded, size: 16),
                                      label: const Text(
                                        'Ulashish',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: XonaDoshColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () => _showQrCodeDialog(
                                      context,
                                      groupCode,
                                      shareUrl,
                                      isDark,
                                    ),
                                    icon: const Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 20,
                                    ),
                                    tooltip: 'QR Kod',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Join Other House
                        Text(
                          'Boshqa xonadonga ulanish',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: joinCodeController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Masalan: HOME-402 yoki chilonzor',
                                  isDense: true,
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                final text = joinCodeController.text.trim();
                                if (text.isEmpty) return;
                                await ref
                                    .read(colivingGroupCodeProvider.notifier)
                                    .setGroupCode(text);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "✓ '$text' xonadoniga muvaffaqiyatli ulandingiz!",
                                      ),
                                      backgroundColor: const Color(0xFF059669),
                                    ),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: XonaDoshColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Ulanish',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Create New House or Reset
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final randomCode =
                                      'UY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                                  await ref
                                      .read(colivingGroupCodeProvider.notifier)
                                      .setGroupCode(randomCode);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "✓ Yangi xonadon yaratildi: $randomCode",
                                        ),
                                        backgroundColor: const Color(0xFF059669),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add_home_rounded, size: 16),
                                label: const Text(
                                  'Yangi xonadon ochish',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            if (!isDefault) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(colivingGroupCodeProvider.notifier)
                                      .setGroupCode('home_default');
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text(
                                  'Namunaga qaytish',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQrCodeDialog(
    BuildContext context,
    String code,
    String url,
    bool isDark,
  ) {
    final qrApiUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(url)}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xonadon QR Kodi',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xonadoshlaringiz kamerani shu QR kodga qaratsa, avtomatik xonadonga ulanadi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Image.network(
                qrApiUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Icon(
                      Icons.qr_code_rounded,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kod: $code',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                fontSize: 16,
                color: XonaDoshColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Yopish',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Uy Qoidalari (House Rules) Modali ──
  void _openHouseRulesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final rulesAsync = ref.watch(xonadoshHouseRulesProvider);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: XonaDoshColors.accentPurple.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.rule_rounded,
                                  color: XonaDoshColors.accentPurple,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Uy Qoidalari',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Xonadon ichki kelishuvlari',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: rulesAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: XonaDoshColors.emerald,
                          ),
                        ),
                        error: (err, _) =>
                            Center(child: Text('Qoidalar yuklanmadi: $err')),
                        data: (rules) {
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildHouseRulesPinnedCard(context, isDark),
                              const SizedBox(height: 12),
                              ...rules.map((rule) {
                                final color = _ruleCategoryColor(rule.category);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: rule.isActive
                                          ? color.withValues(
                                              alpha: isDark ? 0.35 : 0.2,
                                            )
                                          : (isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0)),
                                      width: rule.isActive ? 1.4 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(
                                            alpha: isDark ? 0.25 : 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          _ruleCategoryIcon(rule.category),
                                          size: 18,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    rule.title,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color: rule.isActive
                                                          ? null
                                                          : Colors.grey,
                                                      decoration: rule.isActive
                                                          ? null
                                                          : TextDecoration
                                                                .lineThrough,
                                                    ),
                                                  ),
                                                ),
                                                if (rule.isCustom)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      size: 18,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () async {
                                                      await ref
                                                          .read(
                                                            xonadoshRepositoryProvider,
                                                          )
                                                          .deleteHouseRule(
                                                            rule.id,
                                                          );
                                                      ref.invalidate(
                                                        xonadoshHouseRulesProvider,
                                                      );
                                                    },
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              rule.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch.adaptive(
                                        value: rule.isActive,
                                        activeTrackColor: color,
                                        activeThumbColor: Colors.white,
                                        onChanged: (val) async {
                                          await ref
                                              .read(xonadoshRepositoryProvider)
                                              .toggleHouseRule(rule.id, val);
                                          ref.invalidate(
                                            xonadoshHouseRulesProvider,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showAddHouseRuleDialog(context),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Yangi qoida qo‘shish'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    tooltip: 'Standart qoidalarga qaytarish',
                                    onPressed: () async {
                                      await ref
                                          .read(xonadoshRepositoryProvider)
                                          .resetHouseRules();
                                      ref.invalidate(
                                        xonadoshHouseRulesProvider,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.restart_alt_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _ruleCategoryColor(String category) {
    switch (category) {
      case 'quiet_hours':
        return const Color(0xFF6366F1);
      case 'guests':
        return const Color(0xFF0284C7);
      case 'cleanliness':
        return const Color(0xFF10B981);
      case 'smoking':
        return const Color(0xFFEF4444);
      case 'finances':
        return const Color(0xFFF59E0B);
      case 'safety':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _ruleCategoryIcon(String category) {
    switch (category) {
      case 'quiet_hours':
        return Icons.bedtime_rounded;
      case 'guests':
        return Icons.groups_rounded;
      case 'cleanliness':
        return Icons.cleaning_services_rounded;
      case 'smoking':
        return Icons.smoke_free_rounded;
      case 'finances':
        return Icons.receipt_long_rounded;
      case 'safety':
        return Icons.security_rounded;
      default:
        return Icons.rule_rounded;
    }
  }

  void _showAddHouseRuleDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'cleanliness';

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (dlgCtx, setDlgState) {
            return AlertDialog(
              title: const Text(
                'Yangi qoida',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Qoida nomi',
                        hintText: 'Masalan: Oshxonani yig‘ishtirish',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Tavsif / Kelishuv matni',
                        hintText: 'Har kim ovqatlanib bo‘lgach...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Kategoriya',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cleanliness',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cleaning_services_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Tozalik'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'quiet_hours',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bedtime_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Tinchlik soatlari'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'guests',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Mehmonlar tartibi'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'smoking',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.smoke_free_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Zararli odatlar'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'finances',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('To‘lovlar'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'safety',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Xavfsizlik'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => category = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Bekor qilish'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: XonaDoshColors.accentPurple,
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final newRule = XonadoshHouseRule(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      category: category,
                      icon: category,
                      isActive: true,
                      isCustom: true,
                    );
                    await ref
                        .read(xonadoshRepositoryProvider)
                        .addHouseRule(newRule);
                    if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                    ref.invalidate(xonadoshHouseRulesProvider);
                  },
                  child: const Text('Qo‘shish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Telegram hisoboti generatori va ulashish ──
  String _generateTelegramExpenseReport(XonadoshFinancesData data) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final buffer = StringBuffer();
    buffer.writeln('🏠 *XONADOSH — XONADON HISOB-KITOBLARI*');
    buffer.writeln('📅 *Sana:* $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '💰 *Jami xarajat:* ${_formatMoney(data.totalSpendUzs.toDouble())} UZS',
    );
    buffer.writeln(
      '⚠️ *To‘lanmagan qarz:* ${_formatMoney(data.totalPendingUzs.toDouble())} UZS',
    );

    if (data.rentTotalUzs > 0) {
      buffer.writeln(
        '🏢 *Ijara to‘lovi:* ${_formatMoney(data.rentTotalUzs.toDouble())} UZS',
      );
    }
    if (data.utilityTotalUzs > 0) {
      buffer.writeln(
        '💡 *Kommunal:* ${_formatMoney(data.utilityTotalUzs.toDouble())} UZS',
      );
    }
    if (data.expenseTotalUzs > 0) {
      buffer.writeln(
        '🛒 *Boshqa xaridlar:* ${_formatMoney(data.expenseTotalUzs.toDouble())} UZS',
      );
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 *TO‘LOV VA QARZ TAQSIMOTI:*');

    final allItems = [
      ...data.rentItems,
      ...data.utilityItems,
      ...data.expenseItems,
    ];

    for (final item in allItems) {
      final mark = item.isSettled ? '✅' : '⏳';
      buffer.writeln(
        '$mark *${item.title}*: ${_formatMoney(item.amountUzs.toDouble())} UZS (To‘lovchi: ${item.paidBy})',
      );
      for (final s in item.splits) {
        final st = s.isPaid ? 'to‘landi' : 'QARZ';
        buffer.writeln(
          '   • ${s.name}: ${_formatMoney(s.amountUzs.toDouble())} UZS ($st)',
        );
      }
    }

    if (data.debtBalances.isNotEmpty) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🤝 *XONADOSHLAR O‘ZARO BALANSI:*');
      for (final d in data.debtBalances) {
        buffer.writeln(
          '👉 *${d.debtor}* ➔ *${d.creditor}*ga: ${_formatMoney(d.amountUzs.toDouble())} UZS',
        );
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📲 _XonaDosh Coliving Hub orqali yaratildi_');
    return buffer.toString();
  }

  Future<void> _shareTelegramReport(
    BuildContext context,
    XonadoshFinancesData data,
  ) async {
    final text = _generateTelegramExpenseReport(data);
    await ContactActions.shareText(context, text);
  }

  // ── Tezkor Kommunal & Ijara Taqsimlash Dialogi ──
  void _showQuickSplitDialog(BuildContext context) {
    int roommateCount = 4;
    final roommates = [
      'Jasur',
      'Azizbek',
      'Bekzod',
      'Sardor',
      'Diyor',
      'Nodir',
      'Otabek',
      'Shaxboz',
    ];

    final utilities = <Map<String, dynamic>>[
      {
        'id': 'rent',
        'title': 'Uy ijarasi',
        'amount': 3600000,
        'type': 'rent',
        'selected': true,
      },
      {
        'id': 'electricity',
        'title': 'Elektr energiyasi (Svet)',
        'amount': 180000,
        'type': 'utility',
        'selected': true,
      },
      {
        'id': 'gas',
        'title': 'Gaz to‘lovi',
        'amount': 90000,
        'type': 'utility',
        'selected': true,
      },
      {
        'id': 'water',
        'title': 'Sovuq va issiq suv',
        'amount': 70000,
        'type': 'utility',
        'selected': true,
      },
      {
        'id': 'wifi',
        'title': 'Wi-Fi internet',
        'amount': 150000,
        'type': 'utility',
        'selected': true,
      },
      {
        'id': 'trash',
        'title': 'Axlat puli',
        'amount': 30000,
        'type': 'utility',
        'selected': true,
      },
      {
        'id': 'supplies',
        'title': 'Xo‘jalik mollari',
        'amount': 100000,
        'type': 'expense_split',
        'selected': false,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSplitState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            int totalSelected = 0;
            for (final u in utilities) {
              if (u['selected'] == true) {
                totalSelected += (u['amount'] as int);
              }
            }
            final perPerson = (totalSelected / roommateCount).round();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kommunal & Ijara Taqsimlash',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Xonadoshlar bo‘yicha teng taqsimot',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          // Roommates count selector
                          Row(
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                size: 18,
                                color: XonaDoshColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Xonadoshlar soni: $roommateCount kishi',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [2, 3, 4, 5, 6, 7, 8].map((n) {
                                final isSel = roommateCount == n;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text('$n kishi'),
                                    selected: isSel,
                                    onSelected: (_) =>
                                        setSplitState(() => roommateCount = n),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '⚡ Xarajat turlari:',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...utilities.map((item) {
                            final selected = item['selected'] == true;
                            final amount = item['amount'] as int;
                            final itemPerPerson = (amount / roommateCount)
                                .round();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? XonaDoshColors.emerald.withValues(
                                          alpha: 0.4,
                                        )
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: CheckboxListTile(
                                value: selected,
                                activeColor: XonaDoshColors.emerald,
                                dense: true,
                                title: Text(
                                  item['title'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  'Jami: ${_formatMoney(amount.toDouble())} UZS · Kishi boshiga: ${_formatMoney(itemPerPerson.toDouble())} UZS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                secondary: Icon(
                                  item['type'] == 'rent'
                                      ? Icons.home_rounded
                                      : Icons.bolt_rounded,
                                  color: item['type'] == 'rent'
                                      ? XonaDoshColors.accentPurple
                                      : const Color(0xFF0284C7),
                                  size: 20,
                                ),
                                onChanged: (val) {
                                  setSplitState(() {
                                    item['selected'] = val ?? false;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Summary Banner + CTA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kishi boshiga to‘lov:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_formatMoney(perPerson.toDouble())} UZS',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: XonaDoshColors.emeraldDark,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Jami summa:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_formatMoney(totalSelected.toDouble())} UZS',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: XonaDoshColors.emerald,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final selectedRoommates = roommates
                                    .take(roommateCount)
                                    .toList();

                                for (final item in utilities) {
                                  if (item['selected'] != true) continue;
                                  final amount = item['amount'] as int;
                                  final splitAmt = (amount / roommateCount)
                                      .round();
                                  final splits = selectedRoommates
                                      .map(
                                        (r) => {
                                          'name': r,
                                          'amount': splitAmt,
                                          'is_paid': false,
                                        },
                                      )
                                      .toList();

                                  await ref
                                      .read(xonadoshRepositoryProvider)
                                      .addFinance({
                                        'title': item['title'],
                                        'type': item['type'],
                                        'amount': amount,
                                        'paid_by': 'Umumiy hisob',
                                        'roommates': selectedRoommates,
                                        'splits': splits,
                                        'group_code':
                                            ref.read(colivingGroupCodeProvider),
                                      });
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                ref.invalidate(xonadoshFinancesProvider);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Xarajatlar muvaffaqiyatli xonadoshlar o‘rtasida taqsimlandi!',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Xonadon hisobiga yozish',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 1. SMART UTILITY METER CALCULATOR (ELEKTR, GAZ, SUV)
  // =========================================================================
  void _openUtilityMeterModal(BuildContext context, bool isDark) {
    final elecPrevCtrl = TextEditingController(text: '1200');
    final elecCurrCtrl = TextEditingController(text: '1450');
    final gasPrevCtrl = TextEditingController(text: '500');
    final gasCurrCtrl = TextEditingController(text: '580');
    final waterPrevCtrl = TextEditingController(text: '40');
    final waterCurrCtrl = TextEditingController(text: '52');
    final wifiCtrl = TextEditingController(text: '150000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final elecConsumption = (double.tryParse(elecCurrCtrl.text) ?? 0) -
                (double.tryParse(elecPrevCtrl.text) ?? 0);
            final elecCost = elecConsumption <= 200
                ? (elecConsumption * 450).round()
                : (200 * 450 + (elecConsumption - 200) * 900).round();

            final gasConsumption = (double.tryParse(gasCurrCtrl.text) ?? 0) -
                (double.tryParse(gasPrevCtrl.text) ?? 0);
            final gasCost = gasConsumption <= 500
                ? (gasConsumption * 650).round()
                : (500 * 650 + (gasConsumption - 500) * 1500).round();

            final waterConsumption = (double.tryParse(waterCurrCtrl.text) ?? 0) -
                (double.tryParse(waterPrevCtrl.text) ?? 0);
            final waterCost = (waterConsumption * 2400).round();

            const wasteCost = 20000; // 4 kishi x 5000 so'm
            final wifiCost = int.tryParse(wifiCtrl.text) ?? 150000;
            final grandTotal = (elecCost > 0 ? elecCost : 0) +
                (gasCost > 0 ? gasCost : 0) +
                (waterCost > 0 ? waterCost : 0) +
                wasteCost +
                wifiCost;
            final perPerson = (grandTotal / 4).round();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.electric_bolt_rounded,
                                color: Color(0xFFF59E0B), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kommunal Hisoblagichlar',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '2026-yil O‘zbekiston rasmiy tariflari asosida',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildMeterInputSection(
                            title: '⚡️ Elektr energiyasi (kVt/soat)',
                            prevCtrl: elecPrevCtrl,
                            currCtrl: elecCurrCtrl,
                            consumption: elecConsumption,
                            cost: elecCost,
                            unit: 'kVt',
                            isDark: isDark,
                            onChanged: () => setModalState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildMeterInputSection(
                            title: '🔥 Tabiiy gaz (m³)',
                            prevCtrl: gasPrevCtrl,
                            currCtrl: gasCurrCtrl,
                            consumption: gasConsumption,
                            cost: gasCost,
                            unit: 'm³',
                            isDark: isDark,
                            onChanged: () => setModalState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildMeterInputSection(
                            title: '💧 Sovuq suv va kanalizatsiya (m³)',
                            prevCtrl: waterPrevCtrl,
                            currCtrl: waterCurrCtrl,
                            consumption: waterConsumption,
                            cost: waterCost,
                            unit: 'm³',
                            isDark: isDark,
                            onChanged: () => setModalState(() {}),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_rounded, color: Color(0xFF3B82F6), size: 24),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('Wi-Fi va internet oylik to‘lovi:',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    controller: wifiCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setModalState(() {}),
                                    textAlign: TextAlign.end,
                                    decoration: const InputDecoration(
                                      suffixText: ' so‘m',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Jami hisoblangan summa:',
                                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    Text(
                                      '${_formatMoneySimple(grandTotal)} so‘m',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white24, height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Har bir xonadoshga (4 kishi):',
                                        style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    Text(
                                      '${_formatMoneySimple(perPerson)} so‘m',
                                      style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.share_rounded, size: 18),
                                  label: const Text('Telegram'),
                                  onPressed: () async {
                                    final text = '📊 KOMMUNAL HISOB-KITOB:\n'
                                        '⚡️ Elektr: ${_formatMoneySimple(elecCost)} so‘m\n'
                                        '🔥 Gaz: ${_formatMoneySimple(gasCost)} so‘m\n'
                                        '💧 Suv: ${_formatMoneySimple(waterCost)} so‘m\n'
                                        '📶 Wi-Fi: ${_formatMoneySimple(wifiCost)} so‘m\n'
                                        '💰 JAMI: ${_formatMoneySimple(grandTotal)} so‘m\n'
                                        '👉 Har birimizga: ${_formatMoneySimple(perPerson)} so‘m\n\n'
                                        'XonaDosh 📱 xonadoshim.uz';
                                    final uri = Uri.parse(
                                        'https://t.me/share/url?text=${Uri.encodeComponent(text)}');
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                                  label: const Text('Kassaga yozish'),
                                  onPressed: () async {
                                    final groupCode =
                                        ref.read(colivingGroupCodeProvider);
                                    await ref
                                        .read(xonadoshRepositoryProvider)
                                        .addFinance({
                                      'title': 'Kommunal to‘lovlar (Svet, Gaz, Suv)',
                                      'type': 'utility',
                                      'amount': grandTotal,
                                      'paid_by': 'Umumiy hisob',
                                      'group_code': groupCode,
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    ref.invalidate(xonadoshFinancesProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Kommunal to‘lov muvaffaqiyatli umumiy kassaga qo‘shildi!'),
                                        ),
                                      );
                                    }
                                  },
                                ),
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
          },
        );
      },
    );
  }

  Widget _buildMeterInputSection({
    required String title,
    required TextEditingController prevCtrl,
    required TextEditingController currCtrl,
    required double consumption,
    required int cost,
    required String unit,
    required bool isDark,
    required VoidCallback onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(
                '${_formatMoneySimple(cost)} so‘m',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: prevCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Oldingi',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: currCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Joriy',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${consumption > 0 ? consumption.toStringAsFixed(1) : "0"} $unit',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. OPT-OUT MEAL ("BUGUN UYDA OVQATLANMAYMAN")
  // =========================================================================
  void _openOptOutMealModal(BuildContext context, bool isDark) {
    String selectedReason = 'Dars / Imtihondaman';
    final reasons = [
      'Dars / Imtihondaman',
      'Qishloqdaman / Safardaman',
      'Ishda / Mehmondaman',
      'Ro‘zadaman'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.no_meals_rounded,
                              color: Color(0xFFEF4444), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Bugun uyda ovqatlanmayman',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Darsda, ishda yoki safardamisiz? 1 ta tugma bilan bugungi umumiy oziq-ovqat va bozorlik xarajatidan ozod bo‘ling.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sababni tanlang:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: reasons.map((r) {
                        final isSel = selectedReason == r;
                        return ChoiceChip(
                          label: Text(r),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => selectedReason = r),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(
                                  'Qayd etildi ($selectedReason)! Bugungi taom xarajatidan ozod qilindingiz.'),
                            ),
                          );
                        },
                        child: const Text('Qayd etish (Xarajatdan chiqish)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 3. CHORE SWAP ("BUGUN DARSIM KO'P, NAVBATNI ALMASHTIRAYLIK")
  // =========================================================================
  void _openChoreSwapModal(BuildContext context, bool isDark) {
    String selectedReason = 'Bugun kollokvium / darsim ko‘p';
    final reasons = [
      'Bugun kollokvium / darsim ko‘p',
      'Kasal bo‘lib qoldim',
      'Kech qaytaman / Ishdaman'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: Color(0xFF8B5CF6), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Navbatchilikni almashtirish',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bugun navbatingiz bormi, lekin vaqtingiz yo‘qmi? Xonadoshlaringizga navbatni keyingi kunga o‘zaro almashtirish taklifini yuboring.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sabab:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: reasons.map((r) {
                        final isSel = selectedReason == r;
                        return ChoiceChip(
                          label: Text(r),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => selectedReason = r),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF8B5CF6),
                              content: Text(
                                  'Almashtirish so‘rovi xonadoshlarga yuborildi! Kimdir qabul qilsa sizga bildirishnoma keladi.'),
                            ),
                          );
                        },
                        child: const Text('Xonadoshlarga so‘rov yuborish',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 4. 50% STUDENT SUBSIDY & LEGAL LEASE ADVISORY (IJARA.SOLIQ.UZ)
  // =========================================================================
  void _openStudentSubsidyModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: Color(0xFF0EA5E9), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('50% Davlat Kompensatsiyasi',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('VM 605-son qarori bo‘yicha qo‘llanma',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Talaba uchun 375 000 so‘mgacha bepul yordam!',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0EA5E9),
                                  fontSize: 14),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Davlat OTM kunduzgi talabalariga har oy Toshkentda 375 000 so‘mgacha (BHM 1 baravari), viloyatlarda 187 500 so‘mgacha ijara xarajatlari davlat byudjetidan qoplab beriladi.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Kompensatsiyani olishning 3 ta oson qadami:',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 12),
                      _buildSubsidyStep(
                        step: '1',
                        title: 'ijara.soliq.uz da shartnoma tuzish',
                        desc:
                            'Uy egasi bilan OneID orqali kiring. Talabalarga ijaraga berilganda uy egasi 100% daromad solig‘idan ozod etiladi!',
                      ),
                      const SizedBox(height: 12),
                      _buildSubsidyStep(
                        step: '2',
                        title: 'Dekanat / Tyutorga ariza topshirish',
                        desc:
                            'OTM rektori nomiga ariza va soliqdan olingan QR-kodli ijara shartnomasini taqdim eting.',
                      ),
                      const SizedBox(height: 12),
                      _buildSubsidyStep(
                        step: '3',
                        title: 'Bank kartasiga qabul qilish',
                        desc:
                            'Har oyning 10-sanasiga qadar mablag‘ to‘g‘ridan-to‘g‘ri plastik kartangizga o‘tkazib beriladi.',
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('ijara.soliq.uz portaliga o‘tish',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        onPressed: () async {
                          final uri = Uri.parse('https://ijara.soliq.uz/');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Namunaviy shartnoma matnini nusxalash'),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                            text: 'TURAR JOYNI IJARAGA BERISH SHARTNOMASI (NAMUNA)\n\n'
                                '1. Shartnoma mavzusi: Ijaraga beruvchi o‘ziga tegishli xonadonni Ijarachiga vaqtincha yashash uchun topshiradi.\n'
                                '2. To‘lov miqdori va tartibi: Har oyning 5-sanasiga qadar to‘lanadi.\n'
                                '3. Tomonlarning huquq va majburiyatlari: Fuqarolik Kodeksi 603-614 moddalari bo‘yicha.\n\n'
                                'ijara.soliq.uz orqali ro‘yxatdan o‘tish tavsiya etiladi.',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Namunaviy shartnoma matni buferga nusxalandi!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubsidyStep({
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF0EA5E9),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMoneySimple(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

