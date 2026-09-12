# XonaDosh

Talabalar uchun uy-joy, xonadosh moslash va birga yashash.

**Yagona Flutter kod** — Android, iOS va Web bir xil loyihadan.

| Qurilma | Buyruq / joylashuv |
|---------|---------------------|
| Android | `flutter run` / Play AAB |
| iOS | `flutter run` / Xcode |
| Web | `flutter run -d chrome` yoki `./scripts/build_web.sh` → `https://honadosh.uz/app/` |

## Sozlamalar

| Band | Qiymat |
|------|--------|
| Android application ID | `com.zargo.customer` |
| iOS bundle ID | `uz.xonadosh.app` |
| Package | `xonadosh` |
| API | `https://honadosh.uz/` |
| Brand | Emerald `#10B981` / `#059669` |

## Ishga tushirish

```bash
flutter pub get
flutter gen-l10n

# Mobil
flutter run

# Web (Chrome) — mobil bilan bir xil UI
flutter run -d chrome
```

## Web deploy (server)

```bash
./scripts/build_web.sh
```

Natija: `backend/app/` — Flutter Web build (`honadosh.uz/app/`).
Eski JS SPA birinchi marta `backend/app_legacy_spa/` ga zaxiralanadi.

Backend PHP (`backend/api/`) o‘sha hostda qoladi; Flutter Dio orqali `https://honadosh.uz/api/` ga ulanadi.

## Ilova tuzilishi

- Splash → token → `XonadoshShell` (3 tab); aks holda login/register
- Tablar: Uy-joy · Moslash · Birga yashash (navbat, menyu, bozorlik, moliya, masalalar, karma)
- Desktop web: UI telefon kengligida markazda (mobil bilan bir xil)

## Testlar

```bash
flutter test
```

## Hujjatlar

- [API](docs/API.md)
- [Migration](docs/MIGRATION.md)
- [Store metadata](docs/STORE_METADATA.md)
