<?php
declare(strict_types=1);

/**
 * API: Crowd-moderation report for undisclosed brokers
 * 1-tap report: 3 reports automatically deactivates listing.
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

// User can be authenticated or guest with client identifier/IP
$username = 'guest_' . substr(md5($_SERVER['REMOTE_ADDR'] ?? '127.0.0.1'), 0, 8);
$userPhone = null;

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!empty($authHeader)) {
        $sess = auth_require_token($pdo);
        $username = (string)$sess['username'];
        $userPhone = (string)($sess['phone_number'] ?? '');
    }
} catch (Throwable $e) {
    // Guest fallback permitted
}

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$listingId = isset($body['listing_id']) && is_numeric($body['listing_id']) ? (int)$body['listing_id'] : null;
$reason = trim((string)($body['reason'] ?? 'Yashirin makler / komissiya so‘radi'));

if ($listingId === null || $listingId <= 0) {
    json_response(['ok' => false, 'error' => 'listing_id kiritilishi shart'], 400);
}

try {
    // Check if listing exists
    $chkStmt = $pdo->prepare("SELECT id, status, crowd_broker_reports FROM `xonadosh_listings` WHERE id = ?");
    $chkStmt->execute([$listingId]);
    $listing = $chkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$listing) {
        json_response(['ok' => false, 'error' => 'E‘lon topilmadi'], 404);
    }

    // Check if this user already reported this listing
    $repStmt = $pdo->prepare("SELECT id FROM `xonadosh_broker_reports` WHERE listing_id = ? AND reporter_username = ?");
    $repStmt->execute([$listingId, $username]);
    if ($repStmt->fetch()) {
        json_response([
            'ok' => true,
            'message' => 'Siz ushbu e‘lon bo‘yicha allaqachon xabar bergansiz. E‘tiboringiz uchun rahmat!',
            'already_reported' => true,
            'reports_count' => (int)$listing['crowd_broker_reports']
        ]);
    }

    // Insert report
    $ins = $pdo->prepare("INSERT INTO `xonadosh_broker_reports` (`listing_id`, `reporter_username`, `reporter_phone`, `reason`) VALUES (?, ?, ?, ?)");
    $ins->execute([$listingId, $username, $userPhone, $reason]);

    // Increment crowd report count
    $upd = $pdo->prepare("UPDATE `xonadosh_listings` SET `crowd_broker_reports` = `crowd_broker_reports` + 1 WHERE id = ?");
    $upd->execute([$listingId]);

    // Fetch updated count
    $cntStmt = $pdo->prepare("SELECT crowd_broker_reports FROM `xonadosh_listings` WHERE id = ?");
    $cntStmt->execute([$listingId]);
    $newCount = (int)$cntStmt->fetchColumn();

    $isDeactivated = false;
    // 3 reports triggers automatic deactivation
    if ($newCount >= 3) {
        $deact = $pdo->prepare("UPDATE `xonadosh_listings` SET `status` = 'inactive' WHERE id = ?");
        $deact->execute([$listingId]);
        $isDeactivated = true;
    }

    json_response([
        'ok' => true,
        'message' => 'Rahmat! Xabaringiz qabul qilindi. 3 ta shikoyat tushsa, e‘lon avtomatik yopiladi.',
        'reports_count' => $newCount,
        'is_deactivated' => $isDeactivated
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
