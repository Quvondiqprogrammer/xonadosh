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

/// Format match reason string into a concise 2-word chip
String formatCompactMatchReason(String reason) {
  final lower = reason.toLowerCase();
  if (lower.contains('erta') ||
      (lower.contains('uyqu') && lower.contains('erta'))) {
    return 'Erta turuvchi';
  }
  if (lower.contains('kech') ||
      (lower.contains('uyqu') && lower.contains('kech')) ||
      lower.contains('tungi')) {
    return 'Tungi rejim';
  }
  if (lower.contains('uyqu') ||
      lower.contains('rejim') ||
      lower.contains('moslashuvchan')) {
    return 'Mos rejim';
  }
  if (lower.contains('tozalik') || lower.contains('ozod')) {
    return 'Tartibli';
  }
  if (lower.contains('sokin') ||
      lower.contains('tinch') ||
      lower.contains('dars')) {
    return 'Sokin dars';
  }
  if (lower.contains('chekmay') || lower.contains('tutunsiz')) {
    return 'Chekmaydi';
  }
  if (lower.contains('byudjet') || lower.contains('budget')) {
    return 'Byudjet mos';
  }
  if (lower.contains('otm') ||
      lower.contains('universitet') ||
      lower.contains('uni')) {
    return 'Bir xil OTM';
  }
  return reason.length > 18 ? '${reason.substring(0, 16)}...' : reason;
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

  if (rawReasons.isEmpty) {
    final fallbacks = <VisualMatchBadge>[];
    if (candidate.sleepSchedule == 'early_bird') {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.wb_sunny_rounded,
          label: 'Erta turuvchi',
          color: Color(0xFFF59E0B),
        ),
      );
    } else if (candidate.sleepSchedule == 'night_owl') {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.bedtime_rounded,
          label: 'Tungi rejim',
          color: Color(0xFF8B5CF6),
        ),
      );
    } else {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.schedule_rounded,
          label: 'Mos rejim',
          color: Color(0xFF6366F1),
        ),
      );
    }
    if (candidate.smokingHabit == 'no' || candidate.smokingHabit == 'never') {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.smoke_free_rounded,
          label: 'Chekmaydi',
          color: Color(0xFF10B981),
        ),
      );
    }
    if (candidate.cleanliness == 'strict') {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.cleaning_services_rounded,
          label: 'O‘ta ozoda',
          color: Color(0xFF0D9488),
        ),
      );
    } else if (candidate.cleanliness == 'moderate') {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.cleaning_services_rounded,
          label: 'Tartibli',
          color: Color(0xFF0D9488),
        ),
      );
    }
    if (candidate.studyHabit == 'silent') {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.menu_book_rounded,
          label: 'Sokin dars',
          color: Color(0xFF0284C7),
        ),
      );
    }
    if (candidate.budgetMax > 0) {
      fallbacks.add(
        const VisualMatchBadge(
          icon: Icons.payments_rounded,
          label: 'Byudjet mos',
          color: Color(0xFFF59E0B),
        ),
      );
    }
    return fallbacks.take(limit).toList();
  }

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
        label: 'Bir xil OTM',
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
