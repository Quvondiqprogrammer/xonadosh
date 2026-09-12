# App Store Review — Guideline 2.1 Response

**App:** XonaDosh (iOS 1.0.0 build 3)  
**Submission ID:** adcb0aaa-1d9a-4b2d-8c58-6d8882f1f578  
**Use:** Paste sections below into **App Store Connect → App Review Information → Notes** and/or **Reply to App Review**.

---

## Copy-paste reply (English)

```
Thank you for reviewing XonaDosh. Please find the requested information below.

1) SCREEN RECORDING
We have attached a screen recording captured on a physical iPhone running iOS 26. The video starts from a cold launch and demonstrates:
- Login with the demo account (see item 4)
- Housing feed, filters, listing detail, map view, and location permission (When In Use)
- Commute estimate to university on a listing
- Roommate matching: profile, compatibility scores, contact options
- Coliving tools: chores, meal plan, grocery estimate, shared finances, anonymous polls, karma/reputation
- Create listing flow including photo library / camera permission
- Settings: language (Uzbek/Russian/English), theme, Privacy Policy & Terms links
- Account deletion flow (Settings → Delete account — password confirmation; demo account is NOT deleted in the video)

The app does NOT include in-app purchases, subscriptions, or paid content. There is no App Tracking Transparency prompt because we do not track users across other companies’ apps or websites.

2) DEVICES & OS TESTED
- iPhone (physical device, wireless debugging) — iOS 26.x
- iPhone Simulator — iOS 18.x (development)
- Additional manual testing on Android (same codebase; not part of this iOS submission)

3) APP PURPOSE & TARGET AUDIENCE
XonaDosh is a lifestyle app for university students in Uzbekistan. It helps students:
- Find shared housing and rooms near universities
- Match with compatible roommates based on budget, schedule, habits, and university
- Manage shared living: chore rotation, weekly meal planning, grocery cost estimates, rent/debt tracking, anonymous house polls, and roommate karma/reputation

Problem solved: Students struggle to find affordable housing near campus and compatible roommates; shared flats lack simple tools for chores and expenses. XonaDosh combines housing discovery, roommate matching, and coliving utilities in one app.

Target audience: University students aged 17+ in Uzbekistan (primarily Tashkent and other cities with listed universities).

4) SETUP & DEMO CREDENTIALS
No special setup is required. Internet connection is required.

Demo account (pre-populated with sample data):
- Username: xdshot5122
- Password: ShotTest123!

Steps after login:
1. Bottom navigation — “Uy-joy” tab: browse listings, open map, tap a listing for details
2. “Xonadosh” tab: view/edit roommate profile and see match suggestions
3. “Birga yashash” tab: chores, meals, grocery, finances, polls, karma (group code is preconfigured for the demo user)
4. “+” or create listing: add a housing ad (optional in review)
5. Settings (gear icon): language, theme, Privacy/Terms, logout, delete account

Registration: Available from the login screen (“Ro‘yxatdan o‘tish” / Register) — requires full name, username, phone, password (minimum 8 characters).

5) EXTERNAL SERVICES & PLATFORMS
Core functionality is delivered through our own backend:
- API & website: https://honadosh.uz/ (PHP + MySQL, hosted in EU)
- Authentication: custom token-based sessions (no third-party login providers)

Third-party components used for non-core features:
- OpenStreetMap map tiles (via flutter_map) — display listing locations only; no data sent to OSM beyond standard tile requests
- Device location (Apple Core Location) — nearby listings and commute distance; used only while the app is in use
- Camera / Photo Library — optional photos when creating housing listings
- Phone dialer & Telegram — url_launcher opens the system phone app or Telegram for contacting listing owners (user-initiated)

We do NOT use: payment processors, auto-renewable subscriptions, advertising SDKs, analytics/tracking SDKs, AI/ML APIs, or third-party authentication (Google/Apple Sign-In).

6) REGIONAL DIFFERENCES
The app functions consistently in all regions where it is available. Content (listings, universities) is focused on Uzbekistan. UI supports Uzbek, Russian, and English via in-app language settings. No feature flags or geo-restrictions beyond App Store regional availability.

7) REGULATED INDUSTRY / THIRD-PARTY MATERIAL
XonaDosh is not in a highly regulated industry (not medical, financial trading, or gambling). We do not stream third-party copyrighted content. User-generated content is limited to housing listings and roommate profiles submitted by registered users. Users can report inappropriate listings or profiles via the in-app Report button (flag icon on listing detail; Report button on roommate profile sheet). Reports are stored in our moderation queue and reviewed within 24 hours at https://honadosh.uz/admin. Reported users may be blocked by moderators. Listings and profiles are also proactively moderated through our admin panel.

Privacy Policy: https://honadosh.uz/privacy/
Terms of Use: https://honadosh.uz/terms/

Please contact us if you need any additional information. Thank you.
```

---

## Screen recording checklist (~3–5 minutes)

Record on **physical iPhone**, latest iOS, portrait, **no personal notifications** (Focus mode recommended).

| Step | What to show |
|------|----------------|
| 1 | Cold start → splash → login screen |
| 2 | Login: `xdshot5122` / `ShotTest123!` |
| 3 | Housing tab → scroll feed → open one listing → show price, map, commute |
| 4 | Tap map icon → **Allow Location** when prompted → show markers |
| 5 | Xonadosh tab → profile + match list → open profile → tap **Report** |
| 6 | Birga yashash → chores → meals → grocery → finances → polls → karma |
| 7 | Create listing → pick photo → **Allow Photos/Camera** if prompted (cancel save to avoid junk data) |
| 8 | Settings → switch language → open Privacy Policy link |
| 9 | Settings → Delete account dialog → enter password → **Cancel** or use throwaway account (do NOT delete demo user) |
| 10 | (Optional) Logout → Register screen → back to login |

**Export:** `.mp4` or `.mov`, attach in Resolution Center reply (or unlisted link).

---

## App Store Connect fields to update

1. **App Review Information → Sign-in required:** Yes  
2. **Username:** `xdshot5122`  
3. **Password:** `ShotTest123!`  
4. **Notes:** paste full block from section 1 above (keep credentials in Notes too)  
5. **Contact:** your phone + email  
6. Attach screen recording to **Reply to App Review**

Then click **Resubmit to App Review** after uploading **build 3** (includes in-app Report feature) or attach screen recording + notes only if resubmitting build 2 unchanged.

---

## Optional improvement before resubmit

~~Apple asked about **UGC reporting/blocking**. Backend API exists (`api/report.php`) but the iOS UI does not yet expose “Report listing/profile”.~~ **Done:** Report button added on listing detail (flag icon) and roommate profile sheet. Rebuild iOS (build 3) before resubmit if you ship this change.
