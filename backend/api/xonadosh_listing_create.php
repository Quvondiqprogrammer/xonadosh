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
$ownerName = trim((string)($body['owner_name'] ?? ($sess['display_name'] ?? 'Uy egasi')));
$phoneNumber = trim((string)($body['phone_number'] ?? ($sess['phone_number'] ?? '')));
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

try {
    $stmt = $pdo->prepare("INSERT INTO `xonadosh_listings` (
        `user_id`, `username`, `owner_name`, `phone_number`, `telegram_handle`, `type`,
        `title`, `description`, `price`, `currency`, `price_period`, `city`, `district`,
        `address`, `latitude`, `longitude`, `nearest_university_id`, `distance_to_university_km`,
        `nearest_metro`, `rooms_count`, `floor`, `total_floors`, `area_sqm`, `target_gender`,
        `target_tenant`, `amenities_json`, `photos_json`, `status`
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')");

    $stmt->execute([
        $userId, $username, $ownerName, $phoneNumber, $telegramHandle, $type,
        $title, $description, $price, $currency, $pricePeriod, $city, $district,
        $address, $lat, $lng, $nearestUniId, $distanceToUni,
        $nearestMetro, $roomsCount, $floor, $totalFloors, $areaSqm, $targetGender,
        $targetTenant, json_encode($amenities, JSON_UNESCAPED_UNICODE),
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
