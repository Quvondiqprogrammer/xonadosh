# XONADOSH — API SPECIFICATION (V1 / PRODUCTION)
**Base URL:** `https://xonadoshim.uz/`  
**API Routing:** `/api/*.php` (and transparently aliased as `/api/v1/*`)  
**Transport:** HTTPS Only (TLS 1.3 / HTTP/2)  
**Standard Response Formats:** JSON (`Content-Type: application/json; charset=utf-8`)  

---

## 1. Global Conventions

### 1.1 Authentication Header
Protected endpoints require standard Bearer token authentication:
```http
Authorization: Bearer <access_token>
```

### 1.2 Success Envelope
```json
{
  "ok": true,
  "data": { ... }
}
```

### 1.3 Error Envelope
```json
{
  "ok": false,
  "error": "Human readable error description in Uzbek/English",
  "code": "VALIDATION_FAILED"
}
```

---

## 2. Authentication & Identity Endpoints

### 2.1 `POST /api/auth_register.php`
Registers a new user account with phone number and password.

**Request Payload:**
```json
{
  "full_name": "Asadbek Karimov",
  "username": "asadbek_k",
  "phone": "+998901234567",
  "password": "SecurePassword123!"
}
```

**Success Response (HTTP 200):**
```json
{
  "ok": true,
  "token": "eyJhbGciOi...",
  "refresh_token": "8f3a9b1c...",
  "user": {
    "id": 142,
    "full_name": "Asadbek Karimov",
    "username": "asadbek_k",
    "phone": "+998901234567",
    "avatar_url": null,
    "created_at": "2026-11-11 12:00:00"
  }
}
```

---

### 2.2 `POST /api/auth_login.php`
Authenticates via username or phone number.

**Request Payload:**
```json
{
  "login": "+998901234567",
  "password": "SecurePassword123!"
}
```

**Success Response (HTTP 200):**
```json
{
  "ok": true,
  "token": "eyJhbGciOi...",
  "refresh_token": "8f3a9b1c...",
  "user": {
    "id": 142,
    "full_name": "Asadbek Karimov",
    "phone": "+998901234567"
  }
}
```

---

### 2.3 `POST /api/account_delete.php` (Protected)
Permits instant, irreversible user account deletion conforming to Apple App Store 5.1.1(v) regulations.

**Request Payload:**
```json
{
  "confirm": "delete",
  "password": "OptionalIfOAuthUser"
}
```

**Success Response (HTTP 200):**
```json
{
  "ok": true,
  "message": "Hisobingiz va barcha ma'lumotlaringiz butunlay o'chirildi."
}
```

---

## 3. Rental Marketplace Endpoints

### 3.1 `GET /api/xonadosh_listings_get.php`
Retrieves listings with multi-dimensional filtering, search, and pagination.

**Query Parameters:**
- `city` (string, optional, default: `Toshkent`)
- `district` (string, optional)
- `type` (enum: `apartment`, `house`, `room`, `shared_room`)
- `min_price` / `max_price` (integer UZS)
- `gender` (enum: `any`, `male`, `female`)
- `verified_only` (1/0)
- `id` (integer, optional — returns single listing detail)

**Success Response:**
```json
{
  "ok": true,
  "listings": [
    {
      "id": 85,
      "title": "Chilonzor 9-mavze, 2 xonali shinam kvartira",
      "type": "room",
      "price_month": 1200000,
      "deposit": 600000,
      "city": "Toshkent",
      "district": "Chilonzor",
      "lat": 41.272145,
      "lng": 69.204512,
      "photos": ["uploads/listings/c8f2a...webp"],
      "amenities": ["wifi", "air_conditioner", "washing_machine"],
      "is_verified_landlord": 1,
      "author_name": "Bobur Rustamov",
      "author_phone": "+998931112233",
      "expires_in_hours": 48
    }
  ]
}
```

---

### 3.2 `POST /api/xonadosh_listing_create.php` (Protected)
Publishes a new listing using multi-attribute parameters.

**Request Payload:**
```json
{
  "title": "Toshkent Davlat Yuridik Universiteti yonida 1 ta xonadosh kerak",
  "description": "Barcha sharoitlar bor, tinch va toza yashaydigan talaba qidiryapmiz.",
  "type": "shared_room",
  "price_month": 900000,
  "deposit": 0,
  "utility_estimate": 100000,
  "city": "Toshkent",
  "district": "Yunusobod",
  "lat": 41.311081,
  "lng": 69.240562,
  "rooms_count": 3,
  "beds_available": 1,
  "gender_preference": "male",
  "photos": ["uploads/listings/a1b2c3.webp"],
  "amenities": ["wifi", "fridge", "desk"]
}
```

---

