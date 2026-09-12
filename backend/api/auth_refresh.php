<?php

declare(strict_types=1);

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

$raw = file_get_contents('php://input');
$data = json_decode($raw ?: '{}', true);
if (!is_array($data)) {
    json_response(['ok' => false, 'error' => 'Invalid JSON'], 400);
}

$refreshToken = trim((string) ($data['refresh_token'] ?? ''));
if ($refreshToken === '') {
    json_response(['ok' => false, 'error' => 'refresh_token parameter required'], 400);
}

$newSession = auth_rotate_refresh_token($pdo, $refreshToken);
if (!$newSession) {
    json_response(['ok' => false, 'error' => 'Invalid or expired refresh token'], 401);
}

json_response([
    'ok' => true,
    'token' => $newSession['token'],
    'refresh_token' => $newSession['refresh_token'],
    'expires_at' => $newSession['expires_at'],
    'refresh_expires_at' => $newSession['refresh_expires_at'],
    'username' => $newSession['username'],
]);
