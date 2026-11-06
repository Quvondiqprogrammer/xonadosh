<?php
declare(strict_types=1);

/**
 * API: Get Housing & Rental Listings with Distance & Commute Metrics
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

// Helpers
function calc_distance_km(float $lat1, float $lon1, float $lat2, float $lon2): float {
    $earthRadius = 6371.0;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) * sin($dLat / 2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon / 2) * sin($dLon / 2);
    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
    return round($earthRadius * $c, 2);
}

$uniId = isset($_GET['university_id']) && is_numeric($_GET['university_id']) ? (int)$_GET['university_id'] : null;
$type = isset($_GET['type']) && is_string($_GET['type']) && $_GET['type'] !== '' ? trim($_GET['type']) : null;
$gender = isset($_GET['gender']) && is_string($_GET['gender']) && $_GET['gender'] !== '' ? trim($_GET['gender']) : null;
$city = isset($_GET['city']) && is_string($_GET['city']) && $_GET['city'] !== '' && $_GET['city'] !== 'Barchasi' ? trim($_GET['city']) : null;
$district = isset($_GET['district']) && is_string($_GET['district']) && $_GET['district'] !== '' && $_GET['district'] !== 'Barcha tumanlar' ? trim($_GET['district']) : null;
$rooms = isset($_GET['rooms']) && is_numeric($_GET['rooms']) ? (int)$_GET['rooms'] : null;
$minPrice = isset($_GET['min_price']) && is_numeric($_GET['min_price']) ? (float)$_GET['min_price'] : null;
$maxPrice = isset($_GET['max_price']) && is_numeric($_GET['max_price']) ? (float)$_GET['max_price'] : null;
$q = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : null;
$listingId = isset($_GET['id']) && is_numeric($_GET['id']) ? (int)$_GET['id'] : null;

$limit = isset($_GET['limit']) && is_numeric($_GET['limit']) ? min(100, max(1, (int)$_GET['limit'])) : 30;
$offset = isset($_GET['offset']) && is_numeric($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;

$targetUni = null;
if ($uniId !== null && $uniId > 0) {
    $uniStmt = $pdo->prepare("SELECT id, name_uz, short_name, latitude, longitude, nearest_metro FROM `xonadosh_universities` WHERE id = ?");
    $uniStmt->execute([$uniId]);
    $targetUni = $uniStmt->fetch(PDO::FETCH_ASSOC);
}

$sql = "SELECT l.*, u.short_name as uni_short_name, u.name_uz as uni_name_uz, u.latitude as uni_lat, u.longitude as uni_lng 
        FROM `xonadosh_listings` l
        LEFT JOIN `xonadosh_universities` u ON l.nearest_university_id = u.id
        WHERE l.status = 'active'";
$params = [];

if ($listingId !== null) {
    $sql .= " AND l.id = ?";
    $params[] = $listingId;
    try {
        $updView = $pdo->prepare("UPDATE `xonadosh_listings` SET `views_count` = `views_count` + 1 WHERE `id` = ?");
        $updView->execute([$listingId]);
    } catch (Throwable $e) {}
}

if ($type !== null && $type !== 'all') {
    $sql .= " AND l.type = ?";
    $params[] = $type;
}

if ($gender !== null && $gender !== 'any') {
    $sql .= " AND (l.target_gender = ? OR l.target_gender = 'any')";
    $params[] = $gender;
}

if ($city !== null) {
    $sql .= " AND l.city = ?";
    $params[] = $city;
}

if ($district !== null) {
    $sql .= " AND l.district = ?";
    $params[] = $district;
}

if ($rooms !== null && $rooms > 0) {
    $sql .= " AND l.rooms_count = ?";
    $params[] = $rooms;
}

if ($minPrice !== null) {
    $sql .= " AND l.price >= ?";
    $params[] = $minPrice;
}

if ($maxPrice !== null) {
    $sql .= " AND l.price <= ?";
    $params[] = $maxPrice;
}

if ($q !== null && $q !== '') {
    $sql .= " AND (l.title LIKE ? OR l.description LIKE ? OR l.address LIKE ? OR l.district LIKE ? OR l.city LIKE ?)";
    $like = '%' . $q . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$noBroker = isset($_GET['no_broker']) && ($_GET['no_broker'] === '1' || $_GET['no_broker'] === 'true' || $_GET['no_broker'] === 1);
$utilitiesIncluded = isset($_GET['utilities_included']) && ($_GET['utilities_included'] === '1' || $_GET['utilities_included'] === 'true' || $_GET['utilities_included'] === 1);
$subsidyOnly = isset($_GET['subsidy_only']) && ($_GET['subsidy_only'] === '1' || $_GET['subsidy_only'] === 'true' || $_GET['subsidy_only'] === 1);
$womenOnly = isset($_GET['women_only']) && ($_GET['women_only'] === '1' || $_GET['women_only'] === 'true' || $_GET['women_only'] === 1);
$includeExpired = isset($_GET['include_expired']) && ($_GET['include_expired'] === '1' || $_GET['include_expired'] === 'true' || $_GET['include_expired'] === 1);
$maxDistanceKm = isset($_GET['max_distance_km']) && is_numeric($_GET['max_distance_km']) ? (float)$_GET['max_distance_km'] : null;
$maxCommuteMin = isset($_GET['max_commute_min']) && is_numeric($_GET['max_commute_min']) ? (int)$_GET['max_commute_min'] : null;

// Filter out listings auto-hidden due to >= 3 crowd broker reports
$sql .= " AND (l.crowd_broker_reports < 3 OR l.crowd_broker_reports IS NULL)";

// Filter out expired (TTL 72h / stale) listings unless explicitly asked
if (!$includeExpired) {
    $sql .= " AND (l.expires_at IS NULL OR l.expires_at > NOW())";
}

if ($subsidyOnly) {
    $sql .= " AND l.has_subsidy_contract = 1";
}

if ($womenOnly) {
    $sql .= " AND (l.is_women_only = 1 OR l.target_gender = 'girls')";
}

if ($noBroker) {
    $sql .= " AND (l.amenities_json LIKE '%bez_makler%' OR l.amenities_json LIKE '%no_broker%' OR l.title LIKE '%bez makler%' OR l.title LIKE '%maklersiz%' OR l.description LIKE '%bez makler%' OR l.description LIKE '%maklersiz%' OR l.type = 'roommate_wanted')";
}

if ($utilitiesIncluded) {
    $sql .= " AND (l.amenities_json LIKE '%utilities_included%' OR l.amenities_json LIKE '%kommunal_ichida%' OR l.description LIKE '%kommunal ichida%' OR l.description LIKE '%kommunal to‘lov ichida%' OR l.title LIKE '%kommunal ichida%')";
}

$sql .= " ORDER BY l.id DESC LIMIT $limit OFFSET $offset";

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $listings = [];
    foreach ($rows as $r) {
        $lat = (float)$r['latitude'];
        $lng = (float)$r['longitude'];

        $distanceKm = null;
        if ($targetUni !== null) {
            $distanceKm = calc_distance_km($lat, $lng, (float)$targetUni['latitude'], (float)$targetUni['longitude']);
        } elseif ($r['uni_lat'] !== null && $r['uni_lng'] !== null) {
            $distanceKm = calc_distance_km($lat, $lng, (float)$r['uni_lat'], (float)$r['uni_lng']);
        } else {
            $distanceKm = (float)($r['distance_to_university_km'] ?? 1.5);
        }

        // Calculate commute estimates for 4 modes
        // 1. Metro: ~25 km/h, 1700 UZS ticket
        // 2. Bus: ~18 km/h, 1700 UZS ticket
        // 3. Taxi: ~30 km/h, 6000 start + 2200/km UZS
        // 4. Walk: ~4.5 km/h, 0 UZS
        $dist = max(0.2, (float)$distanceKm);
        
        $metroTime = max(5, (int)round(($dist / 25.0) * 60 + 8)); // +8 min walking to/from station
        $metroFare = 1700;
        
        $busTime = max(8, (int)round(($dist / 18.0) * 60 + 5));
        $busFare = 1700;
        
        $taxiTime = max(4, (int)round(($dist / 30.0) * 60 + 3));
        $taxiFare = (int)round(7000 + ($dist * 2400));
        
        $walkTime = (int)round(($dist / 4.5) * 60);
        $walkCalories = (int)round($dist * 60);

        // Monthly budget calculation (22 study days * 2 trips per day = 44 trips)
        $monthlyMetro = $metroFare * 44;
        $monthlyBus = $busFare * 44;
        $monthlyTaxi = $taxiFare * 44;

        if ($maxDistanceKm !== null && $dist > $maxDistanceKm) {
            continue;
        }

        $minCommute = min($metroTime, $busTime, $walkTime);
        if ($maxCommuteMin !== null && $minCommute > $maxCommuteMin) {
            continue;
        }

        $amenities = [];
        if (!empty($r['amenities_json'])) {
            $decoded = json_decode($r['amenities_json'], true);
            if (is_array($decoded)) $amenities = $decoded;
        }

        $photos = [];
        if (!empty($r['photos_json'])) {
            $decoded = json_decode($r['photos_json'], true);
            if (is_array($decoded)) $photos = $decoded;
        }

        $currentRoommates = [];
        if (!empty($r['current_roommates_json'])) {
            $decodedRm = json_decode($r['current_roommates_json'], true);
            if (is_array($decodedRm)) $currentRoommates = $decodedRm;
        }

        $expiresTs = !empty($r['expires_at']) ? strtotime($r['expires_at']) : null;
        $hoursLeft = $expiresTs ? max(0, (int)round(($expiresTs - time()) / 3600)) : 72;
        $daysLeft = (int)ceil($hoursLeft / 24);

        $isNoBroker = in_array('bez_makler', $amenities, true) ||
                      in_array('no_broker', $amenities, true) ||
                      $r['type'] === 'roommate_wanted' ||
                      stripos($r['title'] . ' ' . ($r['description'] ?? ''), 'bez makler') !== false ||
                      stripos($r['title'] . ' ' . ($r['description'] ?? ''), 'maklersiz') !== false;

        $isUtilitiesIncluded = in_array('utilities_included', $amenities, true) ||
                               in_array('kommunal_ichida', $amenities, true) ||
                               stripos($r['title'] . ' ' . ($r['description'] ?? ''), 'kommunal ichida') !== false ||
                               stripos($r['title'] . ' ' . ($r['description'] ?? ''), 'kommunal to‘lov ichida') !== false;

        $hasSubsidy = !empty($r['has_subsidy_contract']);
        $isWomenOnly = !empty($r['is_women_only']) || ($r['target_gender'] === 'girls');

        $listings[] = [
            'id' => (int)$r['id'],
            'user_id' => $r['user_id'] !== null ? (int)$r['user_id'] : null,
            'username' => $r['username'],
            'owner_name' => $r['owner_name'],
            'phone_number' => $r['phone_number'],
            'telegram_handle' => $r['telegram_handle'],
            'type' => $r['type'],
            'title' => $r['title'],
            'description' => $r['description'] ?? '',
            'price' => (float)$r['price'],
            'true_monthly_cost_uzs' => (float)$r['price'] + (float)$monthlyMetro,
            'currency' => $r['currency'],
            'price_period' => $r['price_period'],
            'city' => $r['city'],
            'district' => $r['district'],
            'address' => $r['address'],
            'latitude' => $lat,
            'longitude' => $lng,
            'nearest_university_id' => $r['nearest_university_id'] !== null ? (int)$r['nearest_university_id'] : null,
            'nearest_university_name' => $targetUni ? $targetUni['name_uz'] : ($r['uni_name_uz'] ?? 'OTM'),
            'nearest_university_short' => $targetUni ? $targetUni['short_name'] : ($r['uni_short_name'] ?? 'OTM'),
            'distance_to_university_km' => $distanceKm,
            'nearest_metro' => $r['nearest_metro'],
            'rooms_count' => (int)$r['rooms_count'],
            'floor' => (int)$r['floor'],
            'total_floors' => (int)$r['total_floors'],
            'area_sqm' => (float)$r['area_sqm'],
            'target_gender' => $r['target_gender'],
            'target_tenant' => $r['target_tenant'],
            'is_no_broker' => (bool)$isNoBroker,
            'utilities_included' => (bool)$isUtilitiesIncluded,
            'has_subsidy_contract' => (bool)$hasSubsidy,
            'is_women_only' => (bool)$isWomenOnly,
            'crowd_broker_reports' => (int)($r['crowd_broker_reports'] ?? 0),
            'expires_at' => $r['expires_at'] ?? null,
            'hours_left' => $hoursLeft,
            'days_left' => $daysLeft,
            'current_roommates' => $currentRoommates,
            'amenities' => $amenities,
            'photos' => $photos,
            'status' => $r['status'],
            'views_count' => (int)$r['views_count'],
            'created_at' => $r['created_at'],
            'commute' => [
                'distance_km' => $dist,
                'metro' => [
                    'time_min' => $metroTime,
                    'fare_uzs' => $metroFare,
                    'monthly_uzs' => $monthlyMetro,
                    'station' => $r['nearest_metro'] ?? 'Yaqin metro'
                ],
                'bus' => [
                    'time_min' => $busTime,
                    'fare_uzs' => $busFare,
                    'monthly_uzs' => $monthlyBus
                ],
                'taxi' => [
                    'time_min' => $taxiTime,
                    'fare_uzs' => $taxiFare,
                    'monthly_uzs' => $monthlyTaxi
                ],
                'walk' => [
                    'time_min' => $walkTime,
                    'calories_kcal' => $walkCalories,
                    'fare_uzs' => 0
                ]
            ]
        ];
    }

    // Sort by distance if university is selected
    if ($targetUni !== null) {
        usort($listings, function($a, $b) {
            return ($a['distance_to_university_km'] ?? 999) <=> ($b['distance_to_university_km'] ?? 999);
        });
    }

    json_response([
        'ok' => true,
        'count' => count($listings),
        'target_university' => $targetUni,
        'listings' => $listings
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
