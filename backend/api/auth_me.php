<?php

declare(strict_types=1);

require dirname(__DIR__) . '/includes/bootstrap.php';
require dirname(__DIR__) . '/includes/db.php';
require dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

$user = auth_require_token($pdo);

json_response([
    'ok' => true,
    'user' => [
        'user_id' => (int) $user['user_id'],
        'username' => $user['username'],
        'full_name' => $user['full_name'] ?? null,
        'phone_number' => $user['phone_number'] ?? null,
        'avatar_url' => $user['avatar_url'] ?? null,
        'display_name' => $user['display_name'] ?? ($user['full_name'] ?? $user['username']),
    ],
]);
