#!/usr/bin/env bash
# Flutter Web → backend/app (honadosh.uz/app/)
# Yagona kod: Android / iOS / Web bir xil Flutter loyihadan.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ flutter pub get"
flutter pub get

echo "→ launcher icons (web)"
dart run flutter_launcher_icons || true

echo "→ flutter build web --release --base-href /app/"
flutter build web --release --base-href /app/

echo "→ deploy build/web → backend/app"
# Keep API-adjacent assets; replace SPA with Flutter web.
mkdir -p backend/app
# Backup old JS SPA once (if still present and not yet flutter)
if [[ -f backend/app/js/app.js && ! -f backend/app/.flutter_web ]]; then
  mkdir -p backend/app_legacy_spa
  rsync -a --exclude 'app_legacy_spa' backend/app/ backend/app_legacy_spa/ 2>/dev/null || true
fi

rsync -a --delete \
  --exclude '.htaccess' \
  build/web/ backend/app/

# Marker so we know this is Flutter web
touch backend/app/.flutter_web

# SPA fallback for go_router path URLs under /app/
cat > backend/app/.htaccess <<'EOF'
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /app/
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /app/index.html [L]
</IfModule>
EOF

echo "✓ Tayyor: backend/app (https://honadosh.uz/app/)"
echo "  Lokal: flutter run -d chrome"
