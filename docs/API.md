# XonaDosh API

Base URL: `https://honadosh.uz/` (HTTPS only). JSON request/response unless noted.

Auth: `Authorization: Bearer <token>` where required.

## Auth

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `api/auth_register.php` | no | `full_name`, `username`, `phone`, `password` |
| POST | `api/auth_login.php` | no | `username` or `phone` + `password` |
| POST | `api/auth_refresh.php` | no | `refresh_token` |
| POST | `api/auth_logout.php` | yes | revoke session |
| GET/POST | `api/auth_me.php` | yes | current user |
| POST | `api/account_delete.php` | yes | `password` + `confirm: "delete"` |

## Housing / commute

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `api/xonadosh_universities_get.php` | optional | `city`, `q` |
| GET | `api/xonadosh_listings_get.php` | optional | filters + `id` for detail |
| POST | `api/xonadosh_listing_create.php` | yes | create listing |
| POST | `api/xonadosh_listing_delete.php` | yes | `listing_id` |
| GET | `api/xonadosh_commute_calc.php` | optional | lat/lng or `listing_id` + `university_id` |

## Matching

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET/POST | `api/xonadosh_profiles.php` | mix | get/save/delete profile |
| GET | `api/xonadosh_match.php` | optional | AI-style weighted matches |

## Coliving

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET/POST | `api/xonadosh_chores.php` | optional | roster + toggle/assign/add |
| GET/POST | `api/xonadosh_recipes.php` | optional | recipes + weekly meal plan |
| GET | `api/xonadosh_grocery_calc.php` | optional | `roommate_count`, `group_code` |

## Misc

| Method | Path | Notes |
|--------|------|-------|
| POST | `api/report.php` | content report |

Success responses typically include `"ok": true`. Errors: `"ok": false`, `"error": "..."`.

The Flutter client treats `ok` as true for `true`, `1`, `"true"`, and `"1"`. HTTP status ≥ 400 is always an error even if the body is HTML. Query parameters that are null or blank are omitted.
