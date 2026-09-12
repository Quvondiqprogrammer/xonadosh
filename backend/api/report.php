<?php

declare(strict_types=1);

/**
 * UGC report stub — stores moderation reports for listings/profiles/users.
 */

require dirname(__DIR__) . '/includes/bootstrap.php';
require dirname(__DIR__) . '/includes/db.php';
require dirname(__DIR__) . '/includes/auth_lib.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    json_response(['ok' => false, 'error' => 'Method not allowed'], 405);
}

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

$user = auth_require_token($pdo);

$raw = file_get_contents('php://input');
$data = json_decode($raw ?: '{}', true);
if (!is_array($data)) {
    json_response(['ok' => false, 'error' => 'Invalid JSON'], 400);
}

$targetType = trim((string) ($data['target_type'] ?? ''));
$targetId = trim((string) ($data['target_id'] ?? ''));
$reason = trim((string) ($data['reason'] ?? ''));

if ($targetType === '' || $targetId === '' || $reason === '') {
    json_response(['ok' => false, 'error' => 'target_type, target_id va reason kerak'], 400);
}

$stmt = $pdo->prepare(
    'INSERT INTO xd_reports (reporter_username, target_type, target_id, reason, created_at)
     VALUES (?, ?, ?, ?, NOW())'
);
$stmt->execute([(string) $user['username'], $targetType, $targetId, $reason]);

json_response([
    'ok' => true,
    'message' => 'Shikoyat qabul qilindi',
    'report_id' => (int) $pdo->lastInsertId(),
]);
