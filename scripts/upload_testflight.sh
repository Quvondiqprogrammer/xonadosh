#!/usr/bin/env bash
# Upload IPA to App Store Connect (TestFlight / App Store).
#
# Option A — App Store Connect API key (recommended):
#   export ASC_KEY_ID=XXXXXXXXXX
#   export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   export ASC_KEY_PATH=$HOME/private_keys/AuthKey_XXXXXXXXXX.p8
#
# Option B — Apple ID + app-specific password:
#   export APPLE_ID=you@icloud.com
#   export APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
#   (create at https://appleid.apple.com → Sign-In and Security → App-Specific Passwords)
#
# Usage:
#   ./scripts/upload_testflight.sh
#   ./scripts/upload_testflight.sh dist/XonaDosh-1.0.0-2.ipa
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA="${1:-$ROOT/dist/XonaDosh-1.0.0-4.ipa}"

if [[ ! -f "$IPA" ]]; then
  echo "IPA not found: $IPA"
  echo "Build first: flutter build ipa --release --build-name=1.0.0 --build-number=N --export-options-plist=ios/ExportOptions.plist"
  exit 1
fi

echo "→ Uploading $IPA ($(du -h "$IPA" | awk '{print $1}'))"

if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]]; then
  KEY_DIR="$(dirname "$ASC_KEY_PATH")"
  export API_PRIVATE_KEYS_DIR="$KEY_DIR"
  # altool looks for AuthKey_<KEY_ID>.p8 inside API_PRIVATE_KEYS_DIR
  xcrun altool --upload-app --type ios -f "$IPA" \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"
elif [[ -n "${APPLE_ID:-}" && -n "${APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun altool --upload-app --type ios -f "$IPA" \
    --username "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD"
else
  echo "No API credentials in env — opening Transporter UI…"
  open -a Transporter "$IPA"
  echo ""
  echo "Transporter da:"
  echo "  1) Apple ID bilan kiring (quvondiq0318@icloud.com)"
  echo "  2) Deliver bosing"
  echo "  3) App Store Connect → TestFlight → build Processing tugaguncha kuting"
  echo ""
  echo "Avtomatik yuklash uchun:"
  echo "  APPLE_ID=... APP_SPECIFIC_PASSWORD=... ./scripts/upload_testflight.sh"
  echo "yoki ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH"
  exit 0
fi

echo "✓ Upload started. Keyin:"
echo "  https://appstoreconnect.apple.com/apps/6806811185/testflight/ios"
echo "  Build → Export Compliance → TestFlight Internal/External testers"
