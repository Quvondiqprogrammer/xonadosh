# Test plan

## Automated

- [ ] `flutter test test/domain/matching_score_test.dart`
- [ ] `flutter test test/domain/commute_math_test.dart`
- [ ] `flutter test test/data/api_response_test.dart`
- [ ] `flutter test test/widget/shell_smoke_test.dart`
- [ ] `flutter analyze` (lib + test)

## Auth

- [ ] Register with full_name, username, phone, password (≥8)
- [ ] Login with username or phone
- [ ] Kill app → reopen stays logged in (secure storage)
- [ ] Logout clears session
- [ ] Account delete requires password + confirm; returns to login

## Housing

- [ ] Feed loads; filters city/district/type/gender/uni
- [ ] Pull-to-refresh
- [ ] Detail: phone / Telegram launch
- [ ] Create listing (auth) + delete own
- [ ] Map markers (OSM) + tap → detail
- [ ] Commute calculator UI on detail

## Matching

- [ ] Edit profile; cache survives restart (SharedPreferences)
- [ ] Match list with % and reasons
- [ ] Gender / university filters
- [ ] Tel / t.me launch

## Coliving

- [ ] Chores by weekday; toggle done
- [ ] Meal plan 21 slots; pick/create recipe
- [ ] Grocery calc updates with roommate count

## Settings

- [ ] Language uz/ru/en updates UI
- [ ] Theme light/dark/system
- [ ] Privacy / Terms open https://honadosh.uz/...

## Platform

- [ ] Android: INTERNET + location permissions prompt when needed
- [ ] iOS: location/camera/photos usage strings shown
- [ ] Display name **XonaDosh**
