# Migration: Hamyon shared DB → dedicated XonaDosh

## Before

XonaDosh lived as a feature module inside HamyonAI (`hamyonai` package), calling `hamyon-ai.uz` APIs and sharing the Hamyon user/session tables.

## After

- Standalone Flutter app package `xonadosh`, bundle `uz.xonadosh.app`
- API host `https://honadosh.uz/`
- Dedicated MySQL schema (`xd_users`, `xd_sessions`, `xonadosh_*` tables) seeded via `backend/migrations/xonadosh_init.php`
- No `hamyonai` imports; auth is local to XonaDosh (`auth_*.php`)

## Port checklist

1. Copy feature models/API/UI from Hamyon `lib/.../xonadosh*` → rewrite imports to `package:xonadosh/...`
2. Point Dio `baseUrl` at `honadosh.uz`
3. Replace Hamyon `SessionManager` / `X-Hamyon-User` with Bearer + refresh on dedicated endpoints
4. Remove back-navigation to Hamyon dashboard; shell is app root
5. Deploy `backend/` separately; keep `config.local.php` off git

## Data

Do **not** migrate live Hamyon production rows into XonaDosh unless you run an explicit, reviewed ETL. Fresh seed + new registrations is the default for v1.
