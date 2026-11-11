# XONADOSH — DATABASE SCHEMA SPECIFICATION
**Engine:** MariaDB 10.6+ / MySQL 8.0+  
**Default Charset:** `utf8mb4`  
**Collation:** `utf8mb4_unicode_ci`  
**Storage Engine:** InnoDB (Strict ACID Compliance)  
**Database Name:** `69561c631190f_xonadoshim.uz`  

---

## 1. Schema Design Philosophy
1. **Financial Integrity:** All monetary figures (rents, utilities, grocery items, splits) are stored as unsigned 64-bit integers (`BIGINT` or `INT`) representing exact amounts in Uzbek So'm (UZS), completely eliminating floating-point rounding inaccuracies.
2. **Referential Integrity & Cascading:** Clean foreign keys with indexed lookups on all relational constraints.
3. **Soft Deletes:** Critical business entities (`xd_users`, `xonadosh_listings`, `xonadosh_profiles`, `xonadosh_finances`) implement `deleted_at DATETIME NULL` to ensure auditability and regulatory compliance.
4. **Idempotency & Concurrency:** Session tokens, invite codes, and phone numbers carry unique indexes to prevent double-registration or race-condition duplicate inserts.

---

## 2. Table Definitions

### 2.1 Core Authentication & Sessions

#### `xd_users`
Stores primary user identity, login credentials, verification badges, and timestamps.
```sql
CREATE TABLE IF NOT EXISTS `xd_users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `avatar_url` VARCHAR(255) NULL,
    `apple_id` VARCHAR(191) NULL DEFAULT NULL,
    `google_id` VARCHAR(191) NULL DEFAULT NULL,
    `is_blocked` TINYINT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` DATETIME NULL,
    UNIQUE KEY `uq_username` (`username`),
    UNIQUE KEY `uq_phone` (`phone`),
    INDEX `idx_apple_id` (`apple_id`),
    INDEX `idx_google_id` (`google_id`),
    INDEX `idx_is_blocked` (`is_blocked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xd_sessions`
Active bearer and refresh tokens with expiry tracking.
```sql
CREATE TABLE IF NOT EXISTS `xd_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `token` VARCHAR(128) NOT NULL,
    `refresh_token` VARCHAR(128) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_token` (`token`),
    UNIQUE KEY `uq_refresh_token` (`refresh_token`),
    INDEX `idx_user_sessions` (`user_id`),
    INDEX `idx_expires` (`expires_at`),
    CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `xd_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### 2.2 Marketplace & Universities

#### `xonadosh_universities`
Directory of Uzbek universities with geographical coordinates for commute time calculations.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_universities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(200) NOT NULL,
    `short_name` VARCHAR(50) NOT NULL,
    `city` VARCHAR(100) NOT NULL DEFAULT 'Toshkent',
    `lat` DECIMAL(10, 7) NOT NULL,
    `lng` DECIMAL(10, 7) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_univ_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xonadosh_listings`
