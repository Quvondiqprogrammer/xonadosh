import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/l10n/app_localizations_en.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/listing_card.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/match_reasons.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';

void main() {
  test('formats listing money with thousands spaces', () {
    expect(formatListingMoney(2500000), '2 500 000');
    expect(formatListingMoney(900), '900');
  });

  test('formats university distance for student cards', () {
    expect(formatListingDistanceKm(0.04), '<0.1 km');
    expect(formatListingDistanceKm(1.2), '1.2 km');
    expect(formatListingDistanceKm(14.6), '15 km');
  });

  test('uses API match reasons when present', () {
    const candidate = XonadoshProfile(
      id: 1,
      username: 'a',
      fullName: 'A',
      phoneNumber: '1',
      gender: 'male',
      matchReasons: ['Same university', 'Budget overlap'],
    );
    final reasons = visibleMatchReasons(
      candidate: candidate,
      l10n: AppLocalizationsEn(),
    );
    expect(reasons, ['Same university', 'Budget overlap']);
  });

  test('computes local why-match reasons when API list is empty', () {
    const me = XonadoshProfile(
      id: 1,
      username: 'me',
      fullName: 'Me',
      phoneNumber: '1',
      gender: 'male',
      universityId: 3,
      universityShort: 'TATU',
      sleepSchedule: 'early_bird',
      cleanliness: 'strict',
      studyHabit: 'silent',
      smokingHabit: 'no',
      budgetMin: 500000,
      budgetMax: 1200000,
    );
    const other = XonadoshProfile(
      id: 2,
      username: 'you',
      fullName: 'You',
      phoneNumber: '2',
      gender: 'male',
      universityId: 3,
      universityShort: 'TATU',
      sleepSchedule: 'early_bird',
      cleanliness: 'strict',
      studyHabit: 'silent',
      smokingHabit: 'no',
      budgetMin: 600000,
      budgetMax: 1100000,
    );
    final reasons = visibleMatchReasons(
      candidate: other,
      me: me,
      l10n: AppLocalizationsEn(),
      limit: 6,
    );
    expect(reasons, isNotEmpty);
    expect(reasons.join(' '), contains('university'));
    expect(reasons.join(' '), contains('Sleep'));
  });
}
