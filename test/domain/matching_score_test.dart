import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/domain/matching_score.dart';

void main() {
  MatchingProfileInput base({
    String sleep = 'early_bird',
    String clean = 'strict',
    String study = 'silent',
    String smoke = 'no',
    double min = 500000,
    double max = 1200000,
    int? uni = 1,
  }) {
    return MatchingProfileInput(
      sleepSchedule: sleep,
      cleanliness: clean,
      studyHabit: study,
      smokingHabit: smoke,
      budgetMin: min,
      budgetMax: max,
      universityId: uni,
    );
  }

  test('perfect match scores high and clamps to 99', () {
    final me = base();
    final other = base();
    final r = MatchingScore.score(me: me, other: other);
    // 20+20+20+20+10+10 = 100 → clamped 99
    expect(r.rawScore, 100);
    expect(r.percentage, 99);
    expect(r.reasons, contains('sleep_early'));
    expect(r.reasons, contains('budget_exact'));
    expect(r.reasons, contains('same_uni'));
    expect(r.reasons, contains('no_smoking'));
  });

  test('flexible sleep gets partial points', () {
    final r = MatchingScore.score(
      me: base(sleep: 'early_bird'),
      other: base(sleep: 'flexible'),
    );
    expect(r.rawScore, greaterThanOrEqualTo(15));
  });

  test('budget near-miss gives 10 points', () {
    final r = MatchingScore.score(
      me: base(min: 500000, max: 800000, sleep: 'night_owl', clean: 'relaxed', study: 'group', smoke: 'yes', uni: null),
      other: base(min: 900000, max: 1200000, sleep: 'early_bird', clean: 'strict', study: 'silent', smoke: 'no', uni: 2),
    );
    // no category exact; budget gap 100k → +10
    expect(r.rawScore, lessThan(50));
    expect(r.percentage, 50); // clamped floor
  });
}