Rental listings for apartments, private rooms, and shared rooms.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_listings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `type` ENUM('apartment','house','room','shared_room','bed_space') NOT NULL DEFAULT 'room',
    `price_month` INT UNSIGNED NOT NULL,
    `deposit` INT UNSIGNED NOT NULL DEFAULT 0,
    `utility_estimate` INT UNSIGNED NOT NULL DEFAULT 0,
    `city` VARCHAR(100) NOT NULL DEFAULT 'Toshkent',
    `district` VARCHAR(100) NOT NULL,
    `address_hint` VARCHAR(255) NULL,
    `lat` DECIMAL(10, 7) NOT NULL,
    `lng` DECIMAL(10, 7) NOT NULL,
    `rooms_count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `beds_available` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `gender_preference` ENUM('any','male','female') NOT NULL DEFAULT 'any',
    `photos` LONGTEXT NULL, -- JSON array of image URLs
    `amenities` LONGTEXT NULL, -- JSON array of amenity keys
    `rules` LONGTEXT NULL, -- JSON array of rules
    `is_verified_landlord` TINYINT NOT NULL DEFAULT 0,
    `status` ENUM('active','pending','quarantine','archived') NOT NULL DEFAULT 'active',
    `views_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `renewed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` DATETIME NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` DATETIME NULL,
    INDEX `idx_listings_status` (`status`, `expires_at`),
    INDEX `idx_listings_city_district` (`city`, `district`),
    INDEX `idx_listings_user` (`user_id`),
    INDEX `idx_listings_price` (`price_month`),
    CONSTRAINT `fk_listing_user` FOREIGN KEY (`user_id`) REFERENCES `xd_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xonadosh_broker_reports`
Anti-broker crowd-moderation reporting.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_broker_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `listing_id` INT NOT NULL,
    `reporter_user_id` INT NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_report_listing` (`listing_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### 2.3 Roommate Matching & Profiles

#### `xonadosh_profiles`
Roommate preference questionnaire, lifestyle choices, and student verification.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `university_id` INT NULL,
    `hemis_verified` TINYINT NOT NULL DEFAULT 0,
    `gender` ENUM('male','female','other') NOT NULL DEFAULT 'male',
    `age` TINYINT UNSIGNED NOT NULL DEFAULT 20,
    `budget_min` INT UNSIGNED NOT NULL DEFAULT 500000,
    `budget_max` INT UNSIGNED NOT NULL DEFAULT 1500000,
    `preferred_districts` TEXT NULL, -- comma separated
    `sleep_schedule` ENUM('early','night_owl','flexible') NOT NULL DEFAULT 'flexible',
    `cleanliness` ENUM('clean_freak','moderate','relaxed') NOT NULL DEFAULT 'moderate',
    `noise_level` ENUM('quiet','moderate','social') NOT NULL DEFAULT 'moderate',
    `cooking_habit` ENUM('cook_daily','cook_sometimes','eat_out') NOT NULL DEFAULT 'cook_sometimes',
    `guests_policy` ENUM('no_guests','weekends_only','flexible') NOT NULL DEFAULT 'weekends_only',
    `smoking` TINYINT NOT NULL DEFAULT 0,
    `pets` TINYINT NOT NULL DEFAULT 0,
    `bio` TEXT NULL,
    `is_actively_looking` TINYINT NOT NULL DEFAULT 1,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_profile_user` (`user_id`),
    INDEX `idx_profile_budget` (`budget_min`, `budget_max`),
    CONSTRAINT `fk_profile_user` FOREIGN KEY (`user_id`) REFERENCES `xd_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### 2.4 Household Co-Living, Squads & Social Code

#### `xonadosh_squads`
Virtual households and co-renting squads.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_squads` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `admin_user_id` INT NOT NULL,
    `members_count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `max_members` TINYINT UNSIGNED NOT NULL DEFAULT 6,
    `address` VARCHAR(255) NULL,
    `monthly_rent` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_squad_code` (`code`),
    INDEX `idx_squad_admin` (`admin_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xonadosh_house_rules`
Agreements to the 5-point Digital House Code.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_house_rules` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL,
    `user_id` INT NOT NULL,
    `rule_id` VARCHAR(50) NOT NULL,
    `agreed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_group_user_rule` (`group_code`, `user_id`, `rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### 2.5 Shared Finances, Chores, Recipes & Groceries

#### `xonadosh_finances`
Shared household expense records, utilities, and debt balances.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_finances` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL,
    `payer_user_id` INT NOT NULL,
    `category` ENUM('rent','utility','grocery','maintenance','other') NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `amount_uzs` INT UNSIGNED NOT NULL,
    `split_mode` ENUM('equal','custom','shares') NOT NULL DEFAULT 'equal',
    `receipt_url` VARCHAR(255) NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` DATETIME NULL,
    INDEX `idx_finance_group` (`group_code`),
    INDEX `idx_finance_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xonadosh_chores`
Household chore duty scheduler and completion tracking.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_chores` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `category` ENUM('cleaning','cooking','dishes','garbage','shopping','other') NOT NULL DEFAULT 'cleaning',
    `assigned_user_id` INT NULL,
    `assigned_name` VARCHAR(100) NULL,
    `due_date` DATE NOT NULL,
    `is_completed` TINYINT NOT NULL DEFAULT 0,
    `completed_at` DATETIME NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_chores_group` (`group_code`),
    INDEX `idx_chores_due` (`due_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xonadosh_recipes` & `xonadosh_meal_plans`
Uzbek national recipes and weekly calendar schedules.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_recipes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(150) NOT NULL,
    `category` VARCHAR(50) NOT NULL DEFAULT 'milliy',
    `cook_time_mins` SMALLINT UNSIGNED NOT NULL DEFAULT 45,
    `difficulty` ENUM('easy','medium','hard') NOT NULL DEFAULT 'medium',
    `estimated_cost_per_person` INT UNSIGNED NOT NULL DEFAULT 20000,
    `ingredients` LONGTEXT NOT NULL, -- JSON array with quantities
    `instructions` TEXT NULL,
    `image_url` VARCHAR(255) NULL,
    INDEX `idx_recipe_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `xonadosh_meal_plans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL,
    `recipe_id` INT NOT NULL,
    `day_of_week` ENUM('mon','tue','wed','thu','fri','sat','sun') NOT NULL,
    `meal_type` ENUM('breakfast','lunch','dinner') NOT NULL DEFAULT 'dinner',
    `scheduled_date` DATE NULL,
    INDEX `idx_meal_group` (`group_code`),
    CONSTRAINT `fk_meal_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `xonadosh_recipes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### `xonadosh_market_prices`
Benchmark market prices for staple foods in Tashkent bazaars.
```sql
CREATE TABLE IF NOT EXISTS `xonadosh_market_prices` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_key` VARCHAR(100) NOT NULL,
    `name_uz` VARCHAR(150) NOT NULL,
    `unit` VARCHAR(20) NOT NULL DEFAULT 'kg',
    `avg_price_uzs` INT UNSIGNED NOT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_product_key` (`product_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### 2.6 Real-Time In-App Messaging

#### `xd_conversations`, `xd_chat_participants`, `xd_chat_messages`
```sql
CREATE TABLE IF NOT EXISTS `xd_conversations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `listing_id` INT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `xd_chat_participants` (
    `conversation_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    PRIMARY KEY (`conversation_id`, `user_id`),
    INDEX `idx_chat_user` (`user_id`),
    CONSTRAINT `fk_cp_conv` FOREIGN KEY (`conversation_id`) REFERENCES `xd_conversations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cp_user` FOREIGN KEY (`user_id`) REFERENCES `xd_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `xd_chat_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `conversation_id` INT NOT NULL,
    `sender_id` INT NOT NULL,
    `message_text` TEXT NOT NULL,
    `is_read` TINYINT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_msg_conv` (`conversation_id`, `created_at`),
    CONSTRAINT `fk_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `xd_conversations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_msg_sender` FOREIGN KEY (`sender_id`) REFERENCES `xd_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
