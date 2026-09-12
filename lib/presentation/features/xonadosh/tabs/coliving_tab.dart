import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import '../widgets/xonadosh_create_recipe_sheet.dart';
import '../widgets/xonadosh_recipe_picker_sheet.dart';

class XonadoshColivingTab extends ConsumerStatefulWidget {
  const XonadoshColivingTab({super.key});

  @override
  ConsumerState<XonadoshColivingTab> createState() => _XonadoshColivingTabState();
}

class _XonadoshColivingTabState extends ConsumerState<XonadoshColivingTab> {
  // 0: Navbatchilik, 1: Taomnoma, 2: Bozorlik, 3: Moliya, 4: Masalalar, 5: Obro'/Karma
  int _activeSubTab = 0;
  /// Moliya filtri: all | due | rent | utility | expense
  String _financeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      body: Column(
        children: [
          // Horizontal sub-tab bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            color: theme.scaffoldBackgroundColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildSubTabPill(0, Icons.assignment_turned_in_rounded, l10n.xonadoshDutyRosterTab, isDark),
                  const SizedBox(width: 6),
                  _buildSubTabPill(1, Icons.restaurant_menu_rounded, l10n.xonadoshMenuTab, isDark),
                  const SizedBox(width: 6),
                  _buildSubTabPill(2, Icons.shopping_cart_rounded, l10n.xonadoshGroceryTab, isDark),
                  const SizedBox(width: 6),
                  _buildSubTabPill(3, Icons.account_balance_wallet_rounded, 'Moliya', isDark),
                  const SizedBox(width: 6),
                  _buildSubTabPill(4, Icons.how_to_vote_rounded, 'Ovoz berish', isDark),
                  const SizedBox(width: 6),
                  _buildSubTabPill(5, Icons.military_tech_rounded, 'Reyting', isDark),
                ],
              ),
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (_activeSubTab) {
                0 => _buildDutyRosterView(context, isDark),
                1 => _buildMealPlanView(context, isDark),
                2 => _buildGroceryView(context, isDark),
                3 => _buildFinancesView(context, isDark),
                4 => _buildPollsView(context, isDark),
                5 => _buildKarmaView(context, isDark),
                _ => _buildDutyRosterView(context, isDark),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabPill(int index, IconData icon, String label, bool isDark) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeSubTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F766E) : const Color(0xFF0D9488))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
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
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. NAVBATCHILIK (DUTY ROSTER) VIEW
  // ==========================================
  String _getLocalizedDayName(String day, dynamic l10n) {
    switch (day.toLowerCase()) {
      case 'dushanba': return l10n.xonadoshDayMonday;
      case 'seshanba': return l10n.xonadoshDayTuesday;
      case 'chorshanba': return l10n.xonadoshDayWednesday;
      case 'payshanba': return l10n.xonadoshDayThursday;
      case 'juma': return l10n.xonadoshDayFriday;
      case 'shanba': return l10n.xonadoshDaySaturday;
      case 'yakshanba': return l10n.xonadoshDaySunday;
      default: return day;
    }
  }

  Widget _buildDutyRosterView(BuildContext context, bool isDark) {
    final choresAsync = ref.watch(xonadoshChoresProvider);

    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: XonaDoshColors.emerald)),
      error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        final todayDuties = data.todayDuties;
        final allChores = data.allChores;

        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async => ref.refresh(xonadoshChoresProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Today Duty Banner Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.today_rounded, color: XonaDoshColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${context.l10n.xonadoshToday} (${_getLocalizedDayName(data.todayDay, context.l10n)})',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: XonaDoshColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${todayDuties.where((c) => c.isCompleted).length}/${todayDuties.length}',
                            style: const TextStyle(
                              color: XonaDoshColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (todayDuties.isEmpty)
                      Text(
                        context.l10n.xonadoshNoDutyToday,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      )
                    else
                      ...todayDuties.map((chore) => _buildChoreItem(chore, isDark, isToday: true)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Weekly Schedule Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.xonadoshDutySchedule,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _showAddChoreDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Group chores by day
              ...['dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'].map((day) {
                final dayChores = allChores.where((c) => c.dayOfWeek == day).toList();
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
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
                          width: isToday ? 1.5 : 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: isToday,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          leading: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: isToday ? XonaDoshColors.emerald : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          title: Text(
                            _getLocalizedDayName(day, context.l10n),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isToday ? XonaDoshColors.emerald : null,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${dayChores.length} ta vazifa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ),
                          children: [
                            if (dayChores.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Bu kunga vazifalar biriktirilmagan',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                child: Column(
                                  children: dayChores.map((c) => _buildChoreItem(c, isDark)).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoreItem(XonadoshChore chore, bool isDark, {bool isToday = false}) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: chore.isCompleted,
            activeColor: XonaDoshColors.emerald,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            visualDensity: VisualDensity.compact,
            onChanged: (val) async {
              await ref.read(xonadoshRepositoryProvider).toggleChoreDone(
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
                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                        : null,
                    decoration: chore.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (chore.notes.isNotEmpty)
                  Text(
                    chore.notes,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              chore.assignedName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. TAOMNOMA (MEAL PLAN) VIEW
  // ==========================================
  Widget _buildMealPlanView(BuildContext context, bool isDark) {
    final mealPlanAsync = ref.watch(xonadoshRecipesAndMealPlanProvider);

    return mealPlanAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: XonaDoshColors.emerald)),
      error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (data) {
        final Map<String, List<XonadoshMealPlan>> grouped = {};
        for (final m in data.mealPlans) {
          grouped.putIfAbsent(m.dayOfWeek, () => []).add(m);
        }

        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async => ref.refresh(xonadoshRecipesAndMealPlanProvider),
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
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showCreateRecipeSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(context.l10n.xonadoshAddNewRecipe, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              ...['dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'].map((day) {
                final meals = grouped[day] ?? [];
                return _buildDayAccordionCard(context, day, meals, isDark);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayAccordionCard(BuildContext context, String day, List<XonadoshMealPlan> meals, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: day == 'dushanba',
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              leading: const Icon(Icons.restaurant_menu_rounded, size: 18, color: XonaDoshColors.emerald),
              title: Text(
                _getLocalizedDayName(day, context.l10n),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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

                      final mealIcon = switch (mealTime) {
                        'breakfast' => '🌅',
                        'lunch' => '🌤',
                        _ => '🌙',
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
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(mealIcon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mealLabel,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
                                  ),
                                  Text(
                                    plan.recipeName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'Oshpaz: ${plan.cookName} • ${plan.prepSchedule}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, size: 20, color: XonaDoshColors.emerald),
                              onPressed: () => _showRecipePickerSheet(context, day, mealTime, plan.recipeName),
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
      loading: () => const Center(child: CircularProgressIndicator(color: XonaDoshColors.emerald)),
      error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
      data: (calc) {
        if (calc == null) return Center(child: Text(context.l10n.xonadoshCalcFailed));

        final bread = calc.breadBreakdown;

        return RefreshIndicator(
          color: XonaDoshColors.emerald,
          onRefresh: () async => ref.refresh(xonadoshGroceryCalculationProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // 1. Roommates Count Stepper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_rounded, color: XonaDoshColors.emerald),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.xonadoshRoommatesCountLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: roommateCount > 1
                          ? () {
                              ref.read(xonadoshRoommateCountProvider.notifier).state--;
                              ref.invalidate(xonadoshGroceryCalculationProvider);
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        context.l10n.xonadoshPeopleCount(roommateCount),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: roommateCount < 10
                          ? () {
                              ref.read(xonadoshRoommateCountProvider.notifier).state++;
                              ref.invalidate(xonadoshGroceryCalculationProvider);
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
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${context.l10n.xonadosh21Meals7Days} ($roommateCount kishi)',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_formatMoney(calc.totalCostUzs.toDouble())} so‘m',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 1),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: XonaDoshColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '📍 ${calc.cheapestMarket}',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
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

              const SizedBox(height: 12),

              // 3. Bread Breakdown Card
              if (bread.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bakery_dining_rounded, size: 18, color: Color(0xFFD97706)),
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
                        '🍞 Qolipli buxanka (ertalab/kunduzi): ${bread['total_buxanka'] ?? bread['breakfast_lunch_buxanka'] ?? 0} dona',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : const Color(0xFF451A03),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🫓 Tandir patir / Obi non (kechki ovqat): ${bread['total_patir'] ?? bread['dinner_patir'] ?? 0} dona',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : const Color(0xFF451A03),
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
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
                      calc.items.every((it) => it.isBought) ? context.l10n.commonClear : context.l10n.xonadoshAllBought,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 5. Expandable Item Cards
              ...calc.items.map((it) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        leading: Checkbox(
                          value: it.isBought,
                          activeColor: XonaDoshColors.emerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => it.isBought = val ?? false),
                        ),
                        title: Text(
                          it.nameUz,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            decoration: it.isBought ? TextDecoration.lineThrough : null,
                            color: it.isBought ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          '${it.quantity} ${it.unit}  •  ~${_formatMoney(it.unitPriceUzs)} so‘m/${it.unit}',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        trailing: Text(
                          '${_formatMoney(it.totalPriceUzs)} so‘m',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: it.isBought ? Colors.grey : XonaDoshColors.emeraldDark,
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.storefront_rounded, size: 14, color: XonaDoshColors.emerald),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Eng arzon manba: ${it.cheapestSource}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: XonaDoshColors.emeraldDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                if (it.buyingTips.isNotEmpty) ...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          it.buyingTips,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                if (it.minPriceUzs > 0 && it.maxPriceUzs > 0) ...[
                                  Text(
                                    'Bozor narxlari oralig‘i: ${_formatMoney(it.minPriceUzs)} – ${_formatMoney(it.maxPriceUzs)} so‘m/${it.unit}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                if (it.usedForMeals.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: it.usedForMeals.map((m) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(m, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                    )).toList(),
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
              )),
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
      loading: () => const Center(child: CircularProgressIndicator(color: XonaDoshColors.emerald)),
      error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
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
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // Compact summary — numbers first, almost no prose
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                            Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            Expanded(
                              child: _financeStat(
                                Icons.schedule_rounded,
                                _formatMoney(data.totalPendingUzs.toDouble()),
                                'Qarz',
                                const Color(0xFFEF4444),
                                isDark,
                              ),
                            ),
                            Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                              value: ((data.totalSpendUzs - data.totalPendingUzs) / data.totalSpendUzs)
                                  .clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              color: XonaDoshColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(((data.totalSpendUzs - data.totalPendingUzs) / data.totalSpendUzs) * 100).round()}% to‘langan',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (data.debtBalances.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.debtBalances.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = data.debtBalances[i];
                          return Container(
                            width: 168,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _avatarInitial(d.debtor, const Color(0xFFF59E0B)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFF59E0B)),
                                    ),
                                    _avatarInitial(d.creditor, XonaDoshColors.emerald),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  _formatMoney(d.amountUzs.toDouble()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                Text(
                                  'so‘m',
                                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ],
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
                        _financeChip('rent', 'Ijara', data.rentItems.length, isDark),
                        _financeChip('utility', 'Kommunal', data.utilityItems.length, isDark),
                        _financeChip('expense', 'Xarid', data.expenseItems.length, isDark),
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
                          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Bo‘sh', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((f) => _buildFinanceItemCard(context, f, isDark)),
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
                label: const Text('To‘lov', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _financeStat(IconData icon, String value, String label, Color accent, bool isDark) {
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
      child: Text(initial, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
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
        selectedColor: XonaDoshColors.emerald.withValues(alpha: isDark ? 0.25 : 0.15),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        side: BorderSide(
          color: selected ? XonaDoshColors.emerald : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: selected ? XonaDoshColors.emeraldDark : (isDark ? Colors.white70 : const Color(0xFF334155)),
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

  Widget _buildFinanceItemCard(BuildContext context, XonadoshFinanceItem item, bool isDark) {
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
                      child: Icon(_financeTypeIcon(item.type), color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                item.isSettled ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                                size: 13,
                                color: item.isSettled ? XonaDoshColors.emerald : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isSettled ? 'Yopildi' : '${unpaid.length} kishi qarzdor',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.isSettled ? XonaDoshColors.emerald : const Color(0xFFD97706),
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
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'so‘m',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[500]),
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
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
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
                            await ref.read(xonadoshRepositoryProvider).toggleFinancePaid(
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: s.isPaid
                                  ? XonaDoshColors.emerald.withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: s.isPaid
                                    ? XonaDoshColors.emerald.withValues(alpha: 0.4)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.isPaid ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: s.isPaid ? XonaDoshColors.emerald : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: s.isPaid
                                        ? XonaDoshColors.emeraldDark
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                    decoration: s.isPaid ? TextDecoration.lineThrough : null,
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

  void _showFinanceDetailSheet(BuildContext context, XonadoshFinanceItem item, bool isDark) {
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
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
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
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(
                          '${_formatMoney(item.amountUzs.toDouble())} so‘m',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: typeColor),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _avatarInitial(
                        s.name,
                        s.isPaid ? XonaDoshColors.emerald : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                      Text(
                        _formatMoney(s.amountUzs.toDouble()),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 34),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          await ref.read(xonadoshRepositoryProvider).toggleFinancePaid(
                            financeId: item.id,
                            memberName: s.name,
                            isPaid: !s.isPaid,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          ref.invalidate(xonadoshFinancesProvider);
                        },
                        child: Text(
                          s.isPaid ? 'Bekor' : 'To‘ladi',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
      loading: () => const Center(child: CircularProgressIndicator(color: XonaDoshColors.emerald)),
      error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
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
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Anonim',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                      label: const Text('Yangi masala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  child: const Center(child: Text('Hozircha o‘rtaga tashlangan masalalar yo‘q')),
                )
              else
                ...data.polls.map((poll) => _buildPollCard(context, poll, isDark)),
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
                  style: TextStyle(color: statusBadgeColor, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              Text(
                '${poll.totalVotes} ta ovoz',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w600),
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
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
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
                child: Text(
                  '👍 ${poll.votesYes} (${poll.yesPercent}%)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: XonaDoshColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '👎 ${poll.votesNo} (${poll.noPercent}%)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '🤷 ${poll.votesNeutral}',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: XonaDoshColors.primary.withValues(alpha: 0.15),
                      foregroundColor: XonaDoshColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: () => _submitVote(poll.id, 'yes'),
                    child: const Text('👍 Rozi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFFB91C1C),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: () => _submitVote(poll.id, 'no'),
                    child: const Text('👎 Qarshi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: () => _submitVote(poll.id, 'neutral'),
                    child: const Text('🤷‍♂️ Betaraf', style: TextStyle(fontSize: 11)),
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
    final res = await ref.read(xonadoshRepositoryProvider).votePoll(
      pollId: pollId,
      vote: vote,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Ovozingiz qabul qilindi!'),
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
      loading: () => const Center(child: CircularProgressIndicator(color: XonaDoshColors.emerald)),
      error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
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
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showGiveKarmaDialog(context, data.roommates, data.availableBadges),
                      icon: const Icon(Icons.star_rounded, size: 16),
                      label: const Text('Ball berish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
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
                                Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(
                                  '${member.badgesCount} ta nishon olingan',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  '${member.totalPoints} ball',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFD97706)),
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
                          children: member.badgesSummary.map((b) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${b['name']} (${b['count']})',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          )).toList(),
                        ),
                      ],
                      if (member.recentPraises.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 6),
                        Text(
                          '💬 Oxirgi izoh: "${member.recentPraises.first.comment}" — ${member.recentPraises.first.fromName}',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey[300] : Colors.grey[700]),
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
  Widget _buildSummaryTile(String label, String value, Color color, bool isDark) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.l10n.xonadoshNewDuty, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                decoration: InputDecoration(labelText: context.l10n.xonadoshDutyPersonInCharge),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: day,
                decoration: InputDecoration(labelText: context.l10n.xonadoshDutyDay),
                items: [
                  DropdownMenuItem(value: 'dushanba', child: Text(context.l10n.xonadoshDayMonday)),
                  DropdownMenuItem(value: 'seshanba', child: Text(context.l10n.xonadoshDayTuesday)),
                  DropdownMenuItem(value: 'chorshanba', child: Text(context.l10n.xonadoshDayWednesday)),
                  DropdownMenuItem(value: 'payshanba', child: Text(context.l10n.xonadoshDayThursday)),
                  DropdownMenuItem(value: 'juma', child: Text(context.l10n.xonadoshDayFriday)),
                  DropdownMenuItem(value: 'shanba', child: Text(context.l10n.xonadoshDaySaturday)),
                  DropdownMenuItem(value: 'yakshanba', child: Text(context.l10n.xonadoshDaySunday)),
                ],
                onChanged: (val) => setDialogState(() => day = val ?? 'dushanba'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: XonaDoshColors.emerald),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(xonadoshRepositoryProvider).addChore({
                  'title': titleCtrl.text.trim(),
                  'assigned_name': personCtrl.text.trim().isEmpty ? 'Jasur' : personCtrl.text.trim(),
                  'day_of_week': day,
                  'group_code': 'home_default',
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
      'rent': [
        (title: 'Oylik ijara', amount: '4000000'),
      ],
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                          decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Yangi to‘lov', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _typePick('utility', Icons.bolt_rounded, 'Kommunal', type, (v) {
                            setDialogState(() {
                              type = v;
                              titleCtrl.clear();
                              amountCtrl.clear();
                            });
                          }, isDark),
                          const SizedBox(width: 6),
                          _typePick('rent', Icons.home_rounded, 'Ijara', type, (v) {
                            setDialogState(() {
                              type = v;
                              titleCtrl.clear();
                              amountCtrl.clear();
                            });
                          }, isDark),
                          const SizedBox(width: 6),
                          _typePick('expense_split', Icons.shopping_bag_rounded, 'Xarid', type, (v) {
                            setDialogState(() {
                              type = v;
                              titleCtrl.clear();
                              amountCtrl.clear();
                            });
                          }, isDark),
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
                        decoration: const InputDecoration(labelText: 'Nomi', hintText: 'Masalan: Svet'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Summa', hintText: '180000', suffixText: 'so‘m'),
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
                              onSelected: (_) => setDialogState(() => paidBy = 'Uy egasiga'),
                            ),
                          ...roommates.map((r) => ChoiceChip(
                                label: Text(r),
                                selected: paidBy == r,
                                onSelected: (_) => setDialogState(() => paidBy = r),
                              )),
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
                            final amt = int.tryParse(amountCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
                            if (titleCtrl.text.trim().isEmpty || amt <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nom va summani kiriting')),
                              );
                              return;
                            }
                            await ref.read(xonadoshRepositoryProvider).addFinance({
                              'type': type,
                              'title': titleCtrl.text.trim(),
                              'amount_uzs': amt,
                              'paid_by': paidBy,
                              'group_code': 'home_default',
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            ref.invalidate(xonadoshFinancesProvider);
                          },
                          child: const Text('Saqlash va taqsimlash', style: TextStyle(fontWeight: FontWeight.w800)),
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
              Icon(icon, size: 20, color: selected ? XonaDoshColors.emerald : Colors.grey),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yangi masala', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategoriya'),
                  items: const [
                    DropdownMenuItem(value: 'rules', child: Text('📋 Xonadon qoidasi')),
                    DropdownMenuItem(value: 'cleaning', child: Text('🧹 Tozalik va tartib')),
                    DropdownMenuItem(value: 'shopping', child: Text('🛒 Xaridlar va byudjet')),
                    DropdownMenuItem(value: 'guests', child: Text('👥 Mehmonlar tartibi')),
                    DropdownMenuItem(value: 'general', child: Text('💡 Umumiy taklif')),
                  ],
                  onChanged: (val) => setDialogState(() => category = val ?? 'rules'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Masala / Taklif sarlavhasi',
                    hintText: 'e.g. 23:00 dan keyin oshxonada shovqin qilmaslik',
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
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4338CA)),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(xonadoshRepositoryProvider).createPoll({
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'category': category,
                  'group_code': 'home_default',
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

  void _showGiveKarmaDialog(BuildContext context, List<String> roommates, List<XonadoshKarmaBadge> badges) {
    String selectedRoommate = roommates.isNotEmpty ? roommates.first : 'Azizbek';
    String selectedBadgeKey = badges.isNotEmpty ? badges.first.key : 'cleanliness_master';
    String selectedBadgeName = badges.isNotEmpty ? badges.first.name : 'Tozalik ustasi';
    final commentCtrl = TextEditingController();
    int points = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Minnatdorchilik bildirish', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRoommate,
                  decoration: const InputDecoration(labelText: 'Kimga obro‘ berasiz?'),
                  items: (roommates.isEmpty ? ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'] : roommates)
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedRoommate = val ?? 'Azizbek'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedBadgeKey,
                  decoration: const InputDecoration(labelText: 'Qanday nishon berasiz?'),
                  items: (badges.isEmpty ? [
                    const XonadoshKarmaBadge(key: 'cleanliness_master', name: 'Tozalik ustasi', icon: '🧹', description: ''),
                    const XonadoshKarmaBadge(key: 'chef_pro', name: 'Mohir oshpaz', icon: '👨‍🍳', description: ''),
                    const XonadoshKarmaBadge(key: 'ontime_payer', name: 'Vaqtida to‘lovchi', icon: '⏱', description: ''),
                  ] : badges)
                      .map((b) => DropdownMenuItem(value: b.key, child: Text('${b.icon} ${b.name}')))
                      .toList(),
                  onChanged: (val) {
                    final found = badges.firstWhere((b) => b.key == val, orElse: () => badges.first);
                    setDialogState(() {
                      selectedBadgeKey = val ?? 'cleanliness_master';
                      selectedBadgeName = found.name;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Ball miqdori:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 10),
                    ...[1, 2, 3, 5].map((p) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('+$p'),
                        selected: points == p,
                        onSelected: (val) => setDialogState(() => points = p),
                      ),
                    )),
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
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
              onPressed: () async {
                await ref.read(xonadoshRepositoryProvider).giveKarma({
                  'from_name': 'Xonadosh',
                  'to_name': selectedRoommate,
                  'badge_key': selectedBadgeKey,
                  'badge_name': selectedBadgeName,
                  'points': points,
                  'comment': commentCtrl.text.trim(),
                  'group_code': 'home_default',
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

  void _showRecipePickerSheet(BuildContext context, String day, String mealTime, String currentRecipeName) {
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
}
