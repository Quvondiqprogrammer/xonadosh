/// Pure Dart roommate matching weights (mirrors PHP `xonadosh_match.php`).
class MatchingProfileInput {
  const MatchingProfileInput({
    required this.sleepSchedule,
    required this.cleanliness,
    required this.studyHabit,
    required this.smokingHabit,
    required this.budgetMin,
    required this.budgetMax,
    this.universityId,
  });

  final String sleepSchedule;
  final String cleanliness;
  final String studyHabit;
  final String smokingHabit;
  final double budgetMin;
  final double budgetMax;
  final int? universityId;
}

class MatchingScoreResult {
  const MatchingScoreResult({
    required this.rawScore,
    required this.percentage,
    required this.reasons,
  });

  final int rawScore;
  final int percentage;
  final List<String> reasons;
}

class MatchingScore {
  MatchingScore._();

  /// Returns clamped percentage (50–99) and reason keys.
  static MatchingScoreResult score({
    required MatchingProfileInput me,
    required MatchingProfileInput other,
  }) {
    var score = 0;
    final reasons = <String>[];

    // 1. Sleep (20)
    if (me.sleepSchedule == other.sleepSchedule) {
      score += 20;
      reasons.add(switch (me.sleepSchedule) {
        'early_bird' => 'sleep_early',
        'night_owl' => 'sleep_night',
        _ => 'sleep_flex',
      });
    } else if (me.sleepSchedule == 'flexible' ||
        other.sleepSchedule == 'flexible') {
      score += 15;
    } else {
      score += 5;
    }

    // 2. Cleanliness (20)
    if (me.cleanliness == other.cleanliness) {
      score += 20;
      reasons.add(me.cleanliness == 'strict' ? 'clean_strict' : 'clean_mod');
    } else if (me.cleanliness == 'moderate' || other.cleanliness == 'moderate') {
      score += 15;
    } else {
      score += 5;
    }

    // 3. Study (20)
    if (me.studyHabit == other.studyHabit) {
      score += 20;
      reasons.add(switch (me.studyHabit) {
        'silent' => 'study_silent',
        'music' => 'study_music',
        _ => 'study_group',
      });
    } else if (me.studyHabit == 'flexible' || other.studyHabit == 'flexible') {
      score += 16;
    } else {
      score += 8;
    }

    // 4. Budget overlap (20)
    final overlapMin =
        me.budgetMin > other.budgetMin ? me.budgetMin : other.budgetMin;
    final overlapMax =
        me.budgetMax < other.budgetMax ? me.budgetMax : other.budgetMax;
    if (overlapMin <= overlapMax) {
      score += 20;
      reasons.add('budget_exact');
    } else {
      final diff = (overlapMin - overlapMax).abs();
      score += diff <= 300000 ? 10 : 2;
    }

    // 5. Smoking (10)
    if (me.smokingHabit == other.smokingHabit) {
      score += 10;
      if (me.smokingHabit == 'no') reasons.add('no_smoking');
    }

    // 6. University (10)
    final myUni = me.universityId ?? 0;
    final otherUni = other.universityId ?? 0;
    if (myUni > 0 && myUni == otherUni) {
      score += 10;
      reasons.add('same_uni');
    }

    final percentage = score.clamp(50, 99);
    return MatchingScoreResult(
      rawScore: score,
      percentage: percentage,
      reasons: reasons,
    );
  }
}
