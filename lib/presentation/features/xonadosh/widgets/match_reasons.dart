import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/domain/matching_score.dart';
import 'package:xonadosh/l10n/app_localizations.dart';

String localizeMatchReason(
  AppLocalizations l10n,
  String key, {
  String? uni,
}) {
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
