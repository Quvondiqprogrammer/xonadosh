# XONADOSH — PROJECT AUDIT & TECHNICAL INVENTORY (PHASE 0)
**Date:** 2026-11-11  
**Lead Architect:** Principal Software Architect & QA Engineer  
**Workspace:** `/Users/quvondiq/Desktop/XonaDoshim/XonaDosh`  
**Target Production Domain:** `https://xonadoshim.uz`  
**Hosting Environment:** Linux CloudLinux `sysdc.uz` (MariaDB 10.6.28, PHP 8.4.26, Nginx/LiteSpeed, cPanel/FTP `142.132.250.229:21`)  

---

## 1. Executive Summary

This empirical audit was executed across the existing local codebase, developer machine toolchains, and the live production hosting environment.

XonaDosh is an advanced Smart Co-Living, Rental Marketplace, and Household Management Ecosystem specifically crafted for Uzbekistan (students, young professionals, flatmates, and landlords). It began development as an innovation inside Quvondiq Kenjaboyev's ecosystem and evolved into a dedicated Flutter Mobile/Web application and PHP/MariaDB REST API.

---

## 2. Environment & Toolchain Audit

### 2.1 Local Development Machine (macOS Apple Silicon)
- **PHP CLI:** `8.5.8 (cli)` (`/opt/homebrew/bin/php`) with OPcache and core extensions enabled.
- **Composer:** Available (`/opt/homebrew/bin/composer`).
- **Flutter Framework:** `3.47.5` (channel stable, revision `6a19cca564`).
- **Dart SDK:** `3.13.4` (Tools & DevTools `2.60.0`).
- **Static Analysis:** `flutter analyze` runs clean (0 issues, 0 warnings).
- **Test Suite:** `flutter test` runs 52/52 tests passing (unit, model, domain, and widget tests).
- **PHP Syntax:** All PHP files in `backend/` evaluated with `php -l` — 100% clean without syntax errors.

### 2.2 Live Production Server (`xonadoshim.uz` / `142.132.250.229`)
- **OS Kernel:** `Linux sysdc.uz 4.18.0-553.171.1.lve.el8.x86_64` (CloudLinux / cPanel).
- **Web Server:** Nginx 1.30.4 / LiteSpeed with HTTPS enabled.
- **PHP Version:** `PHP 8.4.26` with full extensions: `pdo_mysql`, `curl`, `mbstring`, `json`, `bcmath`, `fileinfo`, `gd`, `intl`, `sodium`, `zip`, `xml`, `opcache`.
- **Database Engine:** `MariaDB 10.6.28-MariaDB-cll-lve`.
- **Database Name:** `69561c631190f_xonadoshim.uz`.
- **Database User:** `69561c631190f_xonadoshim.uz`.
- **FTP Access:** `142.132.250.229:21` (User: `69561c631190f_xonadoshim`). Chrooted directly to web root (`public_html`).
- **Current Live Web Root State:** Contains attribution and crawler directives (`humans.txt`, `llms.txt`, `llms-full.txt`, `robots.txt`).
- **Current Database Tables:** Contains empty initial tables `users`, `listings`, `households` (0 rows).

---

## 3. Project Structure & Codebase Inventory

```text
XonaDosh/
├── android/                 # Android project (applicationId: com.zargo.customer)
├── ios/                     # iOS native workspace & Podfile
├── web/                     # Flutter Web shell, index.html, manifest.json
├── lib/                     # Flutter source code (Clean Architecture)
│   ├── config/              # AppConfig (API URLs, timeouts)
│   ├── core/                # Core services, utilities, themes
│   ├── data/
│   │   ├── api/             # HTTP clients (Dio, AuthApiClient, XonadoshApiClient)
│   │   ├── models/          # Strongly typed models (Listing, Profile, Chore, Recipe, Finance)
│   │   └── repositories/    # XonadoshRepository, AuthRepository
│   ├── domain/              # Business rules (UzPhone validation, matching algorithm, commute math)
│   ├── presentation/
│   │   ├── auth/            # Phone/OTP login, Google Sign-in button
│   │   ├── features/xonadosh/
│   │   │   ├── screens/     # MapScreen, ListingDetailScreen, CreateListing, ChatScreen, Settings
│   │   │   ├── tabs/        # HousingTab (Marketplace), MatchingTab (Roommates), ColivingTab (Household)
│   │   │   └── widgets/     # TinderRoommateDeck, ListingCard, RecipePicker, ChoresDialog
│   │   ├── providers/       # Riverpod state notifiers & providers
│   │   └── router/          # AppRouter & GoRouter navigation
│   └── l10n/                # Localization (app_uz.arb, app_ru.arb, app_en.arb)
├── backend/                 # PHP Backend
│   ├── api/                 # 36 REST API endpoints
│   ├── includes/            # Bootstrap, PDO database connection, Auth library, XonaDosh helper lib
│   ├── admin/               # Super Admin Panel (auth, moderation, listings, users, statistics)
│   ├── migrations/          # Schema migrations & initial seeders (xonadosh_init.php)
│   ├── uploads/             # Media storage (avatars, listings, receipts)
│   └── index.html           # Landing website with SEO, Schema.org, responsive UI
├── test/                    # 52 unit & widget tests
└── scripts/                 # deploy_ftp.py, build_web.sh, screenshot scripts
```

