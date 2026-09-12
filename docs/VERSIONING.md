# Versioning

`pubspec.yaml` `version` is `MARKETING+BUILD` and is the single source of truth
for iOS (`CFBundleShortVersionString` / `CFBundleVersion`) and Android
(`versionName` / `versionCode`).

## Current choice: `1.0.1+4`

| Field | Value | Why |
|-------|-------|-----|
| Marketing (`1.0.1`) | Next App Store / Play version after the build already in review | App Store Review notes document **iOS 1.0.0 (build 3)**. This repo’s initial commit still had leftover `12.8.6+69253` from another project (Zargo / Hamyon). |
| Build (`4`) | Must be an integer greater than the last uploaded build | Apple rejects a lower or reused `CFBundleVersion`. Play `versionCode` must also increase. |

Use **1.0.1+4** for the **next** store upload after the current “Waiting for Review” binary (or after it is rejected / expired).

## If you need to replace the waiting 1.0.0 build

If App Store Connect still has **1.0.0 (3)** in review and you want to *replace* that binary rather than ship a new marketing version:

1. Set `version: 1.0.0+4` (same marketing version, higher build).
2. Upload, then attach it to the existing 1.0.0 submission.

Do **not** ship `12.8.6+69253`. Apple would show “12.8.6” to users, and a later drop to `1.0.x` is a version downgrade.

## If Connect already lists 12.8.6 (69253)

Then this repo’s leftover number *was* uploaded. In that case **do not use 1.0.1+4** — bump from the live values instead, e.g. `12.8.7+69254`. Check App Store Connect → App → iOS build list before archiving.

## After each store upload

1. Increment the `+BUILD` integer (never reuse).
2. Increment marketing (`1.0.2`, `1.1.0`, …) when the change is user-visible.
3. Keep `lib/config/app_config.dart` `appVersion` in sync with the marketing version (Settings footer).
