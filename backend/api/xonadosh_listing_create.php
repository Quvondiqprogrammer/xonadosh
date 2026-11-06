<?php
declare(strict_types=1);

/**
 * API: Create or Update Housing Listing in Xonadosh Hub
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

$sess = auth_require_token($pdo);
$username = (string) $sess['username'];
$userId = isset($sess['user_id']) ? (int) $sess['user_id'] : null;

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$title = trim((string)($body['title'] ?? ''));
$description = trim((string)($body['description'] ?? ''));
$type = (string)($body['type'] ?? 'rent');
$price = (float)($body['price'] ?? 0);
$currency = (string)($body['currency'] ?? 'UZS');
$pricePeriod = (string)($body['price_period'] ?? 'month');
$city = trim((string)($body['city'] ?? 'Toshkent'));
$district = trim((string)($body['district'] ?? ''));
$address = trim((string)($body['address'] ?? ''));
$ownerName = trim((string)($body['owner_name'] ?? ''));
if ($ownerName === '') {
    $ownerName = trim((string)($sess['display_name'] ?? ($sess['username'] ?? 'Uy egasi')));
}
if ($ownerName === '') {
    $ownerName = 'Uy egasi';
}
$phoneNumber = trim((string)($body['phone_number'] ?? ''));
if ($phoneNumber === '') {
    $phoneNumber = trim((string)($sess['phone_number'] ?? ''));
}
$telegramHandle = trim((string)($body['telegram_handle'] ?? ''));
$nearestUniId = isset($body['nearest_university_id']) && is_numeric($body['nearest_university_id']) ? (int)$body['nearest_university_id'] : null;
$nearestMetro = trim((string)($body['nearest_metro'] ?? ''));
$roomsCount = (int)($body['rooms_count'] ?? 2);
$floor = (int)($body['floor'] ?? 1);
$totalFloors = (int)($body['total_floors'] ?? 4);
$areaSqm = (float)($body['area_sqm'] ?? 50.0);
$targetGender = (string)($body['target_gender'] ?? 'any');
$targetTenant = (string)($body['target_tenant'] ?? 'Talabalar uchun');
$lat = (float)($body['latitude'] ?? 41.311081);
$lng = (float)($body['longitude'] ?? 69.240562);

$amenities = isset($body['amenities']) && is_array($body['amenities']) ? $body['amenities'] : [];
$photos = isset($body['photos']) && is_array($body['photos']) ? $body['photos'] : [];

$isNoBroker = !empty($body['is_no_broker']) || !empty($body['no_broker']);
if ($isNoBroker && !in_array('bez_makler', $amenities, true)) {
    $amenities[] = 'bez_makler';
}

$utilitiesIncluded = !empty($body['utilities_included']);
if ($utilitiesIncluded && !in_array('utilities_included', $amenities, true)) {
    $amenities[] = 'utilities_included';
    if (!in_array('kommunal_ichida', $amenities, true)) {
        $amenities[] = 'kommunal_ichida';
    }
}

if (empty($title)) {
    json_response(['ok' => false, 'error' => 'E‘lon sarlavhasi kiritilishi shart'], 400);
}
if ($price <= 0) {
    json_response(['ok' => false, 'error' => 'Narx noto‘g‘ri kiritildi'], 400);
}
if (empty($phoneNumber)) {
    json_response(['ok' => false, 'error' => 'Telefon raqam kiritilishi shart'], 400);
}

// Distance to nearest university calculation
$distanceToUni = 1.0;
if ($nearestUniId !== null) {
    $uniStmt = $pdo->prepare("SELECT latitude, longitude FROM `xonadosh_universities` WHERE id = ?");
    $uniStmt->execute([$nearestUniId]);
    $u = $uniStmt->fetch(PDO::FETCH_ASSOC);
    if ($u) {
        $earthRadius = 6371.0;
        $dLat = deg2rad((float)$u['latitude'] - $lat);
        $dLon = deg2rad((float)$u['longitude'] - $lng);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat)) * cos(deg2rad((float)$u['latitude'])) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        $distanceToUni = round($earthRadius * $c, 2);
    }
}

$hasSubsidyContract = !empty($body['has_subsidy_contract']) ? 1 : 0;
$isWomenOnly = (!empty($body['is_women_only']) || $targetGender === 'girls') ? 1 : 0;
$currentRoommatesJson = isset($body['current_roommates']) && is_array($body['current_roommates']) 
    ? json_encode($body['current_roommates'], JSON_UNESCAPED_UNICODE) 
    : null;

// Anti-broker protection: Limit unverified accounts/phones to 1 active listing
try {
    $chkStmt = $pdo->prepare("SELECT COUNT(*) FROM `xonadosh_listings` WHERE `phone_number` = ? AND `status` = 'active' AND (`expires_at` IS NULL OR `expires_at` > NOW())");
    $chkStmt->execute([$phoneNumber]);
    $activeCount = (int)$chkStmt->fetchColumn();
    if ($activeCount >= 2) {
        json_response([
            'ok' => false, 
            'error' => "Har bir telefon raqami uchun maksimal 1 ta bepul faol e'lon ruxsat etiladi (maklerlikni oldini olish tizimi). Yangi e'lon berishdan oldin avvalgisini yakunlang."
        ], 403);
    }
} catch (Throwable $e) {}

try {
    $stmt = $pdo->prepare("INSERT INTO `xonadosh_listings` (
        `user_id`, `username`, `owner_name`, `phone_number`, `telegram_handle`, `type`,
        `title`, `description`, `price`, `currency`, `price_period`, `city`, `district`,
        `address`, `latitude`, `longitude`, `nearest_university_id`, `distance_to_university_km`,
        `nearest_metro`, `rooms_count`, `floor`, `total_floors`, `area_sqm`, `target_gender`,
        `target_tenant`, `has_subsidy_contract`, `is_women_only`, `current_roommates_json`,
        `amenities_json`, `photos_json`, `status`, `expires_at`
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', DATE_ADD(NOW(), INTERVAL 3 DAY))");

    $stmt->execute([
        $userId, $username, $ownerName, $phoneNumber, $telegramHandle, $type,
        $title, $description, $price, $currency, $pricePeriod, $city, $district,
        $address, $lat, $lng, $nearestUniId, $distanceToUni,
        $nearestMetro, $roomsCount, $floor, $totalFloors, $areaSqm, $targetGender,
        $targetTenant, $hasSubsidyContract, $isWomenOnly, $currentRoommatesJson,
        json_encode($amenities, JSON_UNESCAPED_UNICODE),
        json_encode($photos, JSON_UNESCAPED_UNICODE)
    ]);

    $newId = (int)$pdo->lastInsertId();

    json_response([
        'ok' => true,
        'message' => 'E‘lon muvaffaqiyatli joylashtirildi!',
        'listing_id' => $newId
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
