<?php
declare(strict_types=1);

/**
 * XonaDosh Core Library & Schema Definitions
 * Provides tenant isolation (xonadosh_own_group_code),
 * schema definitions, AI matching calculation, and budget calculator helpers.
 */

if (!defined('XONADOSH_LIB_LOADED')) {
    define('XONADOSH_LIB_LOADED', true);
}

/**
 * Tenant Isolation & Group Code Validator
 * Ensures roommate group data (chores, meal plans, expenses) is isolated.
 */
function xonadosh_get_group_code(?string $provided = null): string {
    $code = trim((string)($provided ?? ($_GET['group_code'] ?? ($_POST['group_code'] ?? 'home_default'))));
    if ($code === '' || strlen($code) < 3) {
        return 'home_default';
    }
    // Sanitize to alphanumeric + underscore/dash
    return preg_replace('/[^a-zA-Z0-9_\-]/', '', $code) ?: 'home_default';
}

/**
 * Haversine distance formula between two GPS coordinates
 */
function xonadosh_haversine_km(float $lat1, float $lon1, float $lat2, float $lon2): float {
    $earthRadius = 6371.0;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) * sin($dLat / 2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon / 2) * sin($dLon / 2);
    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
    return round($earthRadius * $c, 2);
}

/**
 * Calculate multi-modal transit estimates
 */
function xonadosh_calculate_commute_modes(float $distKm, ?string $nearestMetro = null): array {
    $roadKm = max(0.3, round($distKm * 1.25, 2));

    $metroTime = max(6, (int)round(($roadKm / 26.0) * 60 + 8));
    $metroFare = 1700;
    $monthlyMetro = $metroFare * 44;

    $busTime = max(9, (int)round(($roadKm / 17.0) * 60 + 5));
    $busFare = 1700;
    $monthlyBus = $busFare * 44;

    $taxiTime = max(4, (int)round(($roadKm / 28.0) * 60 + 3));
    $taxiFare = (int)round(7000 + ($roadKm * 2400));
    $monthlyTaxi = $taxiFare * 44;

    $bikeTime = max(3, (int)round(($roadKm / 14.0) * 60));
    $bikeCalories = (int)round($roadKm * 32);

    $walkTime = max(4, (int)round(($roadKm / 4.5) * 60));
    $walkCalories = (int)round($roadKm * 65);

    return [
        'distance_km' => $roadKm,
        'straight_km' => $distKm,
        'metro' => [
            'name' => 'Metro',
            'time_min' => $metroTime,
            'fare_uzs' => $metroFare,
            'monthly_uzs' => $monthlyMetro,
            'station' => $nearestMetro ?: 'Yaqin metro bekati',
            'recommended' => $roadKm >= 3.0,
        ],
        'bus' => [
            'name' => 'Avtobus',
            'time_min' => $busTime,
            'fare_uzs' => $busFare,
            'monthly_uzs' => $monthlyBus,
            'recommended' => $roadKm < 6.0,
        ],
        'taxi' => [
            'name' => 'Taksi',
            'time_min' => $taxiTime,
            'fare_uzs' => $taxiFare,
            'monthly_uzs' => $monthlyTaxi,
            'recommended' => false,
        ],
        'bicycle' => [
            'name' => 'Velosiped',
            'time_min' => $bikeTime,
            'fare_uzs' => 0,
            'monthly_uzs' => 0,
            'calories_kcal' => $bikeCalories,
            'recommended' => $roadKm <= 4.0,
        ],
        'walk' => [
            'name' => 'Piyoda',
            'time_min' => $walkTime,
            'fare_uzs' => 0,
            'monthly_uzs' => 0,
            'calories_kcal' => $walkCalories,
            'recommended' => $roadKm <= 1.5,
        ],
        'summary' => [
            'monthly_metro_saving_uzs' => max(0, $monthlyTaxi - $monthlyMetro),
        ],
    ];
}

/**
 * Format Telegram Shared Roommate Expense Report
 */
function xonadosh_format_telegram_expense_report(
    string $monthName,
    int $roommatesCount,
    array $categories,
    int $totalSpend,
    int $perPerson,
    array $roommateStatuses
): string {
    $text = "🏠 <b>XONADOSH — Xonadon oylik hisob-kitobi ({$monthName})</b>\n";
    $text .= "──────────────────────────────\n";
    
    foreach ($categories as $cat) {
        $icon = $cat['icon'] ?? '💰';
        $title = $cat['title'] ?? 'Xarajat';
        $amt = number_format((float)($cat['amount_uzs'] ?? 0), 0, '', ' ');
        $text .= "{$icon} {$title}: <b>{$amt} so‘m</b>\n";
    }
    
    $totalFmt = number_format((float)$totalSpend, 0, '', ' ');
    $perPersonFmt = number_format((float)$perPerson, 0, '', ' ');

    $text .= "──────────────────────────────\n";
    $text .= "💰 <b>JAMI XARAJAT:</b> {$totalFmt} so‘m\n";
    $text .= "👥 <b>Xonadoshlar soni:</b> {$roommatesCount} kishi\n";
    $text .= "👤 <b>Kishi boshiga:</b> {$perPersonFmt} so‘m\n";
    $text .= "──────────────────────────────\n";
    $text .= "📊 <b>TO‘LOV HOLATI:</b>\n";

    foreach ($roommateStatuses as $r) {
        $name = $r['name'] ?? 'Xonadosh';
        $isPaid = !empty($r['is_paid']);
        if ($isPaid) {
            $text .= "✅ {$name}: To‘ladi\n";
        } else {
            $dueAmt = number_format((float)($r['due_amount_uzs'] ?? $perPerson), 0, '', ' ');
            $text .= "⏳ {$name}: <b>Qarzda ({$dueAmt} so‘m)</b>\n";
        }
    }

    $text .= "──────────────────────────────\n";
    $text .= "📱 <i>XonaDosh Coliving ekotizimi orqali hisoblandi</i>";

    return $text;
}
