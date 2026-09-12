# Store metadata drafts

## App name

- **uz:** XonaDosh
- **ru:** XonaDosh
- **en:** XonaDosh

## Subtitle / short description

- **uz:** Talabalar uchun uy-joy, xonadosh va birga yashash
- **ru:** Жильё и подбор соседа для студентов
- **en:** Housing & roommate matching for students

## Full description (en)

XonaDosh helps students in Uzbekistan find rooms, match with compatible roommates, and manage shared living — chores, meal plans, and grocery estimates. Browse listings on a map, estimate commute to university, and contact owners via phone or Telegram.

## Full description (uz)

XonaDosh O‘zbekistondagi talabalarga uy-joy topish, mos xonadosh tanlash va birga yashashni boshqarishda yordam beradi — navbatchilik, ovqat menyusi va bozorlik hisobi. Xaritada e’lonlar, OTMgacha yo‘l hisobi, telefon yoki Telegram orqali bog‘lanish.

## Full description (ru)

XonaDosh помогает студентам в Узбекистане найти жильё, подобрать совместимого соседа и вести совместный быт — дежурства, меню и список покупок. Карта объявлений, расчёт дороги до вуза, связь по телефону или Telegram.

## Keywords

housing, roommate, students, Tashkent, Uzbekistan, coliving, university

## Privacy / Terms

- https://honadosh.uz/privacy/
- https://honadosh.uz/terms/

## Category

Lifestyle / Social

## Version shown to stores

`1.0.1` (build `4`). See [VERSIONING.md](VERSIONING.md).

## Permissions (justifications)

| Platform | Permission | When asked | Why |
|----------|------------|------------|-----|
| iOS / Android | Location (When In Use) | Map / “Use my location” on create listing | Nearby housing markers and commute estimate to a university. Never background. |
| iOS / Android | Camera | Create listing → Take photo | Optional photo for the ad the user is composing. |
| iOS / Android | Photo library / images | Create listing → From gallery | Attach a user-selected photo to a listing. App does not scan the library. |

No ATT / tracking. Account deletion: Settings → Delete account (password + confirm). UGC: Report + Block on listings and roommate profiles.

## Privacy Nutrition (iOS)

`ios/Runner/PrivacyInfo.xcprivacy` declares collected types used for app functionality only (name, user ID, phone, precise location, photos, other user content). Tracking is `false`.
