<?php
declare(strict_types=1);

/**
 * API: 1-Tap Renew Housing Listing (72-hour fresh extension)
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
$username = (string)$sess['username'];

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$listingId = isset($body['listing_id']) && is_numeric($body['listing_id']) ? (int)$body['listing_id'] : null;

if ($listingId === null || $listingId <= 0) {
    json_response(['ok' => false, 'error' => 'listing_id kiritilishi shart'], 400);
}

try {
    // Check if listing belongs to user or user is admin
    $chkStmt = $pdo->prepare("SELECT id, username, phone_number, status, expires_at FROM `xonadosh_listings` WHERE id = ?");
    $chkStmt->execute([$listingId]);
    $listing = $chkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$listing) {
        json_response(['ok' => false, 'error' => 'E‘lon topilmadi'], 404);
    }

    $isOwner = ($listing['username'] === $username) || 
               (!empty($sess['phone_number']) && $listing['phone_number'] === $sess['phone_number']);

    if (!$isOwner) {
        json_response(['ok' => false, 'error' => 'Siz faqat o‘zingizning e‘loningizni yangilashingiz mumkin'], 403);
    }

    // Extend for another 72 hours and set active
    $upd = $pdo->prepare("UPDATE `xonadosh_listings` 
        SET `expires_at` = DATE_ADD(NOW(), INTERVAL 3 DAY), 
            `status` = 'active',
            `created_at` = NOW() 
        WHERE id = ?");
    $upd->execute([$listingId]);

    $newExpiresStmt = $pdo->prepare("SELECT expires_at FROM `xonadosh_listings` WHERE id = ?");
    $newExpiresStmt->execute([$listingId]);
    $newExpires = $newExpiresStmt->fetchColumn();

    json_response([
        'ok' => true,
        'message' => 'E‘lon yana 72 soatga muvaffaqiyatli uzaytirildi va ro‘yxat boshiga ko‘tarildi!',
        'listing_id' => $listingId,
        'expires_at' => $newExpires
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
