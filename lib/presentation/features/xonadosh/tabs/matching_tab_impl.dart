import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/block_user_action.dart';
import 'package:xonadosh/presentation/common/contact_actions.dart';
import 'package:xonadosh/presentation/common/report_content_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class XonadoshMatchingTab extends ConsumerWidget {
  const XonadoshMatchingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final myProfileAsync = ref.watch(xonadoshMyProfileProvider);
    final matchesAsync = ref.watch(xonadoshMatchingRoommatesProvider);
    final selectedGender = ref.watch(xonadoshMatchGenderFilterProvider);
    final selectedUni = ref.watch(xonadoshMatchUniProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: XonaDoshColors.primary,
        onRefresh: () async {
          ref.invalidate(xonadoshMatchingRoommatesProvider);
          ref.invalidate(xonadoshMyProfileProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. My Profile Status Card Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: myProfileAsync.when(
                  loading: () => _buildLoadingBanner(),
                  error: (_, _) => _buildCreateProfileBanner(context, ref, null),
                  data: (myProf) {
                    if (myProf != null && myProf.fullName.isNotEmpty) {
                      return _buildActiveProfileBanner(context, ref, myProf, isDark);
                    } else {
                      return _buildCreateProfileBanner(context, ref, null);
                    }
                  },
                ),
              ),
            ),

            // 2. Filters Row (Gender & University)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.commonAll),
                        selected: selectedGender == 'any',
                        onSelected: (_) =>
                            ref.read(xonadoshMatchGenderFilterProvider.notifier).state = 'any',
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.man_rounded, size: 16),
                        label: Text(l10n.xonadoshBoys),
                        selected: selectedGender == 'boys',
                        onSelected: (_) =>
                            ref.read(xonadoshMatchGenderFilterProvider.notifier).state = 'boys',
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.woman_rounded, size: 16),
                        label: Text(l10n.xonadoshGirls),
                        selected: selectedGender == 'girls',
                        onSelected: (_) =>
                            ref.read(xonadoshMatchGenderFilterProvider.notifier).state = 'girls',
                      ),
                      if (selectedUni != null) ...[
                        const SizedBox(width: 8),
                        InputChip(
                          avatar: const Icon(Icons.school_rounded, size: 14),
                          label: Text(selectedUni.shortName),
                          selected: true,
                          onDeleted: () {
                            ref.read(xonadoshMatchUniProvider.notifier).state = null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 3. Matches List
            matchesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: XonaDoshColors.primary),
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
                          onPressed: () => ref.invalidate(xonadoshMatchingRoommatesProvider),
                          child: Text(context.l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (candidates) {
                if (candidates.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: XonaDoshColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.group_off_rounded, size: 44, color: XonaDoshColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.xonadoshNoMatchesTitle,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.xonadoshNoMatchesBody,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => _openProfileScreen(context, ref, myProfileAsync.valueOrNull),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: Text(l10n.xonadoshFillProfile),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: XonaDoshColors.primary,
                                foregroundColor: Colors.white,
                              ),
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
                        final item = candidates[index];
                        return _buildRoommateCard(
                          context,
                          ref,
                          item,
                          myProfileAsync.valueOrNull,
                          isDark,
                        );
                      },
                      childCount: candidates.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileScreen(BuildContext context, WidgetRef ref, XonadoshProfile? profile) async {
    await context.push(AppRoutes.xonadoshProfileEdit, extra: profile);
    if (context.mounted) {
      ref.invalidate(xonadoshMyProfileProvider);
      ref.invalidate(xonadoshMatchingRoommatesProvider);
    }
  }

  int _calcProfileCompletion(XonadoshProfile prof) {
    int score = 0;
    if (prof.fullName.trim().isNotEmpty) score += 20;
    if (prof.phoneNumber.trim().isNotEmpty) score += 20;
    if ((prof.universityShort ?? '').trim().isNotEmpty || prof.universityId != null) score += 20;
    if (prof.avatarUrl != null && prof.avatarUrl!.trim().isNotEmpty) score += 15;
    if (prof.aboutMe.trim().isNotEmpty) score += 15;
    if (prof.telegramHandle != null && prof.telegramHandle!.trim().isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }

  Widget _buildLoadingBanner() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: XonaDoshColors.primary)),
    );
  }

  Widget _buildCreateProfileBanner(BuildContext context, WidgetRef ref, XonadoshProfile? myProfile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
              color: XonaDoshColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_ind_outlined, color: XonaDoshColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xonadoshlik anketasi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Mos sheriklar topish uchun to‘ldiring',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _openProfileScreen(context, ref, myProfile),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('To‘ldirish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProfileBanner(BuildContext context, WidgetRef ref, XonadoshProfile prof, bool isDark) {
    final l10n = context.l10n;
    final completion = _calcProfileCompletion(prof);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            backgroundImage: prof.avatarUrl != null && prof.avatarUrl!.isNotEmpty
                ? NetworkImage(prof.avatarUrl!)
                : null,
            child: prof.avatarUrl == null || prof.avatarUrl!.isEmpty
                ? Text(
                    prof.fullName.isNotEmpty ? prof.fullName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prof.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_uniLabel(prof.universityShort, l10n)} · Anketa $completion%',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openProfileScreen(context, ref, prof),
            icon: const Icon(Icons.edit_outlined, size: 16),
            tooltip: l10n.commonEdit,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildRoommateCard(
    BuildContext context,
    WidgetRef ref,
    XonadoshProfile item,
    XonadoshProfile? myProfile,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final score = item.compatibilityScore ?? 85;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showRoommateDetailSheet(context, ref, item, myProfile, isDark),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name & Age, Uni & Course, Match Score Pill
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                        ? NetworkImage(item.avatarUrl!)
                        : null,
                    child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                        ? Text(
                            item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'T',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.age > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                ', ${item.age}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_uniLabel(item.universityShort, l10n)} · ${l10n.xonadoshCourseYearSuffix(item.courseYear)}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Match Score Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: XonaDoshColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: const TextStyle(
                            color: XonaDoshColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'mos',
                          style: TextStyle(
                            color: XonaDoshColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Lifestyle traits chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildHabitPill(Icons.bedtime_outlined, _sleepLabel(item.sleepSchedule, l10n), isDark),
                  _buildHabitPill(Icons.cleaning_services_outlined, _cleanLabel(item.cleanliness, l10n), isDark),
                  _buildHabitPill(Icons.smoke_free_outlined, _smokeLabel(item.smokingHabit, l10n), isDark),
                ],
              ),

              const SizedBox(height: 10),

              // Footer: Budget & Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '~${(item.budgetMax / 1000).toStringAsFixed(0)}k ${l10n.currencyUzsSuffix}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => ContactActions.callPhone(context, item.phoneNumber),
                        tooltip: 'Qo‘ng‘iroq',
                        icon: const Icon(Icons.call_rounded, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: XonaDoshColors.primary.withValues(alpha: 0.1),
                          foregroundColor: XonaDoshColors.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      if (item.telegramHandle != null && item.telegramHandle!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () => ContactActions.openTelegram(context, item.telegramHandle),
                          tooltip: 'Telegram',
                          icon: const Icon(Icons.send_rounded, size: 14),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF0284C7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      FilledButton.tonal(
                        onPressed: () => _showRoommateDetailSheet(context, ref, item, myProfile, isDark),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Batafsil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitPill(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoommateDetailSheet(
    BuildContext context,
    WidgetRef ref,
    XonadoshProfile item,
    XonadoshProfile? myProfile,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final score = item.compatibilityScore ?? 85;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                              ? NetworkImage(item.avatarUrl!)
                              : null,
                          child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                              ? Text(
                                  item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'T',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.age > 0 ? '${item.fullName}, ${item.age}' : item.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_uniLabel(item.universityShort, l10n)} · ${l10n.xonadoshCourseYearSuffix(item.courseYear)}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: XonaDoshColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$score% mos',
                            style: const TextStyle(
                              color: XonaDoshColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // O'zi haqida
                    if (item.aboutMe.isNotEmpty) ...[
                      const Text('Men haqimda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(item.aboutMe, style: const TextStyle(fontSize: 13, height: 1.4)),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Qanday xonadosh qidiryapti
                    if (item.lookingForText.isNotEmpty) ...[
                      const Text('Qidirilayotgan xonadosh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(item.lookingForText, style: const TextStyle(fontSize: 13, height: 1.4)),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Odatlar va talablar (Visual grid chips)
                    const Text('Odatlar va talablar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTraitChip(Icons.bedtime_outlined, l10n.xonadoshSleepSchedule, _sleepLabel(item.sleepSchedule, l10n), isDark),
                        _buildTraitChip(Icons.cleaning_services_outlined, l10n.xonadoshCleanliness, _cleanLabel(item.cleanliness, l10n), isDark),
                        _buildTraitChip(Icons.headphones_outlined, l10n.xonadoshStudyEnvironment, _studyLabel(item.studyHabit, l10n), isDark),
                        _buildTraitChip(Icons.soup_kitchen_outlined, l10n.xonadoshCooking, _cookLabel(item.cookingHabit, l10n), isDark),
                        _buildTraitChip(Icons.smoke_free_outlined, l10n.xonadoshSmoking, _smokeLabel(item.smokingHabit, l10n), isDark),
                        _buildTraitChip(
                          Icons.account_balance_wallet_outlined,
                          l10n.xonadoshBudgetRangeLabel,
                          '${(item.budgetMin / 1000).toStringAsFixed(0)}k – ${(item.budgetMax / 1000).toStringAsFixed(0)}k ${l10n.currencyUzsSuffix}',
                          isDark,
                        ),
                        if (item.targetDistrict.isNotEmpty)
                          _buildTraitChip(Icons.location_on_outlined, 'Tuman', item.targetDistrict, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ContactActions.callPhone(context, item.phoneNumber),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: Text(l10n.xonadoshCall, style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: XonaDoshColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (item.telegramHandle != null && item.telegramHandle!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => ContactActions.openTelegram(context, item.telegramHandle),
                          icon: const Icon(Icons.send_rounded, size: 15),
                          label: const Text('Telegram', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        confirmAndBlockUser(
                          context,
                          ref,
                          username: item.username,
                          popAfter: true,
                        );
                      },
                      tooltip: l10n.blockUser,
                      icon: const Icon(Icons.block_outlined, size: 18, color: Colors.grey),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showReportContentDialog(
                          context,
                          ref,
                          targetType: ReportTargetType.profile,
                          targetId: item.username.isNotEmpty ? item.username : '${item.id}',
                          subjectLabel: l10n.reportContentSubjectProfile(item.fullName),
                        );
                      },
                      tooltip: l10n.reportAction,
                      icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitChip(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: XonaDoshColors.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _uniLabel(String? short, AppLocalizations l10n) {
    final v = (short ?? '').trim();
    return v.isEmpty ? l10n.xonadoshUniFallback : v;
  }

  String _sleepLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'early_bird': return l10n.xonadoshSleepEarlyHours;
      case 'night_owl': return l10n.xonadoshSleepNightHours;
      default: return l10n.xonadoshHabitFlexible;
    }
  }

  String _cleanLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'strict': return l10n.xonadoshHabitStrictClean;
      case 'moderate': return l10n.xonadoshHabitAverageClean;
      default: return l10n.xonadoshHabitRelaxedClean;
    }
  }

  String _studyLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'silent': return l10n.xonadoshHabitSilentStudy;
      case 'music': return l10n.xonadoshHabitMusicStudy;
      default: return l10n.xonadoshHabitGroupStudy;
    }
  }

  String _cookLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'cooks_often':
      case 'rotates': return l10n.xonadoshHabitCookRotates;
      case 'cooks_rarely':
      case 'cooks_self': return l10n.xonadoshHabitCookSelf;
      default: return l10n.xonadoshHabitEatOut;
    }
  }

  String _smokeLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'smoker':
      case 'yes': return l10n.xonadoshHabitSmoker;
      case 'outdoor_only':
      case 'balcony': return l10n.xonadoshHabitBalconySmoke;
      default: return l10n.xonadoshHabitIDontSmoke;
    }
  }
}
