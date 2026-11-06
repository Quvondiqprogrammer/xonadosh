import 'package:flutter/material.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/domain/matching_score.dart';
import 'package:xonadosh/l10n/app_localizations.dart';

String localizeMatchReason(AppLocalizations l10n, String key, {String? uni}) {
  return switch (key) {
    'sleep_early' => l10n.xonadoshMatchSleepEarly,
    'sleep_night' => l10n.xonadoshMatchSleepNight,
    'sleep_flex' => l10n.xonadoshMatchSleepFlex,
    'clean_strict' => l10n.xonadoshMatchCleanStrict,
    'clean_mod' => l10n.xonadoshMatchCleanMod,
    'study_silent' => l10n.xonadoshMatchStudySilent,
    'study_group' => l10n.xonadoshMatchStudyGroup,
    'study_music' => l10n.xonadoshMatchStudyMusic,
    'budget_exact' => l10n.xonadoshMatchBudgetExact,
    'no_smoking' => l10n.xonadoshMatchNoSmoking,
    'same_uni' => l10n.xonadoshMatchSameUni(uni ?? l10n.xonadoshUniFallback),
    _ => key,
  };
}

MatchingProfileInput matchingInputFromProfile(XonadoshProfile p) {
  return MatchingProfileInput(
    sleepSchedule: p.sleepSchedule,
    cleanliness: p.cleanliness,
    studyHabit: p.studyHabit,
    smokingHabit: p.smokingHabit,
    budgetMin: p.budgetMin,
    budgetMax: p.budgetMax,
    universityId: p.universityId,
  );
}

/// API already returns localized strings; fall back to local score keys.
List<String> visibleMatchReasons({
  required XonadoshProfile candidate,
  required AppLocalizations l10n,
  XonadoshProfile? me,
  int limit = 3,
}) {
  if (candidate.matchReasons.isNotEmpty) {
    return candidate.matchReasons.take(limit).toList();
  }
  if (me == null) return const [];
  final result = MatchingScore.score(
    me: matchingInputFromProfile(me),
    other: matchingInputFromProfile(candidate),
  );
  return result.reasons
      .map((k) => localizeMatchReason(l10n, k, uni: candidate.universityShort))
      .take(limit)
      .toList();
}

class VisualMatchBadge {
  final IconData icon;
  final String label;
  final Color color;

  const VisualMatchBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
}

List<VisualMatchBadge> visibleVisualMatchBadges({
  required XonadoshProfile candidate,
  required AppLocalizations l10n,
  XonadoshProfile? me,
  int limit = 4,
}) {
  final rawReasons = visibleMatchReasons(
    candidate: candidate,
    l10n: l10n,
    me: me,
    limit: limit,
  );

  return rawReasons.map((reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('tozalik') ||
        lower.contains('clean') ||
        lower.contains('ozod')) {
      return const VisualMatchBadge(
        icon: Icons.cleaning_services_rounded,
        label: 'Ozodalik mos',
        color: Color(0xFF0D9488),
      );
    }
    if (lower.contains('dars') ||
        lower.contains('sokin') ||
        lower.contains('study') ||
        lower.contains('tinch')) {
      return const VisualMatchBadge(
        icon: Icons.menu_book_rounded,
        label: 'Sokin muhit',
        color: Color(0xFF0284C7),
      );
    }
    if (lower.contains('byudjet') ||
        lower.contains('budget') ||
        lower.contains('ijara')) {
      return const VisualMatchBadge(
        icon: Icons.payments_rounded,
        label: 'Byudjet mos',
        color: Color(0xFFF59E0B),
      );
    }
    if (lower.contains('otm') ||
        lower.contains('universitet') ||
        lower.contains('uni')) {
      return const VisualMatchBadge(
        icon: Icons.school_rounded,
        label: 'OTM mos',
        color: Color(0xFF6366F1),
      );
    }
    if (lower.contains('uyqu') ||
        lower.contains('sleep') ||
        lower.contains('ertalab') ||
        lower.contains('boyqush')) {
      return const VisualMatchBadge(
        icon: Icons.bedtime_rounded,
        label: 'Rejim mos',
        color: Color(0xFF8B5CF6),
      );
    }
    if (lower.contains('chekmay') || lower.contains('smoke')) {
      return const VisualMatchBadge(
        icon: Icons.smoke_free_rounded,
        label: 'Tutunsiz',
        color: Color(0xFF10B981),
      );
    }
    return VisualMatchBadge(
      icon: Icons.check_circle_rounded,
      label: reason.length > 20 ? '${reason.substring(0, 18)}...' : reason,
      color: const Color(0xFF0D9488),
    );
  }).toList();
}
