<?php
declare(strict_types=1);

/**
 * API: Advanced University Commute Distance & Cost Calculator
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

function haversine_distance_km(float $lat1, float $lon1, float $lat2, float $lon2): float {
    $earthRadius = 6371.0;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) * sin($dLat / 2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon / 2) * sin($dLon / 2);
    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
    return round($earthRadius * $c, 2);
}

$fromLat = isset($_GET['from_lat']) ? (float)$_GET['from_lat'] : null;
$fromLng = isset($_GET['from_lng']) ? (float)$_GET['from_lng'] : null;
$toLat = isset($_GET['to_lat']) ? (float)$_GET['to_lat'] : null;
$toLng = isset($_GET['to_lng']) ? (float)$_GET['to_lng'] : null;
$uniId = isset($_GET['university_id']) ? (int)$_GET['university_id'] : null;
$listingId = isset($_GET['listing_id']) ? (int)$_GET['listing_id'] : null;

$uniName = 'Tanlangan OTM';
$uniShort = 'OTM';
$nearestMetro = 'Yaqin metro bekati';

if ($listingId !== null && $listingId > 0) {
    $lStmt = $pdo->prepare("SELECT latitude, longitude, nearest_university_id, nearest_metro FROM `xonadosh_listings` WHERE id = ?");
    $lStmt->execute([$listingId]);
    $l = $lStmt->fetch(PDO::FETCH_ASSOC);
    if ($l) {
        $fromLat = (float)$l['latitude'];
        $fromLng = (float)$l['longitude'];
        if ($uniId === null && $l['nearest_university_id']) {
            $uniId = (int)$l['nearest_university_id'];
        }
        if (!empty($l['nearest_metro'])) {
            $nearestMetro = $l['nearest_metro'];
        }
    }
}

if ($uniId !== null && $uniId > 0) {
    $uStmt = $pdo->prepare("SELECT name_uz, short_name, latitude, longitude, nearest_metro FROM `xonadosh_universities` WHERE id = ?");
    $uStmt->execute([$uniId]);
    $u = $uStmt->fetch(PDO::FETCH_ASSOC);
    if ($u) {
        $toLat = (float)$u['latitude'];
        $toLng = (float)$u['longitude'];
        $uniName = $u['name_uz'];
        $uniShort = $u['short_name'];
        if ($nearestMetro === 'Yaqin metro bekati' && !empty($u['nearest_metro'])) {
            $nearestMetro = $u['nearest_metro'];
        }
    }
}

if ($fromLat === null || $fromLng === null || $toLat === null || $toLng === null) {
    json_response(['ok' => false, 'error' => 'Manzil koordinatalari to‘liq berilmadi'], 400);
}

// Distance in kilometers
$distKm = haversine_distance_km($fromLat, $fromLng, $toLat, $toLng);
$distKm = max(0.2, $distKm);
// Road factor estimation (crow-flight distance * 1.25 for real city street grid)
$roadKm = round($distKm * 1.25, 2);

// Transport calculations:
// 1. Metro:
$metroTime = max(6, (int)round(($roadKm / 26.0) * 60 + 8));
$metroFare = 1700;
$monthlyMetro = $metroFare * 44; // 22 study days * 2 trips

// 2. Bus:
$busTime = max(9, (int)round(($roadKm / 17.0) * 60 + 5));
$busFare = 1700;
$monthlyBus = $busFare * 44;

// 3. Taxi:
$taxiTime = max(4, (int)round(($roadKm / 28.0) * 60 + 3));
$taxiFare = (int)round(7000 + ($roadKm * 2400));
$monthlyTaxi = $taxiFare * 44;

// 4. Bicycle:
$bikeTime = max(3, (int)round(($roadKm / 14.0) * 60));
$bikeCalories = (int)round($roadKm * 32);

// 5. Walking:
$walkTime = max(4, (int)round(($roadKm / 4.5) * 60));
$walkCalories = (int)round($roadKm * 65);

// Monthly savings comparison:
$monthlyMetroSavingVsTaxi = max(0, $monthlyTaxi - $monthlyMetro);

json_response([
    'ok' => true,
    'university' => [
        'name' => $uniName,
        'short_name' => $uniShort,
        'nearest_metro' => $nearestMetro
    ],
    'distance' => [
        'straight_km' => $distKm,
        'road_km' => $roadKm
    ],
    'modes' => [
        'metro' => [
            'name' => 'Metro (Yer osti / Yer usti)',
            'time_min' => $metroTime,
            'fare_uzs' => $metroFare,
            'monthly_budget_uzs' => $monthlyMetro,
            'icon' => 'directions_subway',
            'recommended' => $roadKm >= 3.0,
            'description' => "$nearestMetro bekati orqali tirbandliksiz qatnov"
        ],
        'bus' => [
            'name' => 'Avtobus (Jamoat transporti)',
            'time_min' => $busTime,
            'fare_uzs' => $busFare,
            'monthly_budget_uzs' => $monthlyBus,
            'icon' => 'directions_bus',
            'recommended' => $roadKm < 6.0,
            'description' => 'To‘g‘ridan-to‘g‘ri yoki 1 ta perexod bilan qatnov'
        ],
        'taxi' => [
            'name' => 'Taksi (Yandex Go / Shahar)',
            'time_min' => $taxiTime,
            'fare_uzs' => $taxiFare,
            'monthly_budget_uzs' => $monthlyTaxi,
            'icon' => 'local_taxi',
            'recommended' => false,
            'description' => 'Shoshilinch holatlar va kechki vaqt uchun'
        ],
        'bicycle' => [
            'name' => 'Velosiped / Samokat',
            'time_min' => $bikeTime,
            'fare_uzs' => 0,
            'monthly_budget_uzs' => 0,
            'calories_kcal' => $bikeCalories,
            'icon' => 'pedal_bike',
            'recommended' => $roadKm <= 4.0,
            'description' => 'Sog‘lom turmush tarzi va 100% tejamkorlik'
        ],
        'walk' => [
            'name' => 'Piyoda borish',
            'time_min' => $walkTime,
            'fare_uzs' => 0,
            'monthly_budget_uzs' => 0,
            'calories_kcal' => $walkCalories,
            'icon' => 'directions_walk',
            'recommended' => $roadKm <= 1.5,
            'description' => "$walkCalories kkal energiya sarfi va toza havo"
        ]
    ],
    'summary' => [
        'monthly_metro_saving_uzs' => $monthlyMetroSavingVsTaxi,
        'fastest_mode' => 'taxi',
        'cheapest_mode' => 'metro_bus',
        'monthly_trips_count' => 44
    ]
]);
