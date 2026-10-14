# 🤖 AI AGENT HANDOFF & PROJECT CONTEXT — XONADOSH (XX)

> **DIQQAT HAR QANDAY AI AGENT VA DASTURCHI UCHUN QAT'IY PROTOKOL:**
> 1. **O'qish Majburiyati:** Ushbu hujjat loyihaning yagona haqiqat manbai (Single Source of Truth) hisoblanadi. Har qanday ish boshlashdan oldin to'liq o'qib chiqing!
> 2. **Yangilash Majburiyati:** Ushbu loyihada biror o'zgarish (kod, API, build, xato tuzatish) qilsangiz, **DARHOL** ushbu faylning tegishli bo'limlariga va pastdagi `Changelog` jadvaliga qayd eting!
> 3. **QAT'IY CHEKLOV (CRITICAL):** Android `applicationId` ni `com.zargo.customer` dan aslo o'zgartirmang! Google Play Store yangilanishi aynan shu id ga bog'langan!

---

## 1. 📌 Loyiha Haqida Umumiy Ma'lumot

- **Loyiha nomi:** XonaDosh (Lokal papka: `xx/`)
- **Versiya:** `1.0.3+69257` (Flutter iOS, Android va Web)
- **Tavsif:** Talabalar va yoshlar uchun uy-joy, xonadosh topish, xonadosh moslash (matching) va birga yashash xarajatlarini bo'lishish mobil platformasi.
- **Platformalar:**
  - Android (Play Store AAB: `applicationId: com.zargo.customer`)
  - iOS (Xcode / TestFlight)
  - Web (`https://honadosh.uz/app/` yoki `./scripts/build_web.sh`)

---

## 2. 🏗 Texnologik Stack va Arxitektura

- **Mobil & Web (Flutter):**
  - Flutter 3.x / Dart.
  - Arxitektura: Clean Architecture qatlamlari (`lib/domain/`, `lib/data/`, `lib/presentation/`).
  - Lokalizatsiya: O'zbek (`uz`), Rus (`ru`), Ingliz (`en`).
  - Maxsus validatsiya: O'zbekiston telefon raqamlari qat'iy tekshiruvi (`lib/domain/uz_phone.dart`) va xalqaro davlatlar tanlovi (`lib/domain/phone_countries.dart`).
- **Backend API (PHP):**
  - `backend/api/auth_login.php`, `backend/api/auth_register.php`.
  - `backend/includes/auth_lib.php`.
  - Web ilova buildi: `backend/app/` (Flutter web static build).
- **Loyiha Tuzilmasi:**
  ```text
  xx/
  ├── lib/
  │   ├── data/api/         # API mijozlari (auth_api_client.dart va b.)
  │   ├── domain/           # Telefon validatsiyasi, qoidalar, entitilar
  │   ├── presentation/     # UI ekranlar (Auth, Match, Room, Profile)
  │   └── l10n/             # .arb ko'p tilli tarjima fayllari
  ├── backend/              # PHP API va Web hosting fayllari
  │   ├── api/              # Kirish, ro'yxatdan o'tish va e'lonlar API
  │   └── app/              # Flutter Web yig'ilgan statik fayllari
  ├── test/                 # Birlik testlari (uz_phone_test.dart)
  └── XonaDosh taqdimot.pptx# Investor va biznes taqdimotlari
  ```

---

## 3. ✅ Bajarilgan Ishlar (Audit va Xatoliklar Tuzatilishi)

1. **Google Play Yangilanish Tayyorgarligi:**
   - Versiya kodi `versionCode: 69254` ga ko'tarilgan (`7f4ce9d`).
   - Android `applicationId: com.zargo.customer` saqlanib, Play Store da mavjud ilovani yangilash imkoniyati ta'minlangan (`97b97c3`).
2. **UX Modernizatsiyasi va Audit:**
   - Foydalanuvchi tajribasi (UX) va dizayn auditlari asosida interfeys yangilangan (`befa413`).
