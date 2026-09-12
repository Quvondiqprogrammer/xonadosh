#!/usr/bin/env bash
# Full App Store screenshot pipeline (1242×2688 via iPhone 11 Pro Max).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE_ID="${DEVICE_ID:-5A7F8C1D-FF27-45BA-828A-EA1CBB28CA76}"
OUT="$ROOT/dist/appstore_screenshots"
PORT="${SHOT_PORT:-8765}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png 2>/dev/null || true

echo "→ Boot $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
open -a Simulator
sleep 2

xcrun simctl status_bar "$DEVICE_ID" override \
  --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100 || true

xcrun simctl uninstall "$DEVICE_ID" uz.xonadosh.app 2>/dev/null || true

# Host IP reachable from Simulator (shared network stack → 127.0.0.1 usually works)
SHOT_HOST="${SHOT_HOST:-127.0.0.1}"

echo "→ Start screenshot server :$PORT"
python3 "$ROOT/scripts/screenshot_server.py" &
SPID=$!
export DEVICE_ID
# server reads DEVICE_ID from env — restart with env
kill "$SPID" 2>/dev/null || true
DEVICE_ID="$DEVICE_ID" SHOT_PORT="$PORT" python3 "$ROOT/scripts/screenshot_server.py" &
SPID=$!
sleep 1
curl -sf "http://127.0.0.1:$PORT/health" >/dev/null

cleanup() { kill "$SPID" 2>/dev/null || true; }
trap cleanup EXIT

echo "→ Run integration test"
SHOT_USER="${SHOT_USER:-xdshot5122}"
SHOT_PASS="${SHOT_PASS:-ShotTest123!}"

flutter test "$ROOT/integration_test/app_store_screenshots_test.dart" \
  -d "$DEVICE_ID" \
  --dart-define="SHOT_USER=$SHOT_USER" \
  --dart-define="SHOT_PASS=$SHOT_PASS" \
  --dart-define="SHOT_HOST=$SHOT_HOST" \
  --dart-define="SHOT_PORT=$PORT"

echo "→ Results"
ls -lh "$OUT"
for f in "$OUT"/*.png; do
  [[ -f "$f" ]] || continue
  echo -n "$(basename "$f"): "
  sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | awk '/pixelWidth|pixelHeight/{printf $2" "}END{print ""}'
done
echo "✓ App Store screenshots: $OUT"
