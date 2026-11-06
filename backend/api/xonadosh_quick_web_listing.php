<?php
declare(strict_types=1);

/**
 * API: 1-Minute Quick Listing from Web Landing (For Landlords)
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$ownerName = trim((string)($body['owner_name'] ?? 'Uy egasi'));
$phoneNumber = trim((string)($body['phone_number'] ?? ''));
$district = trim((string)($body['district'] ?? 'Chilonzor'));
$address = trim((string)($body['address'] ?? 'Toshkent shahar'));
$roomsCount = max(1, min(10, (int)($body['rooms_count'] ?? 2)));
$price = (float)($body['price'] ?? 0);
$targetTenant = trim((string)($body['target_tenant'] ?? 'Talabalar uchun'));
$hasSubsidy = !empty($body['has_subsidy_contract']) ? 1 : 0;
$notes = trim((string)($body['notes'] ?? ''));

if (empty($phoneNumber) || strlen(preg_replace('/\D/', '', $phoneNumber)) < 9) {
    json_response(['ok' => false, 'error' => 'To‘g‘ri telefon raqami kiritilishi shart'], 400);
}

if ($price <= 0) {
    json_response(['ok' => false, 'error' => 'Iltimos, oylik ijara narxini kiriting'], 400);
}

$cleanPhone = preg_replace('/\D/', '', $phoneNumber);
$username = 'web_' . substr($cleanPhone, -9);

// Check anti-spam: max 2 listings from same web phone
$chk = $pdo->prepare("SELECT COUNT(*) FROM `xonadosh_listings` WHERE `phone_number` LIKE ? AND `status` = 'active'");
$chk->execute(['%' . substr($cleanPhone, -9)]);
if ((int)$chk->fetchColumn() >= 2) {
    json_response(['ok' => false, 'error' => 'Ushbu telefon raqamidan allaqachon faol e‘lon mavjud. Moderatorlarimiz siz bilan bog‘lanadi.'], 400);
}

$title = "$district tumanida $roomsCount xonali xonadon ($targetTenant)";
$description = "$district tumanida $roomsCount xonali shinam uy ijaraga beriladi. $targetTenant. " . ($hasSubsidy ? "Ijara shartnomasi va davlat subsidiyasi taqdim etiladi. " : "") . $notes;

$amenities = ['bez_makler', 'web_quick'];
if ($hasSubsidy) {
    $amenities[] = 'subsidy_contract';
}

$targetGender = 'any';
if (stripos($targetTenant, 'qiz') !== false) {
    $targetGender = 'girls';
} elseif (stripos($targetTenant, 'yigit') !== false || stripos($targetTenant, 'bola') !== false) {
    $targetGender = 'boys';
}

// Find nearest university in that district if possible
$uniStmt = $pdo->prepare("SELECT id, latitude, longitude, nearest_metro FROM `xonadosh_universities` WHERE district LIKE ? LIMIT 1");
$uniStmt->execute(['%' . $district . '%']);
$uni = $uniStmt->fetch(PDO::FETCH_ASSOC);

$uniId = $uni ? (int)$uni['id'] : 1;
$lat = $uni ? (float)$uni['latitude'] + 0.005 : 41.311081;
$lng = $uni ? (float)$uni['longitude'] + 0.005 : 69.240562;
$metro = $uni ? ($uni['nearest_metro'] ?? 'Yaqin metro') : 'Metro';

try {
    $ins = $pdo->prepare("INSERT INTO `xonadosh_listings` (
        `username`, `owner_name`, `phone_number`, `type`,
        `title`, `description`, `price`, `currency`, `price_period`, `city`, `district`,
        `address`, `latitude`, `longitude`, `nearest_university_id`, `distance_to_university_km`,
        `nearest_metro`, `rooms_count`, `target_gender`, `target_tenant`,
        `has_subsidy_contract`, `is_women_only`, `amenities_json`, `status`, `expires_at`
    ) VALUES (?, ?, ?, 'rent', ?, ?, ?, 'UZS', 'month', 'Toshkent', ?, ?, ?, ?, ?, 1.2, ?, ?, ?, ?, ?, ?, ?, 'active', DATE_ADD(NOW(), INTERVAL 7 DAY))");

    $ins->execute([
        $username, $ownerName, $phoneNumber,
        $title, $description, $price, $district,
        $address, $lat, $lng, $uniId,
        $metro, $roomsCount, $targetGender, $targetTenant,
        $hasSubsidy, ($targetGender === 'girls' ? 1 : 0),
        json_encode($amenities, JSON_UNESCAPED_UNICODE)
    ]);

    $newId = (int)$pdo->lastInsertId();

    json_response([
        'ok' => true,
        'message' => 'E‘loningiz muvaffaqiyatli qabul qilindi va darhol sayt hamda ilovaga joylashtirildi!',
        'listing_id' => $newId
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
