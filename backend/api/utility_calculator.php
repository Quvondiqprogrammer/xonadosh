<?php
declare(strict_types=1);

/**
 * API: Smart Utility Meter Calculator & Splitter for Uzbekistan Households
 * Hisoblagichlar: Elektr, Gaz, Suv va Wi-Fi
 * Amaldagi O'zbekiston rasmiy tariflari asosida avtomatik hisoblash
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';
require_once dirname(__DIR__) . '/includes/xonadosh_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    $pdo = null;
}

// 2026-yil O'zbekiston rasmiy kommunal tariflari (UZS)
const TARIFF_ELECTRICITY_BASE_LIMIT = 200; // kVt/soat
const TARIFF_ELECTRICITY_BASE_PRICE = 450; // so'm / kVt
const TARIFF_ELECTRICITY_TIER2_PRICE = 900; // so'm / kVt

const TARIFF_GAS_BASE_LIMIT = 500; // m3
const TARIFF_GAS_BASE_PRICE = 650; // so'm / m3
const TARIFF_GAS_TIER2_PRICE = 1500; // so'm / m3

const TARIFF_WATER_COMBINED_PER_M3 = 2400; // Sovuq suv + kanalizatsiya (m3)
const TARIFF_WASTE_PER_PERSON = 5000; // Chiqindi tozalash (oyiga 1 kishi)

if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_meter_readings` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL,
            `meter_type` ENUM('electricity','gas','water') NOT NULL,
            `prev_reading` DECIMAL(12,2) NOT NULL,
            `curr_reading` DECIMAL(12,2) NOT NULL,
            `consumption` DECIMAL(12,2) NOT NULL,
            `total_uzs` BIGINT NOT NULL,
            `meter_photo_url` VARCHAR(255) NULL,
            `reading_month` VARCHAR(7) NOT NULL, -- YYYY-MM
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_group_meter` (`group_code`, `meter_type`, `reading_month`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    } catch (Throwable $e) {}
}

$raw = file_get_contents('php://input');
$body = json_decode($raw ?: '{}', true);
if (!is_array($body)) {
    $body = $_POST;
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$groupCode = xonadosh_get_group_code($body['group_code'] ?? ($_GET['group_code'] ?? null));
$roommateCount = max(1, (int)($body['roommate_count'] ?? ($_GET['roommate_count'] ?? 4)));
$month = date('Y-m');

if ($method === 'GET') {
    // Return last recorded readings and current active tariffs
    $history = [];
    if ($pdo) {
        $stmt = $pdo->prepare("SELECT * FROM `xonadosh_meter_readings` WHERE `group_code` = ? ORDER BY `id` DESC LIMIT 10");
        $stmt->execute([$groupCode]);
        $history = $stmt->fetchAll();
    }

    json_response([
        'ok' => true,
        'group_code' => $groupCode,
        'tariffs' => [
            'electricity' => [
                'base_limit_kwh' => TARIFF_ELECTRICITY_BASE_LIMIT,
                'base_rate_uzs' => TARIFF_ELECTRICITY_BASE_PRICE,
                'tier2_rate_uzs' => TARIFF_ELECTRICITY_TIER2_PRICE,
                'unit' => 'kVt/soat'
            ],
            'gas' => [
                'base_limit_m3' => TARIFF_GAS_BASE_LIMIT,
                'base_rate_uzs' => TARIFF_GAS_BASE_PRICE,
                'tier2_rate_uzs' => TARIFF_GAS_TIER2_PRICE,
                'unit' => 'm³'
            ],
            'water' => [
                'rate_uzs' => TARIFF_WATER_COMBINED_PER_M3,
                'unit' => 'm³'
            ],
            'waste_per_person_uzs' => TARIFF_WASTE_PER_PERSON
        ],
        'history' => $history
    ]);
}

// POST: Calculate & optionally record
$elecPrev = (float)($body['elec_prev'] ?? 0);
$elecCurr = (float)($body['elec_curr'] ?? 0);
$elecPhoto = trim((string)($body['elec_photo_url'] ?? ''));

$gasPrev = (float)($body['gas_prev'] ?? 0);
$gasCurr = (float)($body['gas_curr'] ?? 0);
$gasPhoto = trim((string)($body['gas_photo_url'] ?? ''));

$waterPrev = (float)($body['water_prev'] ?? 0);
$waterCurr = (float)($body['water_curr'] ?? 0);
$waterPhoto = trim((string)($body['water_photo_url'] ?? ''));

$wifiAmount = max(0, (int)($body['wifi_amount_uzs'] ?? 0));
$autoSaveExpense = !empty($body['auto_save_expense']);
$payerName = trim((string)($body['payer_name'] ?? 'Umumiy hisob'));

// 1. Electricity calculation
$elecConsumption = max(0.0, $elecCurr - $elecPrev);
$elecTotal = 0;
if ($elecConsumption <= TARIFF_ELECTRICITY_BASE_LIMIT) {
    $elecTotal = (int)round($elecConsumption * TARIFF_ELECTRICITY_BASE_PRICE);
} else {
    $baseCost = TARIFF_ELECTRICITY_BASE_LIMIT * TARIFF_ELECTRICITY_BASE_PRICE;
    $excess = $elecConsumption - TARIFF_ELECTRICITY_BASE_LIMIT;
    $elecTotal = (int)round($baseCost + ($excess * TARIFF_ELECTRICITY_TIER2_PRICE));
}

// 2. Gas calculation
$gasConsumption = max(0.0, $gasCurr - $gasPrev);
$gasTotal = 0;
if ($gasConsumption <= TARIFF_GAS_BASE_LIMIT) {
    $gasTotal = (int)round($gasConsumption * TARIFF_GAS_BASE_PRICE);
} else {
    $baseCost = TARIFF_GAS_BASE_LIMIT * TARIFF_GAS_BASE_PRICE;
    $excess = $gasConsumption - TARIFF_GAS_BASE_LIMIT;
    $gasTotal = (int)round($baseCost + ($excess * TARIFF_GAS_TIER2_PRICE));
}

// 3. Water calculation
$waterConsumption = max(0.0, $waterCurr - $waterPrev);
$waterTotal = (int)round($waterConsumption * TARIFF_WATER_COMBINED_PER_M3);

// 4. Waste total
$wasteTotal = $roommateCount * TARIFF_WASTE_PER_PERSON;

// Grand total
$grandTotal = $elecTotal + $gasTotal + $waterTotal + $wasteTotal + $wifiAmount;
$perPerson = (int)round($grandTotal / $roommateCount);

// Save meter readings in database
if ($pdo) {
    try {
        if ($elecConsumption > 0) {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_meter_readings` (`group_code`, `meter_type`, `prev_reading`, `curr_reading`, `consumption`, `total_uzs`, `meter_photo_url`, `reading_month`) VALUES (?, 'electricity', ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$groupCode, $elecPrev, $elecCurr, $elecConsumption, $elecTotal, $elecPhoto ?: null, $month]);
        }
        if ($gasConsumption > 0) {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_meter_readings` (`group_code`, `meter_type`, `prev_reading`, `curr_reading`, `consumption`, `total_uzs`, `meter_photo_url`, `reading_month`) VALUES (?, 'gas', ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$groupCode, $gasPrev, $gasCurr, $gasConsumption, $gasTotal, $gasPhoto ?: null, $month]);
        }
        if ($waterConsumption > 0) {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_meter_readings` (`group_code`, `meter_type`, `prev_reading`, `curr_reading`, `consumption`, `total_uzs`, `meter_photo_url`, `reading_month`) VALUES (?, 'water', ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$groupCode, $waterPrev, $waterCurr, $waterConsumption, $waterTotal, $waterPhoto ?: null, $month]);
        }

        // If requested, automatically create an expense bill in xonadosh_finances
        if ($autoSaveExpense && $grandTotal > 0) {
            $title = "Kommunal to'lovlar (" . date('F') . "): Svet, Gaz, Suv";
            $notes = "Svet: {$elecConsumption} kVt (" . number_format($elecTotal, 0, '', ' ') . " so'm), " .
                     "Gaz: {$gasConsumption} m³ (" . number_format($gasTotal, 0, '', ' ') . " so'm), " .
                     "Suv: {$waterConsumption} m³ (" . number_format($waterTotal, 0, '', ' ') . " so'm)";
            
            $splits = [
                'per_person' => $perPerson,
                'roommates' => $roommateCount
            ];

            $fStmt = $pdo->prepare("INSERT INTO `xonadosh_finances` 
                (`group_code`, `type`, `title`, `amount_uzs`, `paid_by`, `category`, `due_date`, `status`, `split_json`, `notes`) 
                VALUES (?, 'utility', ?, ?, ?, 'utility', ?, 'pending', ?, ?)");
            $dueDate = date('Y-m-15', strtotime('+1 month'));
            $fStmt->execute([$groupCode, $title, $grandTotal, $payerName, $dueDate, json_encode($splits), $notes]);
        }
    } catch (Throwable $e) {}
}

// Telegram format summary message ready to post in roommate group
$tgMessage = "📊 *KOMMUNAL TO'LOVLAR HISOBLAGICHI*\n" .
             "🏠 Xonadon: {$groupCode}\n" .
             "📅 Oy: {$month}\n" .
             "👥 Xonadoshlar: {$roommateCount} kishi\n\n" .
             "⚡️ *Elektr:* {$elecConsumption} kVt/soat = " . number_format($elecTotal, 0, '', ' ') . " so'm\n" .
             "🔥 *Gaz:* {$gasConsumption} m³ = " . number_format($gasTotal, 0, '', ' ') . " so'm\n" .
             "💧 *Suv:* {$waterConsumption} m³ = " . number_format($waterTotal, 0, '', ' ') . " so'm\n" .
             "🗑 *Chiqindi:* " . number_format($wasteTotal, 0, '', ' ') . " so'm\n";
if ($wifiAmount > 0) {
    $tgMessage .= "📶 *Wi-Fi:* " . number_format($wifiAmount, 0, '', ' ') . " so'm\n";
}
$tgMessage .= "\n💰 *JAMI SUMMA:* " . number_format($grandTotal, 0, '', ' ') . " so'm\n" .
              "👉 *Har bir kishiga:* *" . number_format($perPerson, 0, '', ' ') . " so'm*\n" .
              "\n_XonaDosh orqali shaffof hisoblandi 📱 xonadoshim.uz_";

json_response([
    'ok' => true,
    'group_code' => $groupCode,
    'month' => $month,
    'roommate_count' => $roommateCount,
    'calculations' => [
        'electricity' => [
            'consumption_kwh' => $elecConsumption,
            'cost_uzs' => $elecTotal,
            'formatted' => number_format($elecTotal, 0, '', ' ') . " so'm"
        ],
        'gas' => [
            'consumption_m3' => $gasConsumption,
            'cost_uzs' => $gasTotal,
            'formatted' => number_format($gasTotal, 0, '', ' ') . " so'm"
        ],
        'water' => [
            'consumption_m3' => $waterConsumption,
            'cost_uzs' => $waterTotal,
            'formatted' => number_format($waterTotal, 0, '', ' ') . " so'm"
        ],
        'waste' => [
            'cost_uzs' => $wasteTotal,
            'formatted' => number_format($wasteTotal, 0, '', ' ') . " so'm"
        ],
        'wifi' => [
            'cost_uzs' => $wifiAmount,
            'formatted' => number_format($wifiAmount, 0, '', ' ') . " so'm"
        ]
    ],
    'grand_total_uzs' => $grandTotal,
    'formatted_grand_total' => number_format($grandTotal, 0, '', ' ') . " so'm",
    'cost_per_person_uzs' => $perPerson,
    'formatted_cost_per_person' => number_format($perPerson, 0, '', ' ') . " so'm",
    'telegram_message' => $tgMessage
]);
