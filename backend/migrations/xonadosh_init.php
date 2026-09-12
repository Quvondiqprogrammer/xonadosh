<?php
declare(strict_types=1);
/**
 * XonaDosh Full Migration
 * Creates ALL tables IF NOT EXISTS + seeds universities/recipes/meals/chores/market.
 * Protect: ?key=xonadosh_setup_2026
 */
require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

$lockFile = __DIR__ . '/.setup_done';
if (is_file($lockFile) && ($_GET['force'] ?? '') !== '1') {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'Migration already applied. Pass &force=1 to re-run.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$key = $_GET['key'] ?? '';
if ($key !== 'xonadosh_setup_2026') {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'Forbidden — use ?key=xonadosh_setup_2026'], JSON_UNESCAPED_UNICODE);
    exit;
}

header('Content-Type: application/json; charset=utf-8');
try { $pdo = db_connect($cfg); }
catch (Throwable $e) { echo json_encode(['ok'=>false,'error'=>$e->getMessage()]); exit; }

// --- Auth tables ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xd_users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `avatar_url` VARCHAR(255) NULL,
    `is_blocked` TINYINT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` DATETIME NULL,
    UNIQUE KEY `uq_username` (`username`),
    UNIQUE KEY `uq_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

$pdo->exec("CREATE TABLE IF NOT EXISTS `xd_sessions` (
    `token` CHAR(64) NOT NULL PRIMARY KEY,
    `username` VARCHAR(100) NOT NULL,
    `created_at` BIGINT NOT NULL,
    `expires_at` BIGINT NOT NULL,
    `refresh_token` CHAR(64) NULL,
    `refresh_expires_at` BIGINT NULL,
    INDEX `idx_refresh_token` (`refresh_token`),
    INDEX `idx_username` (`username`),
    INDEX `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

$pdo->exec("CREATE TABLE IF NOT EXISTS `xd_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reporter_username` VARCHAR(100) NOT NULL,
    `target_type` VARCHAR(50) NOT NULL,
    `target_id` VARCHAR(64) NOT NULL,
    `reason` TEXT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_reporter` (`reporter_username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Universities ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_universities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name_uz` VARCHAR(200) NOT NULL UNIQUE,
    `short_name` VARCHAR(50) NOT NULL,
    `city` VARCHAR(100) NOT NULL DEFAULT 'Toshkent',
    `district` VARCHAR(100) NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `latitude` DECIMAL(10,8) NOT NULL,
    `longitude` DECIMAL(11,8) NOT NULL,
    `nearest_metro` VARCHAR(100) NULL,
    `metro_distance_m` INT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Listings (live API column names — NOT legacy listing_type enum) ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_listings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL,
    `username` VARCHAR(100) NOT NULL,
    `owner_name` VARCHAR(150) NOT NULL,
    `phone_number` VARCHAR(30) NOT NULL,
    `telegram_handle` VARCHAR(100) NULL,
    `type` ENUM('rent','roommate_wanted','sell','buy') NOT NULL DEFAULT 'rent',
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `price` DECIMAL(15,2) NOT NULL,
    `currency` VARCHAR(10) NOT NULL DEFAULT 'UZS',
    `price_period` VARCHAR(20) NOT NULL DEFAULT 'month',
    `city` VARCHAR(100) NOT NULL DEFAULT 'Toshkent',
    `district` VARCHAR(100) NULL,
    `address` VARCHAR(255) NULL,
    `latitude` DECIMAL(10,8) NOT NULL,
    `longitude` DECIMAL(11,8) NOT NULL,
    `nearest_university_id` INT NULL,
    `distance_to_university_km` DECIMAL(6,2) NULL,
    `nearest_metro` VARCHAR(100) NULL,
    `rooms_count` INT NOT NULL DEFAULT 2,
    `floor` INT NOT NULL DEFAULT 1,
    `total_floors` INT NOT NULL DEFAULT 4,
    `area_sqm` DECIMAL(8,2) NOT NULL DEFAULT 50.0,
    `target_gender` ENUM('boys','girls','family','any') NOT NULL DEFAULT 'any',
    `target_tenant` VARCHAR(150) NULL,
    `amenities_json` JSON NULL,
    `photos_json` JSON NULL,
    `status` ENUM('active','inactive','occupied') NOT NULL DEFAULT 'active',
    `views_count` INT NOT NULL DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    INDEX `idx_username` (`username`),
    INDEX `idx_type` (`type`),
    INDEX `idx_uni` (`nearest_university_id`),
    INDEX `idx_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Roommate profiles (live API columns) ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL,
    `username` VARCHAR(100) NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `phone_number` VARCHAR(30) NOT NULL,
    `telegram_handle` VARCHAR(100) NULL,
    `avatar_url` VARCHAR(255) NULL,
    `gender` VARCHAR(20) NOT NULL DEFAULT 'male',
    `age` INT NOT NULL DEFAULT 20,
    `university_id` INT NULL,
    `university_name` VARCHAR(200) NULL,
    `faculty` VARCHAR(150) NULL,
    `course_year` INT NOT NULL DEFAULT 1,
    `budget_min` DECIMAL(15,2) NOT NULL DEFAULT 500000,
    `budget_max` DECIMAL(15,2) NOT NULL DEFAULT 1200000,
    `target_district` VARCHAR(100) NULL,
    `sleep_schedule` VARCHAR(50) NOT NULL DEFAULT 'flexible',
    `cleanliness` VARCHAR(50) NOT NULL DEFAULT 'moderate',
    `study_habit` VARCHAR(50) NOT NULL DEFAULT 'silent',
    `cooking_habit` VARCHAR(50) NOT NULL DEFAULT 'sometimes',
    `smoking_habit` VARCHAR(50) NOT NULL DEFAULT 'no',
    `social_habit` VARCHAR(50) NOT NULL DEFAULT 'balanced',
    `about_me` TEXT NULL,
    `looking_for_text` TEXT NULL,
    `status` ENUM('looking','paused') NOT NULL DEFAULT 'looking',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_username` (`username`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_uni` (`university_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Chores ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_chores` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
    `creator_username` VARCHAR(100) NULL,
    `day_of_week` ENUM('dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba') NOT NULL,
    `chore_type` ENUM('cleaning','dishes','cooking','shopping','trash') NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `assigned_name` VARCHAR(100) NOT NULL,
    `is_completed` TINYINT(1) NOT NULL DEFAULT 0,
    `completed_at` DATETIME NULL,
    `notes` VARCHAR(255) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_group_day` (`group_code`,`day_of_week`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Recipes ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_recipes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name_uz` VARCHAR(150) NOT NULL,
    `category` VARCHAR(50) NOT NULL DEFAULT 'Kechki ovqat',
    `prep_time_min` INT NOT NULL DEFAULT 30,
    `cost_level` ENUM('budget','medium','high') NOT NULL DEFAULT 'budget',
    `ingredients_json` JSON NOT NULL,
    `instructions_uz` TEXT NOT NULL,
    `calories_kcal` INT NOT NULL DEFAULT 500,
    `image_url` VARCHAR(255) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Meal plans ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_meal_plans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
    `day_of_week` ENUM('dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba') NOT NULL,
    `meal_time` ENUM('breakfast','lunch','dinner') NOT NULL DEFAULT 'dinner',
    `recipe_id` INT NULL,
    `recipe_name` VARCHAR(150) NOT NULL,
    `cook_name` VARCHAR(100) NOT NULL DEFAULT 'Navbatchi',
    `prep_schedule` VARCHAR(80) NOT NULL DEFAULT '19:00 - 19:30',
    `eating_schedule` VARCHAR(80) NOT NULL DEFAULT '19:30 - 20:15',
    `cleanup_schedule` VARCHAR(80) NOT NULL DEFAULT '20:15 - 20:30',
    `bread_count` DECIMAL(4,2) NOT NULL DEFAULT 0.50,
    `tea_type` VARCHAR(100) NOT NULL DEFAULT \"Ko'k choy (95-nav)\",
    `notes` VARCHAR(255) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_group_day_meal` (`group_code`,`day_of_week`,`meal_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Market prices ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_market_prices` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `item_key` VARCHAR(50) NOT NULL UNIQUE,
    `name_uz` VARCHAR(150) NOT NULL,
    `category` VARCHAR(50) NOT NULL DEFAULT 'Asosiy',
    `unit` VARCHAR(20) NOT NULL DEFAULT 'kg',
    `avg_price_uzs` DECIMAL(15,2) NOT NULL,
    `min_price_uzs` DECIMAL(15,2) NOT NULL,
    `max_price_uzs` DECIMAL(15,2) NOT NULL,
    `bazaar_sample` VARCHAR(150) NOT NULL DEFAULT 'Chorsu',
    `cheapest_source` VARCHAR(200) NOT NULL DEFAULT 'Qo\'yliq ulgurji bozor',
    `buying_tips` VARCHAR(255) NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Karma / Peer Reputation ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_karma` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
    `from_name` VARCHAR(100) NOT NULL,
    `to_name` VARCHAR(100) NOT NULL,
    `badge_key` VARCHAR(50) NOT NULL,
    `badge_name` VARCHAR(100) NOT NULL,
    `comment` TEXT NULL,
    `points` INT NOT NULL DEFAULT 1,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_group_to` (`group_code`, `to_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Anonymous Polls ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_polls` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `category` VARCHAR(50) NOT NULL DEFAULT 'rules',
    `status` ENUM('active','passed','rejected','closed') NOT NULL DEFAULT 'active',
    `votes_yes` INT NOT NULL DEFAULT 0,
    `votes_no` INT NOT NULL DEFAULT 0,
    `votes_neutral` INT NOT NULL DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_group_status` (`group_code`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_poll_votes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `poll_id` INT NOT NULL,
    `voter_hash` VARCHAR(64) NOT NULL,
    `vote` ENUM('yes','no','neutral') NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_poll_voter` (`poll_id`, `voter_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// --- Finances, Rent & Utilities ---
$pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_finances` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
    `type` ENUM('rent','utility','expense_split','debt') NOT NULL DEFAULT 'expense_split',
    `title` VARCHAR(200) NOT NULL,
    `amount_uzs` BIGINT NOT NULL,
    `paid_by` VARCHAR(100) NOT NULL,
    `category` VARCHAR(50) NOT NULL DEFAULT 'general',
    `due_date` VARCHAR(50) NULL,
    `status` ENUM('pending','partially_paid','settled') NOT NULL DEFAULT 'pending',
    `split_json` TEXT NOT NULL,
    `notes` VARCHAR(255) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_group_type` (`group_code`, `type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

// Clear meal plans before reseed (idempotent re-run safe for plans)
try { $pdo->exec("DELETE FROM `xonadosh_meal_plans` WHERE `group_code`='home_default'"); } catch (Throwable $e) {}

// ==========================================
// SEED UNIVERSITIES
// ==========================================
$unis = [
    ["Toshkent Axborot Texnologiyalari Universiteti (TATU)","TATU","Toshkent","Yunusobod","Amir Temur shoh ko'chasi, 108",41.340900,69.286600,"Shahriston",450],
    ["O'zbekiston Milliy Universiteti (O'zMU)","O'zMU","Toshkent","Olmazor","Talabalar shaharchasi",41.350600,69.206200,"Beruniy",350],
    ["Toshkent Davlat Texnika Universiteti (TDTU)","TDTU","Toshkent","Olmazor","Talabalar shaharchasi, Universitet ko'chasi, 2",41.353300,69.201400,"Beruniy",400],
    ["Toshkent Davlat Iqtisodiyot Universiteti (TDIU)","TDIU (Narxoz)","Toshkent","Chilonzor","Islom Karimov ko'chasi, 49",41.309800,69.243500,"Xalqlar Do'stligi",300],
    ["O'zbekiston Davlat Jahon Tillari Universiteti (O'zDJTU)","O'zDJTU","Toshkent","Uchtepa","Kichik halqa yo'li, G-9a mavzesi, 21-a",41.285800,69.176400,"Novza",1200],
    ["Toshkent Davlat Sharqshunoslik Universiteti (TDSHU)","TDSHU","Toshkent","Mirobod","Amir Temur shoh ko'chasi, 20",41.307500,69.278900,"Amir Temur Xiyoboni",250],
    ["Toshkent Tibbiyot Akademiyasi (TMA)","TMA","Toshkent","Yashnobod","Farobiy ko'chasi, 2",41.319500,69.340200,"Do'stlik",800],
    ["Toshkent Farmatsevtika Instituti (ToshFarmI)","ToshFarmI","Toshkent","Mirobod","Oybek ko'chasi, 45",41.298500,69.272100,"Oybek",200],
    ["Toshkent Davlat Pedagogika Universiteti (TDPU)","TDPU (Nizomiy)","Toshkent","Yakkasaroy","Bunyodkor shoh ko'chasi, 27",41.282900,69.219800,"Mirzo Ulug'bek",300],
    ["Inha Universiteti Toshkentda (IUT)","INHA","Toshkent","Mirzo Ulug'bek","Ziyolilar ko'chasi, 9",41.338500,69.334500,"Buyuk Ipak Yo'li",1500],
    ["Vestminster Xalqaro Universiteti (WIUT)","WIUT","Toshkent","Mirobod","Istiqlol ko'chasi, 12",41.310500,69.280500,"Amir Temur Xiyoboni",300],
    ["Webster Universiteti Toshkentda","Webster","Toshkent","Shayxontohur","Navoiy shoh ko'chasi, 13",41.318200,69.255400,"Alisher Navoiy",350],
    ["Amity Universiteti Toshkentda","Amity","Toshkent","Shayxontohur","Labzak ko'chasi, 70",41.332100,69.261200,"Minor",900],
    ["Samarqand Davlat Universiteti (SamDU)","SamDU","Samarqand","Universitet xiyoboni","Universitet xiyoboni, 15",39.645000,66.960000,null,null],
    ["Farg'ona Davlat Universiteti (FarDU)","FarDU","Farg'ona","Markaz","Murabbiylar ko'chasi, 19",40.386000,71.785000,null,null],
    ["Andijon Davlat Universiteti (ADU)","ADU","Andijon","Markaz","Universitet ko'chasi, 129",40.782000,72.344000,null,null],
    ["Buxoro Davlat Universiteti (BuxDU)","BuxDU","Buxoro","Markaz","M.Iqbol ko'chasi, 11",39.768000,64.421000,null,null]
];
$s = $pdo->prepare("INSERT INTO `xonadosh_universities` (`name_uz`,`short_name`,`city`,`district`,`address`,`latitude`,`longitude`,`nearest_metro`,`metro_distance_m`) VALUES (?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE `short_name`=VALUES(`short_name`)");
foreach ($unis as $u) { $s->execute($u); }

// ==========================================
// SEED 29 MARKET PRICES WITH CHEAPEST SOURCES
// ==========================================
$prices = [
    ["beef","Mol go'shti (Lohim/suyaksiz)","Go'sht","kg",95000,90000,105000,"Qo'yliq / Chorsu","Chorsu Eski Juva go'sht paviloni (ertalab 07:00-09:00)","Katta bo'lak (3-5 kg) olinganda 90 000 so'mdan beriladi"],
    ["mutton","Qo'y go'shti (Yangi go'sht)","Go'sht","kg",105000,98000,115000,"Eski Juva / Chorsu","Chorsu go'sht rastasi (Shanba ertalab)","To'sh qismi dimlama uchun qulay, arzonroq"],
    ["chicken_fillet","Tovuq filesi (Toza lahm)","Go'sht","kg",45000,42000,49000,"Chorsu / Oloy","Chorsu parrandachilik paviloni (10 kg quti bilan)","1 quti (10 kg) ulgurji olinganda 40 000-42 000 so'm/kg"],
    ["minced_meat","Mol qiyma (Yog'sizroq)","Go'sht","kg",85000,80000,92000,"Chorsu bozor","Chorsu qassoblar rastasi","Ko'z oldingizda tortib beriladigan yangi qiyma"],
    ["rice_lazer","Guruch (Lazer Xorazm)","Don & Dukkak","kg",26000,23000,30000,"Qo'yliq dehqon","Qo'yliq ulgurji guruch rastasi (10 kg xaltada)","Palov uchun eng maqbul. 10 kg da 23 000 so'm/kg"],
    ["rice_alanga","Guruch (Alanga saralangan)","Don & Dukkak","kg",19000,17000,22000,"Chorsu bozor","Qo'yliq ulgurji dehqon bozori","Talabalar palovi va mastavasi uchun tejamkor va mazali"],
    ["oil_vegetable","O'simlik yog'i (Pista yog'i)","Yog' & Moy","litr",18000,16500,20000,"Chorsu / Qo'yliq","Havas supermarket aksiyasi / Qo'yliq ulgurji","5 litrlik idishda 16 500 so'm/litr"],
    ["oil_cotton","Paxta yog'i (Zilol)","Yog' & Moy","litr",17000,15500,19000,"Ulgurji bozor","Qo'yliq ulgurji qator","Qovurma va osh uchun xushbo'y"],
    ["onion","Piyoz (Oshbop sariq)","Sabzavot","kg",4000,3200,5000,"Dehqon bozor","Qo'yliq mashinalar ulgurji qatori (30 kg qop)","1 qop (30 kg) olinganda 3 200 so'm/kg"],
    ["carrot_yellow","Sabzi (Sariq oshbop)","Sabzavot","kg",4500,3500,5500,"Dehqon bozor","Qo'yliq dehqon bozori / Chorsu","10 kg dan ortiq olinganda 3 500 so'm/kg"],
    ["carrot_red","Sabzi (Qizil vitaminli)","Sabzavot","kg",5000,4000,6000,"Dehqon bozor","Dehqon bozori","Salat va sho'rvalar uchun"],
    ["potato","Kartoshka (Qizil / Oq)","Sabzavot","kg",6000,5000,7500,"Qo'yliq bozor","Qo'yliq ulgurji kartoshka qatori (25 kg qop)","1 qop (25 kg) olinganda 5 000 so'm/kg"],
    ["tomato","Pomidor (Yangi qizil)","Sabzavot","kg",14000,10000,19000,"Chorsu","Chorsu yangi sabzavotlar rastasi (kechqurun 17:00+)","Kechki payt (17:00 dan keyin) 20% arzonlashadi"],
    ["cucumber","Bodring (Mayda / Tillo)","Sabzavot","kg",9000,7000,13000,"Chorsu","Chorsu / Oloy bozor","Ertalabki salat uchun yangi bodring"],
    ["bell_pepper","Bolgar qalampiri","Sabzavot","kg",16000,12000,22000,"Chorsu","Chorsu sabzavot paviloni","Dimlama va qovurmalarga ta'm beradi"],
    ["cabbage","Karam (Yangi oq)","Sabzavot","kg",4500,3500,6000,"Dehqon bozor","Dehqon bozorlari","Katta bosh karam bir necha kunlik ovqatga yetadi"],
    ["greens","Ko'katlar (Kashnich, ukrop, petrushka)","Sabzavot","bog'",2500,2000,3500,"Bozor","Chorsu ko'kat rastasi","5 ta bog' birgalikda 8 000-10 000 so'm"],
    ["garlic","Sarimsoqpiyoz","Sabzavot","kg",28000,22000,35000,"Chorsu","Chorsu ziravorlar qatori","Palov va sho'rvalar uchun 2-3 bosh yetarli"],
    ["eggs","Tuxum (Saralangan C-1)","Sut & Tuxum","dona",1600,1400,1800,"Parrandachilik / Bozor","Chorsu tuxum qatori (30 donalik lotok = 42 000 so'm)","30 donalik lotok bilan olish arzonroq: 1 400 so'm/dona"],
    ["milk","Sut (Yangi pasterizatsiyalangan)","Sut & Tuxum","litr",10000,8500,12000,"Sut do'koni","Mahalliy sutchi / Ferma savdo nuqtasi","Ertalabki kasha va shirin choy uchun yangi sut"],
    ["bread_bukhanka","Non (Qolipli Buxanka)","Non mahsulotlari","dona",3000,2800,3500,"Non do'koni","Mahalla novvoyxonasi (issiq yangi)","Har kuni ertalab va kechqurun yangi issiq olinadi"],
    ["bread_patir","Non (Tandir Patir / Obi non)","Non mahsulotlari","dona",5000,4000,8000,"Novvoyxona","Mahalliy tandir novvoyxonasi","Palov va dimlama kunlari tandirdan issiq"],
    ["pasta_makaron","Makaron (Pachka 450g oliy nav)","Baqqollik","pachka",9500,8000,12000,"Supermarket/Bozor","Havas / FixPrice / Qo'yliq baqqollik","10 pachkalik blokda 8 000 so'm/pachka"],
    ["lagman_noodles","Lag'mon xamiri (Cho'zma)","Baqqollik","kg",18000,15000,22000,"Chorsu xamir","Chorsu xamirchilar rastasi","Tayyor cho'zilgan yangi xamir vaqtni tejaydi"],
    ["buckwheat_grechka","Grechka (1 kg toza don)","Don & Dukkak","kg",15000,13000,18000,"Chorsu","Chorsu / Havas supermarket","Tez pishadigan toza qovurilgan don"],
    ["mung_bean_mosh","Mosh (Saralangan o'zbek mosh)","Don & Dukkak","kg",17000,14000,20000,"Chorsu bozor","Chorsu dukkakliklar rastasi","Moshkichiri uchun eng yuqori oqsil manbai"],
    ["sugar","Shakar (1 kg)","Baqqollik","kg",14000,12500,16000,"Chorsu ulgurji","Qo'yliq ulgurji shakar bozori (5 kg xaltada)","5 kg xaltada 12 500 so'm/kg"],
    ["tea_green_black","Choy Ko'k 95-nav (100g pachka)","Baqqollik","pachka",10000,8000,14000,"Bozor","Chorsu choy rastasi (Ko'k 95-nav)","Ko'k choy 95-nav — talabalar uchun eng maqbul"],
    ["salt_spices","Ziravorlar to'plami (Zira, murch, tuz)","Ziravor","to'plam",8000,5000,12000,"Ziravorchilar qatori","Chorsu ziravorchilar qatori","Zira va murch to'plami 1 oyga yetadi"]
];
$s = $pdo->prepare("INSERT INTO `xonadosh_market_prices` (`item_key`,`name_uz`,`category`,`unit`,`avg_price_uzs`,`min_price_uzs`,`max_price_uzs`,`bazaar_sample`,`cheapest_source`,`buying_tips`) VALUES (?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE `avg_price_uzs`=VALUES(`avg_price_uzs`),`min_price_uzs`=VALUES(`min_price_uzs`),`max_price_uzs`=VALUES(`max_price_uzs`),`cheapest_source`=VALUES(`cheapest_source`),`buying_tips`=VALUES(`buying_tips`)");
foreach ($prices as $p) { $s->execute($p); }

// ==========================================
// SEED 21 RECIPES (7 × Nonushta, 7 × Tushlik, 7 × Kechki ovqat)
// ==========================================
$recipes = [
// ===== NONUSHTALAR (Breakfast) — Recipe IDs 1-7 =====
[1,"Pomidorli Tuxum Quymoq (Shakshuka-style)","Nonushta",10,"budget",
 json_encode([["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.04,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.02,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Buxanka non","qty_per_person"=>0.50,"unit"=>"dona"],["key"=>"tea_green_black","name"=>"Ko'k choy","qty_per_person"=>0.15,"unit"=>"pachka"],["key"=>"sugar","name"=>"Shakar","qty_per_person"=>0.02,"unit"=>"kg"]],JSON_UNESCAPED_UNICODE),
 "1. Tovada piyoz va pomidorni 3 daqiqa qovuring.\n2. Ustiga tuxumlarni chaqib qopqog'ini 4 daqiqa yoping.\n3. Issiq non botirib yeyiladigan ertalabki shirin taom!",350,"https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800"],

[2,"Tuxumli Issiq Grenki (Non-tuxum)","Nonushta",8,"budget",
 json_encode([["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"milk","name"=>"Sut","qty_per_person"=>0.05,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.02,"unit"=>"litr"],["key"=>"sugar","name"=>"Shakar","qty_per_person"=>0.02,"unit"=>"kg"],["key"=>"tea_green_black","name"=>"Choy","qty_per_person"=>0.15,"unit"=>"pachka"]],JSON_UNESCAPED_UNICODE),
 "1. Tuxumni sut va chimdim tuz bilan ko'pirtiring.\n2. Non bo'laklarini botirib tovada ikki tomonini qizartirib oling.\n3. Issiq shirin choy bilan mazali va tejamkor!",370,"https://images.unsplash.com/photo-1484723091739-00975c5898b8?w=800"],

[3,"Qaynatilgan Tuxum & Tandir Non","Nonushta",5,"budget",
 json_encode([["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"bread_patir","name"=>"Tandir non","qty_per_person"=>0.33,"unit"=>"dona"],["key"=>"tea_green_black","name"=>"Ko'k choy","qty_per_person"=>0.15,"unit"=>"pachka"],["key"=>"sugar","name"=>"Shakar","qty_per_person"=>0.02,"unit"=>"kg"]],JSON_UNESCAPED_UNICODE),
 "1. Tuxumlarni qaynagan suvda 7 daqiqa pishiring.\n2. Issiq tandir noni bilan shirin choy qo'yib nonushta qiling.",300,"https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800"],

[4,"Sutli Suli Bo'tqasi (Gerkules & Asal)","Nonushta",7,"budget",
 json_encode([["key"=>"milk","name"=>"Sut","qty_per_person"=>0.20,"unit"=>"litr"],["key"=>"sugar","name"=>"Shakar/Asal","qty_per_person"=>0.03,"unit"=>"kg"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.25,"unit"=>"dona"],["key"=>"tea_green_black","name"=>"Choy","qty_per_person"=>0.15,"unit"=>"pachka"]],JSON_UNESCAPED_UNICODE),
 "1. Qaynab turgan sutga suli yormasini solib 5 daqiqa aralashtirib pishiring.\n2. Shakar yoki asal qo'shing. Kun bo'yi uzoq quvvat beradi!",330,"https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=800"],

[5,"Lavash Roll (Tuxum & Pomidor & Ko'kat)","Nonushta",8,"budget",
 json_encode([["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"cucumber","name"=>"Bodring","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.01,"unit"=>"litr"],["key"=>"tea_green_black","name"=>"Ko'k choy","qty_per_person"=>0.15,"unit"=>"pachka"],["key"=>"sugar","name"=>"Shakar","qty_per_person"=>0.01,"unit"=>"kg"]],JSON_UNESCAPED_UNICODE),
 "1. Tuxumni tovada quymoq qilib pishirib oling.\n2. Lavash ichiga tuxum, pomidor va bodring o'rab tovada 2 daqiqa qizartiring. Darsga ketishdan oldin tezkor!",390,"https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800"],

[6,"Sabzavotli Omlet (Qalampir & Pomidor)","Nonushta",10,"budget",
 json_encode([["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"bell_pepper","name"=>"Bolgar qalampiri","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.04,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.02,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"],["key"=>"tea_green_black","name"=>"Choy","qty_per_person"=>0.15,"unit"=>"pachka"]],JSON_UNESCAPED_UNICODE),
 "1. Tuxumlarni ko'pirib, mayda to'g'ralgan pomidor va qalampir qo'shing.\n2. Tovada past olovda 5 daqiqa pishiring. Vitaminli nonushta!",380,"https://images.unsplash.com/photo-1506084868230-bb9d95c24759?w=800"],

[7,"Sutli Choy va Non (Eng Tezkor)","Nonushta",3,"budget",
 json_encode([["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"],["key"=>"bread_patir","name"=>"Tandir non","qty_per_person"=>0.33,"unit"=>"dona"],["key"=>"tea_green_black","name"=>"Ko'k choy 95-nav","qty_per_person"=>0.15,"unit"=>"pachka"],["key"=>"sugar","name"=>"Shakar","qty_per_person"=>0.02,"unit"=>"kg"],["key"=>"milk","name"=>"Sut","qty_per_person"=>0.05,"unit"=>"litr"]],JSON_UNESCAPED_UNICODE),
 "1. Qaynagan suvga ko'k choy soling va 3 daqiqa damlab qo'ying.\n2. Issiq non, saryog' bilan. Kechikib qolganda 3 daqiqa nonushta!",280,"https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800"],

// ===== TUSHLIKLAR (Lunch) — Recipe IDs 8-14 =====
[8,"Lanchboks: Tovuqli Sendvich & Bodring","Tushlik",5,"budget",
 json_encode([["key"=>"chicken_fillet","name"=>"Pishgan tovuq","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"cucumber","name"=>"Bodring","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Kechadan qolgan yoki pishirilgan tovuq filesini, bodring va pomidor bo'laklarini nonga qo'ying.\n2. Plastik qutiga joylab universitetga olib boring!",420,"https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800"],

[9,"Issiq Tovuqli Vermishel Sho'rva","Tushlik",20,"budget",
 json_encode([["key"=>"chicken_fillet","name"=>"Tovuq","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"potato","name"=>"Kartoshka","qty_per_person"=>0.12,"unit"=>"kg"],["key"=>"carrot_red","name"=>"Sabzi","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"pasta_makaron","name"=>"Vermishel","qty_per_person"=>0.12,"unit"=>"pachka"],["key"=>"greens","name"=>"Ko'katlar","qty_per_person"=>0.25,"unit"=>"bog'"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Tovuq va sabzavotlarni 15 daqiqa qaynating.\n2. Vermishelni solib 4 daqiqa pishiring, ko'katlar seping.\n3. Oshqozonni charchatmaydigan yengil tushlik!",400,"https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800"],

[10,"Karam & Tuxum Qovurmasi","Tushlik",12,"budget",
 json_encode([["key"=>"cabbage","name"=>"Karam","qty_per_person"=>0.20,"unit"=>"kg"],["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Mayda to'g'ralgan karam va piyozni yumshaguncha qovuring.\n2. Ustiga tuxumlarni chaqib aralashtiring. 12 daqiqada sershira tushlik!",375,"https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800"],

[11,"Kartoshka-Tovuq Qovurma (Tushlik)","Tushlik",18,"budget",
 json_encode([["key"=>"potato","name"=>"Kartoshka","qty_per_person"=>0.20,"unit"=>"kg"],["key"=>"chicken_fillet","name"=>"Tovuq","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Kartoshkani parrak to'g'rab qizigan yog'da qizartirib qovuring.\n2. Mayda tovuq bo'laklari va piyozni qo'shib 5 daqiqa dimlang.",480,"https://images.unsplash.com/photo-1518013034458-30b0ee243590?w=800"],

[12,"Pomidorli Guruch Sho'rva (Tushlik)","Tushlik",18,"budget",
 json_encode([["key"=>"rice_alanga","name"=>"Guruch","qty_per_person"=>0.07,"unit"=>"kg"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"carrot_yellow","name"=>"Sabzi","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.05,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.02,"unit"=>"litr"],["key"=>"greens","name"=>"Ko'katlar","qty_per_person"=>0.25,"unit"=>"bog'"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Piyoz, sabzi va pomidorni qovurib, suv qo'shing.\n2. Guruchni solib 12 daqiqa pishiring va ko'katlar seping. Yengil va to'yimli!",370,"https://images.unsplash.com/photo-1547592180-85f173990554?w=800"],

[13,"Tezkor Somsa (Tovada Pishgan)","Tushlik",22,"budget",
 json_encode([["key"=>"chicken_fillet","name"=>"Tovuq qiymasi","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"salt_spices","name"=>"Zira va tuz","qty_per_person"=>0.15,"unit"=>"to'plam"],["key"=>"bread_patir","name"=>"Non","qty_per_person"=>0.33,"unit"=>"dona"],["key"=>"tea_green_black","name"=>"Choy","qty_per_person"=>0.15,"unit"=>"pachka"]],JSON_UNESCAPED_UNICODE),
 "1. Xamir ichiga tovuq qiymasi, piyoz va zira solib uchburchak buking.\n2. Tovada past olovda har ikki tomonini 8 daqiqa pishiring. Pechkasiz somsa!",450,"https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=800"],

[14,"Tushlik Salat (Pomidor, Bodring, Ko'kat)","Tushlik",5,"budget",
 json_encode([["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.15,"unit"=>"kg"],["key"=>"cucumber","name"=>"Bodring","qty_per_person"=>0.12,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.05,"unit"=>"kg"],["key"=>"greens","name"=>"Ko'katlar","qty_per_person"=>0.50,"unit"=>"bog'"],["key"=>"oil_vegetable","name"=>"Zeytun yog'i","qty_per_person"=>0.01,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Barcha sabzavotlarni yirikroq to'g'rang.\n2. Tuz va yog' solib aralashtiring. Eng tez va eng vitamin to'la tushlik!",260,"https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800"],

// ===== KECHKI OVQATLAR (Dinner) — Recipe IDs 15-21 =====
[15,"Talabacha Tovuqli Palov (Osh)","Kechki ovqat",35,"budget",
 json_encode([["key"=>"chicken_fillet","name"=>"Tovuq filesi","qty_per_person"=>0.15,"unit"=>"kg"],["key"=>"rice_alanga","name"=>"Alanga guruch","qty_per_person"=>0.18,"unit"=>"kg"],["key"=>"carrot_yellow","name"=>"Sariq sabzi","qty_per_person"=>0.20,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Pista yog'i","qty_per_person"=>0.05,"unit"=>"litr"],["key"=>"salt_spices","name"=>"Zira va tuz","qty_per_person"=>0.25,"unit"=>"to'plam"],["key"=>"bread_patir","name"=>"Tandir non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Qozonda yog'ni qizdirib tovuq va piyozni qizartirib qovuring.\n2. Somoncha sabzini solib 5 daqiqa qovuring, suv solib 15 daqiqa zirvak qaynating.\n3. Alanga guruchni tekis solib, suvini tortgach 15 daqiqa damlang.",650,"https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800"],

[16,"Qovurma Makaron (Tuxum & Tomatli)","Kechki ovqat",15,"budget",
 json_encode([["key"=>"pasta_makaron","name"=>"Makaron","qty_per_person"=>0.25,"unit"=>"pachka"],["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Makaronni tuzli suvda 7 daqiqa qaynatib oling.\n2. Tovada piyoz va pomidorni qovurib, makaronni qo'shing.\n3. 2 ta tuxumni chaqib aralashtiring. 15 daqiqada tayyor!",520,"https://images.unsplash.com/photo-1621996346565-e3d5d6281744?w=800"],

[17,"Talabacha Sabzavotli Dimlama","Kechki ovqat",35,"budget",
 json_encode([["key"=>"chicken_fillet","name"=>"Tovuq","qty_per_person"=>0.12,"unit"=>"kg"],["key"=>"potato","name"=>"Kartoshka","qty_per_person"=>0.20,"unit"=>"kg"],["key"=>"cabbage","name"=>"Karam","qty_per_person"=>0.15,"unit"=>"kg"],["key"=>"carrot_red","name"=>"Sabzi","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Qozon tubiga yog' solib, barcha sabzavotlarni qavatma-qavat tering.\n2. Karam barglari bilan yopib qopqog'ini zich yoping.\n3. Past olovda 35 daqiqa o'z bug'ida pishiring.",480,"https://images.unsplash.com/photo-1547592180-85f173990554?w=800"],

[18,"Quyuq Mastava (Qatiq & Ko'katli)","Kechki ovqat",25,"budget",
 json_encode([["key"=>"chicken_fillet","name"=>"Tovuq","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"rice_alanga","name"=>"Guruch","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"potato","name"=>"Kartoshka","qty_per_person"=>0.15,"unit"=>"kg"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"greens","name"=>"Ko'katlar","qty_per_person"=>0.25,"unit"=>"bog'"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Go'sht, piyoz, pomidor va sabzini qovuring.\n2. Suv quyib guruch va kubik kartoshka soling.\n3. 20 daqiqa qaynab quyilgach ko'katlar va qatiq bilan torting.",450,"https://images.unsplash.com/photo-1547592180-85f173990554?w=800"],

[19,"Qovurilgan Kartoshka & Tuxum","Kechki ovqat",20,"budget",
 json_encode([["key"=>"potato","name"=>"Kartoshka","qty_per_person"=>0.25,"unit"=>"kg"],["key"=>"eggs","name"=>"Tuxum","qty_per_person"=>2.0,"unit"=>"dona"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.04,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Kartoshkani parrak to'g'rab qizigan yog'da qizartirib qovuring.\n2. Piyoz qo'shib 3 daqiqa dimlang.\n3. Ustiga tuxumlarni quying, murch va tuz seping. Eng sevimli taom!",510,"https://images.unsplash.com/photo-1518013034458-30b0ee243590?w=800"],

[20,"Moshkichiri (Oqsilga Boy)","Kechki ovqat",30,"budget",
 json_encode([["key"=>"mung_bean_mosh","name"=>"Mosh","qty_per_person"=>0.09,"unit"=>"kg"],["key"=>"rice_alanga","name"=>"Guruch","qty_per_person"=>0.07,"unit"=>"kg"],["key"=>"chicken_fillet","name"=>"Tovuq","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"potato","name"=>"Kartoshka","qty_per_person"=>0.10,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Moshni yuvib qozonga soling va yorilguncha 15 daqiqa qaynating.\n2. Go'sht va piyozni qovurib qozonga qo'shing.\n3. Guruch va kartoshkani solib past olovda miltillatib pishiring.",580,"https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800"],

[21,"Grechka & Tovuqli Sous","Kechki ovqat",25,"budget",
 json_encode([["key"=>"buckwheat_grechka","name"=>"Grechka","qty_per_person"=>0.12,"unit"=>"kg"],["key"=>"chicken_fillet","name"=>"Tovuq","qty_per_person"=>0.12,"unit"=>"kg"],["key"=>"onion","name"=>"Piyoz","qty_per_person"=>0.06,"unit"=>"kg"],["key"=>"carrot_red","name"=>"Sabzi","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"tomato","name"=>"Pomidor","qty_per_person"=>0.08,"unit"=>"kg"],["key"=>"oil_vegetable","name"=>"Yog'","qty_per_person"=>0.03,"unit"=>"litr"],["key"=>"bread_bukhanka","name"=>"Non","qty_per_person"=>0.50,"unit"=>"dona"]],JSON_UNESCAPED_UNICODE),
 "1. Grechkani 1 ga 2 nisbatda tuzli suvda 15 daqiqa qaynating.\n2. Tovada tovuq filesini piyoz, sabzi va pomidor bilan qovurib xushbo'y sous tayyorlang.\n3. Grechka ustiga qaynoq sousni quyib torting.",490,"https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800"]
];

$pdo->exec("TRUNCATE TABLE `xonadosh_recipes`");
$s = $pdo->prepare("INSERT INTO `xonadosh_recipes` (`id`,`name_uz`,`category`,`prep_time_min`,`cost_level`,`ingredients_json`,`instructions_uz`,`calories_kcal`,`image_url`) VALUES (?,?,?,?,?,?,?,?,?)");
foreach ($recipes as $r) { $s->execute($r); }

// ==========================================
// SEED 21 MEAL PLAN SLOTS (7 kun x 3 mahal)
// Har bir slot: kun, mahal, retsept ID, navbatchi, tayyorlash, yeyish, tozalash vaqti, non miqdori, choy turi
// ==========================================
$mealPlans = [
// DUSHANBA
['dushanba','breakfast',1,"Pomidorli Tuxum Quymoq",'Jasur',"07:30 – 07:42","07:42 – 08:15","08:15 – 08:25",0.50,"Ko'k choy (95-nav) + Shakar","Nonushtadan keyin Jasur idish yuvadi, qolganlar darsga tayyorlanadi"],
['dushanba','lunch',   8,"Lanchboks: Tovuqli Sendvich",'Har kim o\'zi',"08:05 – 08:15","12:30 – 13:15","13:15 – 13:25",0.50,"Mineral suv / Choy termos","Universitetga olib ketish uchun ertalab tayyorlanadi"],
['dushanba','dinner', 15,"Talabacha Tovuqli Palov",'Jasur',"19:00 – 19:35","19:35 – 20:15","20:15 – 20:30",0.50,"Ko'k choy & Achchiq-chuchuk","Dushanba — Jasur navbati. Idish: Azizbek"],

// SESHANBA
['seshanba','breakfast',2,"Tuxumli Issiq Grenki",'Azizbek',"07:30 – 07:45","07:45 – 08:15","08:15 – 08:25",0.50,"Sutli shirin choy","Ertalabki qarsildoq grenki darsga kuch beradi"],
['seshanba','lunch',   9,"Issiq Tovuqli Vermishel Sho'rva",'Azizbek',"12:15 – 12:35","12:35 – 13:15","13:15 – 13:30",0.50,"Qora choy / Limon","Uyga kelgan talabalar uchun issiq sho'rva"],
['seshanba','dinner', 16,"Qovurma Makaron (Tuxum & Tomatli)",'Azizbek',"19:15 – 19:30","19:30 – 20:10","20:10 – 20:25",0.50,"Ko'k choy (95-nav)","15 daqiqada bitta tovada pishadigan tezkor taom"],

// CHORSHANBA
['chorshanba','breakfast',3,"Qaynatilgan Tuxum & Tandir Non",'Bekzod',"07:35 – 07:48","07:48 – 08:15","08:15 – 08:25",0.33,"Ko'k choy & Tuzliq","5 daqiqada eng tezkor nonushta"],
['chorshanba','lunch',  10,"Karam & Tuxum Qovurmasi",'Bekzod',"12:20 – 12:35","12:35 – 13:15","13:15 – 13:30",0.50,"Ko'k choy","Oshqozonga yengil va sershira tushlik"],
['chorshanba','dinner', 17,"Sabzavotli Dimlama",'Bekzod',"18:50 – 19:30","19:30 – 20:15","20:15 – 20:30",0.50,"Ko'k choy & Tandir non","Bitta qozonda o'z bug'ida pishadi"],

// PAYSHANBA
['payshanba','breakfast',4,"Sutli Suli Bo'tqasi (Gerkules)",'Sardor',"07:30 – 07:45","07:45 – 08:10","08:10 – 08:25",0.25,"Ko'k choy / Asal","Miyaga uzoq vaqt quvvat beradi"],
['payshanba','lunch',  11,"Kartoshka-Tovuq Qovurma",'Sardor',"12:25 – 12:43","12:43 – 13:15","13:15 – 13:30",0.50,"Qora choy","Tushlik uchun kartoshka qovurma"],
['payshanba','dinner', 18,"Quyuq Mastava (Qatiq & Ko'katli)",'Sardor',"19:00 – 19:30","19:30 – 20:15","20:15 – 20:30",0.50,"Ko'k choy & Qatiq & Ko'kat","Charchoqni chiqaruvchi issiq sho'rva"],

// JUMA
['juma','breakfast',5,"Lavash Roll (Tuxum & Ko'kat)",'Jasur',"07:30 – 07:45","07:45 – 08:15","08:15 – 08:25",0.25,"Shirin choy","Juma tongi — tezkor lavash roll"],
['juma','lunch',   12,"Pomidorli Guruch Sho'rva",'Jasur',"12:20 – 12:38","12:38 – 13:15","13:15 – 13:30",0.50,"Ko'k choy","Juma kuni dars orasida issiq sho'rva"],
['juma','dinner',  19,"Qovurilgan Kartoshka & Tuxum",'Jasur',"19:10 – 19:30","19:30 – 20:15","20:15 – 20:30",0.50,"Ko'k choy & Pomidor salat","Juma kechasi eng sevimli arzon kechki ovqat"],

// SHANBA
['shanba','breakfast',6,"Sabzavotli Omlet",'Azizbek',"08:30 – 08:45","08:45 – 09:30","09:30 – 09:45",0.50,"Qaynoq ko'k choy & Tandir non","Dam olish kuni — xotirjam nonushta"],
['shanba','lunch',  13,"Tezkor Somsa (Tovada)",'Azizbek',"13:00 – 13:25","13:25 – 14:15","14:15 – 14:30",0.33,"Ko'k choy (95-nav)","Shanba tushligida issiq somsa"],
['shanba','dinner', 20,"Moshkichiri (Oqsilga Boy)",'Azizbek',"19:00 – 19:35","19:35 – 20:20","20:20 – 20:40",0.50,"Qatiq & Qora murch","Shanba oqshomida oqsilga boy moshkichiri"],

// YAKSHANBA
['yakshanba','breakfast',7,"Sutli Choy va Non",'Bekzod',"08:45 – 08:55","08:55 – 09:45","09:45 – 10:00",0.50,"Sutli ko'k choy & Qand","Yakshanba — barcha birgalikda xotirjam nonushta"],
['yakshanba','lunch',  14,"Tushlik Salat (Pomidor, Bodring)",'Bekzod',"13:00 – 13:10","13:10 – 14:00","14:00 – 14:15",0.50,"Salqin choy / Kompot","5 daqiqada yangi salat va non"],
['yakshanba','dinner', 21,"Grechka & Tovuqli Sous",'Bekzod',"19:00 – 19:30","19:30 – 20:15","20:15 – 20:30",0.50,"Ko'k choy & Bodring salat","Yangi haftaga quvvat beruvchi sog'lom ovqat"]
];

$s = $pdo->prepare("INSERT INTO `xonadosh_meal_plans` (`group_code`,`day_of_week`,`meal_time`,`recipe_id`,`recipe_name`,`cook_name`,`prep_schedule`,`eating_schedule`,`cleanup_schedule`,`bread_count`,`tea_type`,`notes`) VALUES ('home_default',?,?,?,?,?,?,?,?,?,?,?)");
foreach ($mealPlans as $mp) { $s->execute($mp); }

// ==========================================
// CHORES SEED
// ==========================================
$pdo->exec("DELETE FROM `xonadosh_chores` WHERE `group_code`='home_default'");
$chores = [
    ['dushanba','cooking',"Nonushta (Pomidorli tuxum) va Kechki osh tayyorlash",'Jasur','home_default'],
    ['dushanba','dishes',"Kechki ovqatdan so'ng idishlarni yuvish",'Azizbek','home_default'],
    ['seshanba','cooking',"Tushlik sho'rva va kechki makaron tayyorlash",'Azizbek','home_default'],
    ['seshanba','trash',"Chiqindilarni tashqariga olib chiqish",'Bekzod','home_default'],
    ['chorshanba','cooking',"Nonushta tuxum va kechki dimlama tayyorlash",'Bekzod','home_default'],
    ['chorshanba','dishes',"Idish-tovoqlarni yuvish va oshxona",'Jasur','home_default'],
    ['payshanba','cooking',"Suli bo'tqa va kechki mastava tayyorlash",'Sardor','home_default'],
    ['payshanba','trash',"Chiqindilarni olib chiqish",'Azizbek','home_default'],
    ['juma','cooking',"Lavash roll va kechki kartoshka-tuxum tayyorlash",'Jasur','home_default'],
    ['juma','dishes',"Kechki idishlarni yuvish",'Sardor','home_default'],
    ['shanba','shopping',"Haftalik bozorlik qilish (Qo'yliq / Chorsu)",'Jasur & Bekzod','home_default'],
    ['yakshanba','cleaning',"Umumiy xonalarni tozalash — Hamma birgalikda",'Hamma birgalikda','home_default']
];
$s = $pdo->prepare("INSERT INTO `xonadosh_chores` (`day_of_week`,`chore_type`,`title`,`assigned_name`,`group_code`) VALUES (?,?,?,?,?)");
foreach ($chores as $c) { $s->execute($c); }

@file_put_contents($lockFile, date('c') . "\n");

echo json_encode([
    'ok'=>true,
    'message'=>'XonaDosh — jadvallar va seed muvaffaqiyatli joylashtirildi!',
    'tables'=>[
        'xd_users'=>(int)$pdo->query("SELECT COUNT(*) FROM `xd_users`")->fetchColumn(),
        'universities'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_universities`")->fetchColumn(),
        'listings'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_listings`")->fetchColumn(),
        'profiles'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_profiles`")->fetchColumn(),
        'market_prices'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_market_prices`")->fetchColumn(),
        'recipes'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_recipes`")->fetchColumn(),
        'meal_plan_slots'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_meal_plans`")->fetchColumn(),
        'chores'=>(int)$pdo->query("SELECT COUNT(*) FROM `xonadosh_chores`")->fetchColumn()
    ]
],JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE);
