# XONADOSH — PRODUCT REQUIREMENTS DOCUMENT (PRD)
**Version:** 2.0 Production  
**Status:** Approved & Baselined  
**Author:** Principal Product Architect & Engineering Team  
**Target Market:** Uzbekistan (Tashkent, Samarkand, Bukhara, Fergana Valley, regional centers)  

---

## 1. Product Vision & Positioning

### 1.1 Vision Statement
XonaDosh is Uzbekistan's premier Smart Co-Living, Rental Marketplace, and Household Management Ecosystem. It moves beyond passive rental notice boards to provide an end-to-end digital lifecycle: from discovering verified accommodation and algorithmic roommate matching, to managing daily living routines, fair chore rotation, transparent shared finances, and meal planning in a shared apartment.

**Slogan:** *Find Your Home. Find Your People. Live Smarter.*  
*(O'zingga mos uy. O'zingga mos odamlar. Aqlli hayot.)*

### 1.2 Target Personas
1. **University Students (Talabalar):**  
   Students migrating to Tashkent and regional universities. Need affordable rooms near campuses, verified roommates with compatible sleep/study habits, fair split of utilities, and predictable grocery budgets.
2. **Young Working Professionals (Yosh Mutaxassislar):**  
   IT specialists, teachers, service workers sharing modern apartments. Require quiet working hours, reliable internet, automated chore rotas, and frictionless expense settlement.
3. **Verified Landlords (Haqiqiy Uy Egalari):**  
   Apartment owners who want reliable, vetted tenants without paying hefty broker commissions or dealing with irresponsible subletting.
4. **Coliving Squads (Birgalikda Ijara Oluvchilar):**  
   Groups of 2–4 individuals who join forces to rent entire multi-room apartments at wholesale rates.

---

## 2. Functional Requirements by Module

### 2.1 Authentication & User Management
- **Phone Number Authentication:** Primary identifier using Uzbekistan MSISDN format (`+998 XX XXX-XX-XX`) with safe parsing and international fallback (`phone_countries.dart`).
- **OAuth Providers:** Google Sign-In and Apple Sign-In with transparent identity linking (`auth_google.php`, `auth_apple.php`).
- **18+ Age Verification:** Mandatory age confirmation before participating in rental marketplace or roommate discovery.
- **Student Verification (HEMIS):** Integration adapter validating official student status via Higher Education Ministry HEMIS system (`verify_hemis.php`), granting a verified student badge.
- **Account Lifecycles:** Session revocation (`auth_logout.php`), refresh token rotation (`auth_refresh.php`), and permanent self-service account deletion conforming strictly with Apple App Store Guideline 5.1.1(v) (`account_delete.php`).

### 2.2 Rental Marketplace
- **Listing Types:**
  - Entire Apartment (`house`, `apartment`)
  - Private Room (`room`)
  - Shared Room / Bed Space (`shared_room`, `bed_space`)
  - Looking for Room / Looking for Roommate
  - Rent Together (Coliving Squads)
- **Step-by-Step Creation Wizard:**
  1. Category & Property Type
  2. Geographic Location (City, District, Mahalla, Map Pin)
  3. Capacity & Layout (Rooms, Available Beds, Bathrooms)
  4. Pricing & Deposit (Monthly Rent, Estimated Utilities, Security Deposit)
  5. House Rules & Amenities (WiFi, Air Conditioning, Washing Machine, Heating, Balcony)
  6. Photos (WebP compressed, max 10MB)
  7. Verification & Contact Preferences
- **Commute & Proximity Engine:**
  - Integrated with 30+ Uzbekistan universities (NUUz, TUIT, Westminster, INHA, MDIST, TDIU, TMA, etc.).
  - Calculates walking distance (meters/minutes) and metro travel time.
- **Dynamic 72-Hour TTL & Anti-Broker Crowd-Moderation:**
  - Listings automatically decay after 72 hours unless refreshed with a 1-tap "Still Available" button (`xonadosh_listing_renew.php`).
  - One-tap post-call broker reporting (`xonadosh_report_broker.php`). 3 distinct reports trigger automatic review quarantine.

### 2.3 Smart Roommate Matching
- **Lifestyle & Preferences Questionnaire:**
  - Monthly budget range (UZS)
  - Preferred universities & administrative districts
  - Sleep habits (Early bird / Night owl / Flexible)
  - Study & noise preferences (Silent / Moderate / Music-friendly)
  - Cleanliness habits (High / Moderate / Relaxed)
  - Cooking habits (Cooks daily / Occasional / Ordering out)
  - Guest policy (Rare / On weekends / Any time)
  - Smoking & pet tolerance
