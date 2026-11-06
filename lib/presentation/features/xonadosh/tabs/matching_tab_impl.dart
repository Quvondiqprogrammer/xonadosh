import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/app_localizations.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/block_user_action.dart';
import 'package:xonadosh/presentation/common/contact_actions.dart';
import 'package:xonadosh/presentation/common/empty_state.dart';
import 'package:xonadosh/presentation/common/report_content_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/match_reasons.dart';
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
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. My Profile Status Card Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: myProfileAsync.when(
                  loading: () => _buildLoadingBanner(),
                  error: (_, _) =>
                      _buildCreateProfileBanner(context, ref, null),
                  data: (myProf) {
                    if (myProf != null && myProf.fullName.isNotEmpty) {
                      return _buildActiveProfileBanner(
                        context,
                        ref,
                        myProf,
                        isDark,
                      );
                    } else {
                      return _buildCreateProfileBanner(context, ref, null);
                    }
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _CampusFitFeatureCard(isDark: isDark, l10n: l10n),
              ),
            ),

            // 2. Xonadosh Jamoasi (Coliving Squads)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ColivingSquadsSection(isDark: isDark),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.xonadoshMatchFiltersLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text(l10n.commonAll),
                            selected: selectedGender == 'any',
                            onSelected: (_) =>
                                ref
                                        .read(
                                          xonadoshMatchGenderFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    'any',
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: const Icon(Icons.man_rounded, size: 16),
                            label: Text(l10n.xonadoshBoys),
                            selected: selectedGender == 'boys',
                            onSelected: (_) =>
                                ref
                                        .read(
                                          xonadoshMatchGenderFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    'boys',
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: const Icon(Icons.woman_rounded, size: 16),
                            label: Text(l10n.xonadoshGirls),
                            selected: selectedGender == 'girls',
                            onSelected: (_) =>
                                ref
                                        .read(
                                          xonadoshMatchGenderFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    'girls',
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.school_outlined, size: 16),
                            label: Text(
                              selectedUni?.shortName ??
                                  l10n.xonadoshUniversityFilter,
                            ),
                            onPressed: () => _openUniPicker(context, ref),
                          ),
                          if (selectedUni != null) ...[
                            const SizedBox(width: 8),
                            InputChip(
                              avatar: const Icon(
                                Icons.school_rounded,
                                size: 14,
                              ),
                              label: Text(selectedUni.shortName),
                              selected: true,
                              onDeleted: () {
                                ref
                                        .read(xonadoshMatchUniProvider.notifier)
                                        .state =
                                    null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (selectedGender != 'any' || selectedUni != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            l10n.xonadoshFiltersOn,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                      .read(
                                        xonadoshMatchGenderFilterProvider
                                            .notifier,
                                      )
                                      .state =
                                  'any';
                              ref
                                      .read(xonadoshMatchUniProvider.notifier)
                                      .state =
                                  null;
                            },
                            child: Text(l10n.xonadoshClearFilter),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 3. Matches List
            matchesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: XonaDoshColors.primary,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.xonadoshErrGeneric('$err'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(xonadoshMatchingRoommatesProvider),
                          child: Text(context.l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (candidates) {
                if (candidates.isEmpty) {
                  final myProf = myProfileAsync.valueOrNull;
                  final profileReady =
                      myProf != null && myProf.fullName.isNotEmpty;
                  final filtersOn =
                      selectedGender != 'any' || selectedUni != null;
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.group_off_rounded,
                      accentColor: XonaDoshColors.primary,
                      title: l10n.xonadoshNoMatchesTitle,
                      subtitle: !profileReady
                          ? l10n.xonadoshEmptyMatchesNeedProfile
                          : (filtersOn
                                ? l10n.xonadoshEmptyMatchesFiltered
                                : l10n.xonadoshNoMatchesBody),
                      action: FilledButton.icon(
                        onPressed: () =>
                            _openProfileScreen(context, ref, myProf),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(l10n.xonadoshFillProfile),
                      ),
                      secondaryAction: filtersOn
                          ? TextButton(
                              onPressed: () {
                                ref
                                        .read(
                                          xonadoshMatchGenderFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    'any';
                                ref
                                        .read(xonadoshMatchUniProvider.notifier)
                                        .state =
                                    null;
                              },
                              child: Text(l10n.xonadoshClearFilters),
                            )
                          : TextButton.icon(
                              onPressed: () =>
                                  ref
                                          .read(
                                            xonadoshShellTabIndexProvider
                                                .notifier,
                                          )
                                          .state =
                                      0,
                              icon: const Icon(Icons.home_outlined, size: 18),
                              label: Text(l10n.xonadoshFindRoom),
                            ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = candidates[index];
                      return _buildRoommateCard(
                        context,
                        ref,
                        item,
                        myProfileAsync.valueOrNull,
                        isDark,
                      );
                    }, childCount: candidates.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUniPicker(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    var unis = <XonadoshUniversity>[];
    try {
      unis = await ref.read(xonadoshAllUniversitiesProvider.future);
    } catch (_) {}
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final selected = ref.read(xonadoshMatchUniProvider);
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                l10n.xonadoshUniversityFilter,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(l10n.xonadoshAllUniversities),
                selected: selected == null,
                onTap: () {
                  ref.read(xonadoshMatchUniProvider.notifier).state = null;
                  Navigator.of(ctx).pop();
                },
              ),
              ...unis.map(
                (u) => ListTile(
                  title: Text(u.shortName),
                  subtitle: Text(u.city),
                  selected: selected?.id == u.id,
                  onTap: () {
                    ref.read(xonadoshMatchUniProvider.notifier).state = u;
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openProfileScreen(
    BuildContext context,
    WidgetRef ref,
    XonadoshProfile? profile,
  ) async {
    await context.push(AppRoutes.xonadoshProfileEdit, extra: profile);
    if (context.mounted) {
      ref.invalidate(xonadoshMyProfileProvider);
      ref.invalidate(xonadoshMatchingRoommatesProvider);
    }
  }

  int _calcProfileCompletion(XonadoshProfile prof) {
    int score = 0;
    if (prof.fullName.trim().isNotEmpty) {
      score += 20;
    }
    if (prof.phoneNumber.trim().isNotEmpty) {
      score += 20;
    }
    if ((prof.universityShort ?? '').trim().isNotEmpty ||
        prof.universityId != null) {
      score += 20;
    }
    if (prof.avatarUrl != null && prof.avatarUrl!.trim().isNotEmpty) {
      score += 15;
    }
    if (prof.aboutMe.trim().isNotEmpty) {
      score += 15;
    }
    if (prof.telegramHandle != null && prof.telegramHandle!.trim().isNotEmpty) {
      score += 10;
    }
    return score.clamp(0, 100);
  }

  Widget _buildLoadingBanner() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: XonaDoshColors.primary,
        ),
      ),
    );
  }

  Widget _buildCreateProfileBanner(
    BuildContext context,
    WidgetRef ref,
    XonadoshProfile? myProfile,
  ) {
    final l10n = context.l10n;
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
            child: const Icon(
              Icons.assignment_ind_outlined,
              color: XonaDoshColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.xonadoshSurveyTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.xonadoshEmptyMatchesNeedProfile,
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
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _openProfileScreen(context, ref, myProfile),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.xonadoshFillProfile,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProfileBanner(
    BuildContext context,
    WidgetRef ref,
    XonadoshProfile prof,
    bool isDark,
  ) {
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
            backgroundColor: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFF1F5F9),
            backgroundImage:
                prof.avatarUrl != null && prof.avatarUrl!.isNotEmpty
                ? NetworkImage(prof.avatarUrl!)
                : null,
            child: prof.avatarUrl == null || prof.avatarUrl!.isEmpty
                ? Text(
                    prof.fullName.isNotEmpty
                        ? prof.fullName[0].toUpperCase()
                        : 'U',
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_uniLabel(prof.universityShort, l10n)} · Anketa $completion%',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: XonaDoshStyles.cardDecoration(isDark, radius: 16),
      child: InkWell(
        onTap: () =>
            _showRoommateDetailSheet(context, ref, item, myProfile, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name & Age, Uni & Course, Match Score Pill
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    backgroundImage:
                        item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                        ? NetworkImage(item.avatarUrl!)
                        : null,
                    child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                        ? Text(
                            item.fullName.isNotEmpty
                                ? item.fullName[0].toUpperCase()
                                : 'T',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.age > 0)
                              Text(
                                ', ${item.age}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_uniLabel(item.universityShort, l10n)} · ${l10n.xonadoshCourseYearSuffix(item.courseYear)}',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Match Score Pill
                  _buildMatchScoreBadge(score, isDark),
                ],
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildHabitPill(
                    Icons.bedtime_outlined,
                    _sleepLabel(item.sleepSchedule, l10n),
                    isDark,
                  ),
                  _buildHabitPill(
                    Icons.cleaning_services_outlined,
                    _cleanLabel(item.cleanliness, l10n),
                    isDark,
                  ),
                  _buildHabitPill(
                    Icons.smoke_free_outlined,
                    _smokeLabel(item.smokingHabit, l10n),
                    isDark,
                  ),
                ],
              ),
              if (visibleMatchReasons(
                candidate: item,
                me: myProfile,
                l10n: l10n,
              ).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.xonadoshWhyMatch,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      visibleMatchReasons(
                            candidate: item,
                            me: myProfile,
                            l10n: l10n,
                          )
                          .map(
                            (r) => _buildHabitPill(
                              Icons.check_circle_outline,
                              r,
                              isDark,
                            ),
                          )
                          .toList(),
                ),
              ],

              const SizedBox(height: 10),

              // Footer: Budget & Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
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
                        const Icon(
                          Icons.payments_outlined,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${(item.budgetMax / 1000).toStringAsFixed(0)}k ${l10n.currencyUzsSuffix}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () =>
                            ContactActions.callPhone(context, item.phoneNumber),
                        tooltip: l10n.xonadoshCallShort,
                        icon: const Icon(Icons.call_rounded, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: XonaDoshColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: XonaDoshColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      if (item.telegramHandle != null &&
                          item.telegramHandle!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () => ContactActions.openTelegram(
                            context,
                            item.telegramHandle,
                          ),
                          tooltip: l10n.xonadoshTelegram,
                          icon: const Icon(Icons.send_rounded, size: 14),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF0284C7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      FilledButton.tonal(
                        onPressed: () => _showRoommateDetailSheet(
                          context,
                          ref,
                          item,
                          myProfile,
                          isDark,
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.xonadoshMoreDetails,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
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

  Widget _buildMatchScoreBadge(int score, bool isDark) {
    final isHigh = score >= 80;
    final isMed = score >= 60;
    final gradColors = isHigh
        ? const [Color(0xFF059669), Color(0xFF10B981)]
        : (isMed
              ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
              : const [Color(0xFF64748B), Color(0xFF94A3B8)]);
    final icon = isHigh ? '🔥' : (isMed ? '⚡' : '✨');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradColors),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
          Icon(
            icon,
            size: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
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
                          backgroundColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          backgroundImage:
                              item.avatarUrl != null &&
                                  item.avatarUrl!.isNotEmpty
                              ? NetworkImage(item.avatarUrl!)
                              : null,
                          child:
                              item.avatarUrl == null || item.avatarUrl!.isEmpty
                              ? Text(
                                  item.fullName.isNotEmpty
                                      ? item.fullName[0].toUpperCase()
                                      : 'T',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
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
                                item.age > 0
                                    ? '${item.fullName}, ${item.age}'
                                    : item.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_uniLabel(item.universityShort, l10n)} · ${l10n.xonadoshCourseYearSuffix(item.courseYear)}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildMatchScoreBadge(score, isDark),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (visibleMatchReasons(
                      candidate: item,
                      me: myProfile,
                      l10n: l10n,
                      limit: 5,
                    ).isNotEmpty) ...[
                      Text(
                        l10n.xonadoshWhyMatch,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            visibleMatchReasons(
                                  candidate: item,
                                  me: myProfile,
                                  l10n: l10n,
                                  limit: 5,
                                )
                                .map(
                                  (r) => _buildHabitPill(
                                    Icons.check_circle_outline,
                                    r,
                                    isDark,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (item.aboutMe.isNotEmpty) ...[
                      const Text(
                        'Men haqimda',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          item.aboutMe,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Qanday xonadosh qidiryapti
                    if (item.lookingForText.isNotEmpty) ...[
                      const Text(
                        'Qidirilayotgan xonadosh',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          item.lookingForText,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Odatlar va talablar (Visual grid chips)
                    const Text(
                      'Odatlar va talablar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTraitChip(
                          Icons.bedtime_outlined,
                          l10n.xonadoshSleepSchedule,
                          _sleepLabel(item.sleepSchedule, l10n),
                          isDark,
                        ),
                        _buildTraitChip(
                          Icons.cleaning_services_outlined,
                          l10n.xonadoshCleanliness,
                          _cleanLabel(item.cleanliness, l10n),
                          isDark,
                        ),
                        _buildTraitChip(
                          Icons.headphones_outlined,
                          l10n.xonadoshStudyEnvironment,
                          _studyLabel(item.studyHabit, l10n),
                          isDark,
                        ),
                        _buildTraitChip(
                          Icons.soup_kitchen_outlined,
                          l10n.xonadoshCooking,
                          _cookLabel(item.cookingHabit, l10n),
                          isDark,
                        ),
                        _buildTraitChip(
                          Icons.smoke_free_outlined,
                          l10n.xonadoshSmoking,
                          _smokeLabel(item.smokingHabit, l10n),
                          isDark,
                        ),
                        _buildTraitChip(
                          Icons.account_balance_wallet_outlined,
                          l10n.xonadoshBudgetRangeLabel,
                          '${(item.budgetMin / 1000).toStringAsFixed(0)}k – ${(item.budgetMax / 1000).toStringAsFixed(0)}k ${l10n.currencyUzsSuffix}',
                          isDark,
                        ),
                        if (item.targetDistrict.isNotEmpty)
                          _buildTraitChip(
                            Icons.location_on_outlined,
                            'Tuman',
                            item.targetDistrict,
                            isDark,
                          ),
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
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            ContactActions.callPhone(context, item.phoneNumber),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: Text(
                          l10n.xonadoshCall,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: XonaDoshColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (item.telegramHandle != null &&
                        item.telegramHandle!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => ContactActions.openTelegram(
                            context,
                            item.telegramHandle,
                          ),
                          icon: const Icon(Icons.send_rounded, size: 15),
                          label: const Text(
                            'Telegram',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                      icon: const Icon(
                        Icons.block_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showReportContentDialog(
                          context,
                          ref,
                          targetType: ReportTargetType.profile,
                          targetId: item.username.isNotEmpty
                              ? item.username
                              : '${item.id}',
                          subjectLabel: l10n.reportContentSubjectProfile(
                            item.fullName,
                          ),
                        );
                      },
                      tooltip: l10n.reportAction,
                      icon: const Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
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

  Widget _buildTraitChip(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    final cleanLabel = label.trim().replaceAll(RegExp(r'[:\s]+$'), '');
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
            '$cleanLabel: ',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
      case 'early_bird':
        return '🌅 Erta turadi';
      case 'night_owl':
        return '🌙 Tungi qush';
      default:
        return '⏱️ Erkin rejim';
    }
  }

  String _cleanLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'strict':
        return '✨ O‘ta ozoda';
      case 'moderate':
        return '🧹 Tartibli';
      default:
        return '😌 Erkin tartib';
    }
  }

  String _studyLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'silent':
        return '🤫 Sokin dars';
      case 'music':
        return '🎧 Musiqada';
      default:
        return '👥 Guruhda';
    }
  }

  String _cookLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'cooks_often':
      case 'rotates':
        return '🍳 Navbat bilan';
      case 'cooks_rarely':
      case 'cooks_self':
        return '👨‍🍳 O‘zi pishiradi';
      default:
        return '🍽️ Tashqarida';
    }
  }

  String _smokeLabel(String val, AppLocalizations l10n) {
    switch (val) {
      case 'smoker':
      case 'yes':
        return '🚬 Chekadi';
      case 'outdoor_only':
      case 'balcony':
        return '💨 Balkonda';
      default:
        return '🚭 Chekmaydi';
    }
  }
}

class _CampusFitFeatureCard extends StatefulWidget {
  const _CampusFitFeatureCard({required this.isDark, required this.l10n});

  final bool isDark;
  final AppLocalizations l10n;

  @override
  State<_CampusFitFeatureCard> createState() => _CampusFitFeatureCardState();
}

class _CampusFitFeatureCardState extends State<_CampusFitFeatureCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isDark
                ? const [Color(0xFF0F766E), Color(0xFF134E4A)]
                : const [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDark
                ? const Color(0xFF2DD4BF)
                : const Color(0xFF14B8A6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 18,
                  color: widget.isDark
                      ? const Color(0xFF99F6E4)
                      : const Color(0xFF0F766E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.l10n.xdCampusFitTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF134E4A),
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: widget.isDark
                      ? Colors.white70
                      : const Color(0xFF134E4A),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                widget.l10n.xdCampusFitBody,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: widget.isDark
                      ? const Color(0xFFCCFBF1)
                      : const Color(0xFF115E59),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.l10n.xdCampusFitPreviewBody,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? const Color(0xFF5EEAD4)
                      : const Color(0xFF0F766E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColivingSquadsSection extends ConsumerWidget {
  const _ColivingSquadsSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadsAsync = ref.watch(xonadoshSquadsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xonadosh Jamoasi (Coliving Squad)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Birgalikda budjet tuzib, tayyor guruh bo‘lib uy oling',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateSquadDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tuzish'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          squadsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Jamoalar yuklanmadi: $err',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            data: (squads) {
              if (squads.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Hozircha faol jamoalar yo‘q',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Birinchi bo‘lib o‘zingiz guruh tuzing, budjetni birlashtiring va mos sheriklarni toping!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showCreateSquadDialog(context, ref),
                        icon: const Icon(Icons.group_add_rounded, size: 15),
                        label: const Text('Birinchi bo‘lib jamoa tuzish'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: squads.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, idx) {
                    final sq = squads[idx];
                    final progress = sq.membersCount / sq.lookingForCount;

                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            children: [
                              Expanded(
                                child: Text(
                                  sq.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${sq.spotsLeft} ta joy',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '🎓 ${sq.targetUniversityName} • ${sq.targetDistrict}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: Colors.grey.withAlpha(50),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Umumiy budjet:',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${_formatMoney(sq.totalBudgetUzs)} UZS',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                              FilledButton(
                                onPressed: () =>
                                    _showJoinSquadDialog(context, ref, sq),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Qo‘shilish'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  static void _showCreateSquadDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(text: '1200000');
    final districtCtrl = TextEditingController(text: 'Chilonzor');
    final descCtrl = TextEditingController();
    int count = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text(
              '🤝 Xonadosh Jamoasi tuzish',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Jamoa nomi',
                      hintText: 'Masalan: TATU 2-kurs dasturchilari',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sizning hissangiz (oylik so‘mda)',
                      hintText: '1200000',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: districtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mo‘ljallangan tuman',
                      hintText: 'Chilonzor / Yunusobod',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: count,
                    decoration: const InputDecoration(
                      labelText: 'Jami nechta odam kerak?',
                    ),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('2 kishi')),
                      DropdownMenuItem(value: 3, child: Text('3 kishi')),
                      DropdownMenuItem(value: 4, child: Text('4 kishi')),
                    ],
                    onChanged: (v) => setDialogState(() => count = v ?? 3),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Qisqacha talablar',
                      hintText: 'Sokin, toza, dars qiladigan',
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
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final b = double.tryParse(budgetCtrl.text.trim()) ?? 1000000;
                  Navigator.pop(ctx);
                  try {
                    final res = await ref
                        .read(xonadoshRepositoryProvider)
                        .createSquad(
                          name: name,
                          targetDistrict: districtCtrl.text.trim(),
                          myBudgetUzs: b,
                          lookingForCount: count,
                          description: descCtrl.text.trim(),
                        );
                    if (context.mounted) {
                      ref.invalidate(xonadoshSquadsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            res['message']?.toString() ?? 'Jamoa tuzildi!',
                          ),
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
                child: const Text('Tuzish'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _showJoinSquadDialog(
    BuildContext context,
    WidgetRef ref,
    XonadoshSquad squad,
  ) {
    final budgetCtrl = TextEditingController(text: '1000000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${squad.name} ga qo‘shilish',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎓 ${squad.targetUniversityName} • ${squad.targetDistrict}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              'Hozirgi a‘zolar: ${squad.membersCount} / ${squad.lookingForCount} kishi',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sizning oylik budjetingiz (so‘m)',
                hintText: '1000000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () async {
              final b = double.tryParse(budgetCtrl.text.trim()) ?? 1000000;
              Navigator.pop(ctx);
              try {
                final res = await ref
                    .read(xonadoshRepositoryProvider)
                    .joinSquad(squadId: squad.id, memberBudgetUzs: b);
                if (context.mounted) {
                  ref.invalidate(xonadoshSquadsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res['message']?.toString() ?? 'Jamoaga qo‘shildingiz!',
                      ),
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
            child: const Text('Qo‘shilish'),
          ),
        ],
      ),
    );
  }
}