---

## 4. API Inventory & Contract Audit

The existing backend provides 36 modular PHP endpoints:

| Domain | File | Method | Purpose |
|---|---|---|---|
| **Auth** | `auth_register.php` | POST | User registration with phone / password validation |
| **Auth** | `auth_login.php` | POST | Login with username/phone, password verification, token issue |
| **Auth** | `auth_me.php` | GET/POST | Current authenticated profile retrieval |
| **Auth** | `auth_refresh.php` | POST | JWT / Bearer token refresh rotation |
| **Auth** | `auth_logout.php` | POST | Session termination |
| **Auth** | `auth_google.php` | POST | Google OAuth sign-in adapter |
| **Auth** | `auth_apple.php` | POST | Apple OAuth sign-in adapter |
| **Auth** | `account_delete.php` | POST | Account deletion (Apple App Store Guideline 5.1.1 compliant) |
| **Marketplace** | `xonadosh_listings_get.php` | GET | Listing feed, multi-filter, search, and detail lookup |
| **Marketplace** | `xonadosh_listing_create.php` | POST | Multi-step property listing submission |
| **Marketplace** | `xonadosh_listing_delete.php` | POST | Listing removal with ownership verification |
| **Marketplace** | `xonadosh_listing_renew.php` | POST | 72-hour dynamic TTL renewal |
| **Marketplace** | `xonadosh_report_broker.php` | POST | Crowd-moderation broker reporting & auto-quarantine |
| **Marketplace** | `xonadosh_universities_get.php`| GET | Universities directory for commute calculations |
| **Marketplace** | `xonadosh_commute_calc.php` | GET | Walk/metro commute distance calculation |
| **Marketplace** | `xonadosh_upload.php` | POST | High-performance WebP media upload |
| **Matching** | `xonadosh_profiles.php` | GET/POST | Roommate questionnaire & personal profile |
| **Matching** | `xonadosh_match.php` | GET | Weighted compatibility matching (0-100 score + explainable reasons) |
| **Matching** | `verify_hemis.php` | POST | HEMIS university student verification badge |
| **Coliving/Squad**| `xonadosh_squads.php` | GET/POST | Rent Together squad management |
| **Coliving/Squad**| `xonadosh_house_rules.php` | GET/POST | 5-rule household code agreement |
| **Household** | `xonadosh_chores.php` | GET/POST | Duty rotation, chore assignments & toggle |
| **Household** | `xonadosh_finances.php` | GET/POST | Splitwise-style shared finance, utilities, rent & telegram export |
| **Household** | `xonadosh_recipes.php` | GET/POST | Uzbek national & budget recipes database |
| **Household** | `xonadosh_grocery_calc.php` | GET | Automatic meal planner to grocery list calculator |
| **Household** | `xonadosh_polls.php` | GET/POST | Democratic household voting & polls |
| **Household** | `xonadosh_karma.php` | GET/POST | Household karma & gamified contribution leaderboard |
| **Chat** | `chat_conversations.php` | GET | Conversation threads list |
| **Chat** | `chat_messages.php` | GET | Message history for thread |
| **Chat** | `chat_send.php` | POST | Send real-time in-app message |
| **Chat** | `chat_start.php` | POST | Start conversation with listing owner or roommate match |
| **Admin** | `admin/index.php` | GET | Super Admin dashboard metrics |
| **Admin** | `admin/listings.php` | GET/POST | Listing moderation, approval, reject |
| **Admin** | `admin/users.php` | GET/POST | User management & ban/unban |
| **Admin** | `admin/reports.php` | GET/POST | Dispute & broker report review |

---

## 5. Identified Gaps & Refactoring Directives

1. **Production Configuration Alignment:**  
   `config.local.php` was previously configured for `honadosh.uz`. We must configure it for `xonadoshim.uz` with database credentials `69561c631190f_xonadoshim.uz` and update `scripts/deploy_ftp.py` to target the active FTP credentials.
2. **Database Migration to Remote Production:**  
   The remote MariaDB database currently only has initial empty placeholder tables. We need to deploy and execute `xonadosh_init.php` to seed all 21 tables (`xd_users`, `xd_sessions`, `xonadosh_profiles`, `xonadosh_listings`, `xonadosh_universities`, `xonadosh_recipes`, `xonadosh_chores`, `xonadosh_market_prices`, `xonadosh_finances`, `xd_conversations`, etc.) safely without dropping any tables.
3. **Landing Website & Domain Synchronization:**  
   The web landing page in `backend/index.html` references `honadosh.uz` in various links, meta tags, and structured schema data. We must update the branding, SEO OpenGraph, and URLs to `xonadoshim.uz`.
4. **Enhanced REST API Versioning (`/api/v1/` compatibility):**  
   To fulfill Enterprise Architecture standards while maintaining 100% backward compatibility with mobile builds, we will add an Nginx/.htaccess routing shim so `/api/v1/*` routes transparently to the corresponding API controllers.
5. **Comprehensive Automated Verification:**  
   Empirical testing of end-to-end endpoints via curl, automated test suites, Flutter web builds, and live smoke testing on `https://xonadoshim.uz`.