- **Weighted Compatibility Algorithm (0–100 Scale):**
  - Budget Compatibility: 25%
  - Lifestyle & Habits: 25%
  - Geographic Proximity: 15%
  - Move-in Horizon: 10%
  - Cleanliness Standards: 10%
  - Daily Routine: 10%
  - Household Expectations: 5%
- **Explainable Matching (Why You Match):**
  - Generates clear bullet points highlighting alignment and key conversation starters.
- **Interaction Modes:**
  - Tinder-style swipe cards with gesture controls (`tinder_roommate_deck.dart`).
  - Fast-scroll list view with instant filter chips.

### 2.4 Household Management (Virtual Co-Living)
- **Group Code & Invitations:** Every household possesses a unique invite token (`join.php?code=...`) allowing roommates to join in one tap.
- **Digital House Code (Raqamli Xonadoshlik Bitimi):** 5-rule social contract signed digitally by all members (`xonadosh_house_rules.php`).
- **Dashboard Overview:** Real-time visibility into shared treasury balance, upcoming rent dates, unassigned chores, and tonight's dinner.

### 2.5 Smart Shared Finance
- **Splitwise-Style Expense Ledger:**
  - Categories: Groceries, Utilities (Gas, Water, Electricity, Internet), Rent, Maintenance.
  - Split algorithms: Equal split, custom shares, individual exclusion.
- **Settlement Engine:**
  - Calculates net balances ("Who owes whom how much") minimizing multi-party debt cycles.
  - Real integer UZS storage to avoid floating-point rounding errors.
- **1-Tap Telegram Export:**
  - Formatted text summary ready to post into household Telegram groups with receipt tallies.
- **Non-Custodial Compliance:**
  - XonaDosh does not operate as an escrow or payment gateway; it provides an immutable accounting ledger and audit log.

### 2.6 Smart Chores & Duty Scheduler
- **Duty Categories:** Cooking, Kitchen cleaning, Bathroom sanitization, Trash disposal, Living room maintenance.
- **Fair Rotation Algorithm:** Automatically assigns weekly duties balancing previous task completion records and difficulty scores.
- **Task Swapping & Proof:** Members can request peer swaps or mark tasks completed with optional photo proof.
- **Gamified Karma Leaderboard:** Completing duties on time earns Karma points (`xonadosh_karma.php`), fostering positive social accountability.

### 2.7 Smart Meal Planner & Uzbek Recipe Catalog
- **Integrated Recipe Engine:**
  - Curated database of 25+ classic Uzbek national dishes (Palov/Osh, Manti, Lag'mon, Mastava, Sho'rva, Dimlama, Norin, Somsa) plus quick, budget student meals (Tuxum qovurma, Makaron palov, Grechka).
  - Scalable ingredient quantities based on household roommate count (2–8 people).
- **Weekly & Monthly Meal Calendar:**
  - Day-by-day scheduling for Breakfast, Lunch, and Dinner.
  - Democratic voting on weekly menu options (`xonadosh_polls.php`).

### 2.8 Smart Shopping & Grocery Management
- **Automatic Grocery Aggregator:**
  - Extracts all ingredients from the weekly meal plan.
  - Normalizes measurement units (kg, grams, liters, pieces, bundles).
  - Deducts items currently available in the household pantry.
  - Generates an actionable grocery shopping checklist with estimated Tashkent market prices (`xonadosh_market_prices`).

### 2.9 In-App Communications & Notifications
- **Private In-App Chat:**
  - 1-to-1 secure messaging between prospective roommates, listing owners, and squad members (`chat_send.php`, `chat_messages.php`).
- **Contextual Notifications:**
  - Upcoming rent deadlines (3 days prior, 1 day prior).
  - Assigned chore reminders.
  - Grocery list assignment alerts.

### 2.10 Super Admin Dashboard
- **Security Gatekeeper:** Password-protected admin gateway with CSRF tokens and rate limiting.
- **Listing Moderation:** View pending, active, and reported listings; 1-click approve, ban, or archive.
- **User Management:** Search users by phone/name, view verification status, suspend bad actors.
- **Analytics & Platform Health:** Total active users, daily listing posts, active households, broker report volumes.

---

## 3. Non-Functional & Regulatory Requirements
- **Performance:** API response times < 200ms on shared hosting; Flutter mobile 60/120fps; lazy loading of listing images.
- **Data Privacy & Localization (Uzbekistan O'RQ-1125):** User data processed and hosted in compliance with local legal requirements; zero storage of sensitive biometric/passport scans.
- **Security:** Strict PDO parameterization, input sanitization, HTTPOnly cookies, CORS restrictions, WebP compression preventing image bomb attacks.
- **Accessibility & UX:** High contrast WCAG 2.1 compliance, dark/light theme switching, full support for Uzbek (Latin), Russian, and English.
