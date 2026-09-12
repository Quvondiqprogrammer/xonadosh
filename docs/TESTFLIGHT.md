# TestFlight — XonaDosh

## 1) Build yuklash

So‘nggi IPA: `dist/XonaDosh-1.0.0-3.ipa` (version **1.0.0**, build **3**)

```bash
./scripts/upload_testflight.sh
```

Transporter ochiladi → **Deliver**.

Yoki App-Specific Password bilan:

```bash
export APPLE_ID='quvondiq0318@icloud.com'
export APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'   # appleid.apple.com
./scripts/upload_testflight.sh
```

## 2) App Store Connect (5–30 daqiqa Processing)

1. [TestFlight → iOS](https://appstoreconnect.apple.com/apps/6806811185/testflight/ios)
2. Build **2** paydo bo‘lguncha kuting (Processing → Ready to Test)
3. **Export Compliance**: *Uses encryption? → No / exempt only*  
   (`ITSAppUsesNonExemptEncryption = false` allaqachon Info.plist da)

## 3) Internal Testing (tez, review yo‘q)

1. TestFlight → **Internal Testing**
2. Group yarating yoki App Store Connect Users
3. Build **2** ni qo‘shing
4. Testerlarni (Admin/Developer/Marketing rollari) qo‘shing
5. Telefonda **TestFlight** app → Accept → Install

## 4) External Testing (havola orqali, beta review bor)

1. TestFlight → **External Testing** → yangi guruh
2. Build qo‘shing
3. To‘ldiring:

**Beta App Description**
```
XonaDosh helps students find housing near universities, match roommates, and manage shared living (chores, meals, groceries, rent, polls, karma).
```

**What to Test**
```
Please try: Housing listings + map, Roommate matching, Coliving (chores, menu, grocery, finances, polls, karma), create listing, settings.
```

**Feedback Email** — o‘z emailingiz  

**Privacy Policy** — `https://honadosh.uz/privacy/`

4. **Submit for Review** (beta) → tasdiqdan keyin public link chiqadi

## Demo login (review / testers)

- Username: `xdshot5122`
- Password: `ShotTest123!`