### 3.3 `POST /api/xonadosh_listing_renew.php` (Protected)
Renews an active listing, refreshing its 72-hour dynamic decay timer.

**Request Payload:**
```json
{
  "listing_id": 85
}
```

---

### 3.4 `POST /api/xonadosh_report_broker.php` (Protected)
Submits a crowd-moderation broker report against suspicious or deceptive listings.

**Request Payload:**
```json
{
  "listing_id": 85,
  "reason": "Ushbu raqam rieltor/makler, 50% komissiya talab qildi"
}
```

---

## 4. Roommate Matching Endpoints

### 4.1 `GET /api/xonadosh_match.php`
Computes candidate compatibility scores (0–100) using weighted multi-factor matching.

**Success Response:**
```json
{
  "ok": true,
  "candidates": [
    {
      "user_id": 92,
      "full_name": "Sardor Alimov",
      "avatar_url": "uploads/avatars/sardor.webp",
      "age": 21,
      "university_name": "TUIT (TATU)",
      "hemis_verified": 1,
      "match_score": 94,
      "match_reasons": [
        "Ikkalangiz ham soat 23:00 dan keyin tinchlikni afzal ko'rasiz",
        "Byudjetingiz 1 000 000 - 1 500 000 so'm oralig'ida to'liq mos",
        "Yunusobod va Chilonzor tumanlari tanlangan"
      ],
      "bio": "Dasturchi talaba, 3-bosqich. Uyda asosan dars va kod yozaman."
    }
  ]
}
```

---

### 4.2 `POST /api/verify_hemis.php` (Protected)
Submits university credentials for official Higher Education HEMIS verification.

**Request Payload:**
```json
{
  "student_id": "3920192841",
  "university_id": 4
}
```

---

## 5. Coliving & Household Endpoints

### 5.1 `GET/POST /api/xonadosh_finances.php` (Protected)
Handles shared expenses, utility splits, and settlement balances.

**Action: `add_expense`**
```json
{
  "group_code": "CHILONZOR42",
  "title": "Bozorlik va yuvish vositalari",
  "category": "grocery",
  "amount_uzs": 240000,
  "split_mode": "equal"
}
```

**Action: `get_summary` Response:**
```json
{
  "ok": true,
  "total_monthly_uzs": 4250000,
  "balances": [
    {
      "user_id": 142,
      "name": "Asadbek",
      "net_balance_uzs": 120000,
      "status": "Olishi kerak"
    },
    {
      "user_id": 92,
      "name": "Sardor",
      "net_balance_uzs": -120000,
      "status": "Qarzdor"
    }
  ]
}
```

---

### 5.2 `GET/POST /api/xonadosh_chores.php` (Protected)
Duty schedule rotation and completion logging.

**Action: `toggle_done`**
```json
{
  "chore_id": 18,
  "is_completed": 1
}
```

---

### 5.3 `GET /api/xonadosh_recipes.php`
Fetches Uzbek national and quick student recipes.

**Success Response:**
```json
{
  "ok": true,
  "recipes": [
    {
      "id": 1,
      "title": "Toshkentcha To'y Oshi",
      "category": "milliy",
      "cook_time_mins": 90,
      "difficulty": "medium",
      "estimated_cost_per_person": 28000,
      "ingredients": [
        {"name": "Devzira/Lazer guruch", "qty": "1", "unit": "kg"},
        {"name": "Mol go'shti", "qty": "1", "unit": "kg"},
        {"name": "Sariq sabzi", "qty": "1", "unit": "kg"},
        {"name": "Paxta/Zaytun yog'i", "qty": "250", "unit": "ml"}
      ]
    }
  ]
}
```

---

### 5.4 `GET /api/xonadosh_grocery_calc.php`
Generates aggregated grocery purchase checklist normalized by roommate count.

**Query Parameters:**
- `group_code=CHILONZOR42`
- `roommate_count=4`

**Success Response:**
```json
{
  "ok": true,
  "items": [
    {"product": "Go'sht (mol)", "total_qty": 3.5, "unit": "kg", "est_price_uzs": 350000},
    {"product": "Sabzi", "total_qty": 4, "unit": "kg", "est_price_uzs": 24000},
    {"product": "Piyoz", "total_qty": 3, "unit": "kg", "est_price_uzs": 12000},
    {"product": "Guruch", "total_qty": 2.5, "unit": "kg", "est_price_uzs": 65000}
  ],
  "total_budget_uzs": 451000
}
```

---

## 6. Real-Time In-App Chat Endpoints

- `POST /api/chat_start.php`: Initialize a chat thread between two users.
- `GET /api/chat_conversations.php`: List user's active conversations.
- `GET /api/chat_messages.php?conversation_id=...`: Retrieve message history.
- `POST /api/chat_send.php`: Send a message.
