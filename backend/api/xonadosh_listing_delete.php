<?php
declare(strict_types=1);

/**
 * API: Delete or Deactivate Listing in Xonadosh Hub
 * Requires Bearer auth + ownership of the listing.
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

$user = auth_require_token($pdo);
$username = (string) ($user['username'] ?? '');

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    json_response(['ok' => false, 'error' => 'Method not allowed'], 405);
}

$raw = file_get_contents('php://input');
$body = json_decode($raw ?: '{}', true);
if (!is_array($body)) {
    $body = $_POST;
}
$listingId = isset($body['listing_id']) ? (int) $body['listing_id'] : 0;

if ($listingId <= 0) {
    json_response(['ok' => false, 'error' => 'listing_id kiritilishi shart'], 400);
}

try {
    $check = $pdo->prepare(
        'SELECT id, username FROM `xonadosh_listings` WHERE `id` = ? LIMIT 1'
    );
    $check->execute([$listingId]);
    $row = $check->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        json_response(['ok' => false, 'error' => 'E‘lon topilmadi'], 404);
    }

    if (strcasecmp((string) $row['username'], $username) !== 0) {
        json_response(['ok' => false, 'error' => 'Faqat o‘z e‘loningizni o‘chira olasiz'], 403);
    }

    $stmt = $pdo->prepare(
        "UPDATE `xonadosh_listings` SET `status` = 'inactive' WHERE `id` = ? AND `username` = ?"
    );
    $stmt->execute([$listingId, $row['username']]);

    json_response([
        'ok' => true,
        'message' => 'E‘lon muvaffaqiyatli o‘chirildi/arxivlandi',
    ]);
} catch (Throwable $e) {
    error_log('xonadosh_listing_delete: ' . $e->getMessage());
    json_response(['ok' => false, 'error' => 'Server xatosi'], 500);
}