3. **Telefon Validatsiyasi va Davlat Kodlari:**
   - O'zbekiston raqamlari (+998 XX XXX-XX-XX) uchun maxsus xavfsiz validatsiya va testlar yozilgan (`test/domain/uz_phone_test.dart`).
   - Xalqaro country picker sheet qo'shilgan.
4. **Backend Autentifikatsiya Mustahkamlanishi:**
   - `auth_login.php` va `auth_register.php` da xavfsizlik va xatoliklar javoblari yaxshilangan.

---

## 4. 🔄 Hozirgi Holat va Jarayondagi Ishlar

- **Joriy Git Holati:** So'nggi commit: `7f4ce9d chore: bump versionCode to 69254 for Play upgrade`.
- **O'zgarishlar (23 ta fayl):** Telefon validatsiyasi, country picker, auth API client va tarjimalar bo'yicha tuzatishlar hali commit qilinmagan.
- **Jarayondagi topshiriq:**
  - `flutter test` orqali testlarni tekshirish.
  - Uncommitted o'zgarishlarni commit qilish.
  - Google Play Console va App Store ga `1.0.1+69254` versiyani release qilish.

---

## 5. 🚀 Keyingi Qadamlar va Yo'l Xaritasi (Roadmap)

1. **P1 (Zudlik bilan):**
   - O'zgarishlarni commit qilish (`git commit -m "feat(auth): complete uz_phone validation and country picker"`).
   - Release AAB yig'ish (`flutter build appbundle --release`).
   - Play Console ga yangilanish sifatida topshirish.
2. **P2 (O'rta muddat):**
   - Xonadosh qidirish algoritmi (talaba OTMlari, byudjet, qiziqishlar bo'yicha moslash).
   - Real-time chat (Xonadoshlar o'rtasida muloqot).
3. **P3 (Production):**
   - Veb versiyani serverga deploy qilish (`./scripts/build_web.sh`).

---

## 6. ⚠️ Muhim Ogohlantirishlar va Xavfsizlik

- **DIQQAT (Application ID):** Hech qachon `android/app/build.gradle` faylidagi `applicationId` ni o'zgartirmang! Agar o'zgartirilsa, Google Play ilovani yangi ilova deb o'ylaydi va eski foydalanuvchilar yangilay olmaydi.
- **Xavfsizlik:** Backenddagi PHP skriptlarda SQL injection va XSS dan himoya PDO orqali ta'minlangan bo'lishi shart.

---

## 7. 📝 AI Agent Amallar Jurnali (Changelog)

| Sana | Agent / Dasturchi | Bajarilgan Amal / O'zgarish Tavsifi | Holat |
| :--- | :--- | :--- | :--- |
| 2026-09-14 | Antigravity AI | Loyiha to'liq o'rganildi va standart `PROJECT_CONTEXT.md` hujjati yaratildi. | ✅ Bajarildi |
| 2026-10-13 | Antigravity AI | Keng qamrovli audit & bug fix: profil tahrirlash (`looking_for_text`, avatar), xarita tile identifikatori, shell lokalizatsiya tipi, sessiya foydalanuvchi nomi, PHP bo'sh satrlar fallback'lari, e'lon o'chirish moslashuvchanligi, navbatchilik API xavfsizligi va fallback ma'lumotlari. 42 ta test va tahlil 100% toza. | ✅ Bajarildi |
| 2026-10-13 | Antigravity AI | UX/UI Zamonaviy Transformatsiya: E'lon kartalari (XonadoshListingCard) to'liq qayta dizayn qilindi (takroriy badge'lar olib tashlandi, rasm kontrast gradienti, zamonaviy narx va kontakt tugmalari qo'shildi); ortiqcha og'ir bannerlar (XonadoshJobsHero, CampusFit, ColivingTip) ixcham, yig'iladigan (collapsible/dismissible) holatga keltirildi; filtr chiplari mantiqiy tartiblandi; floating dock va kartalar radius 16-18px va yumshoq soyalarga o'tkazildi. | ✅ Bajarildi |
