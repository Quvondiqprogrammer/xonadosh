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

$token = bearer_token();
if ($token === null) {
    json_response(['ok' => false, 'error' => 'Authorization token missing'], 401);
}

$stmt = $pdo->prepare('DELETE FROM xd_sessions WHERE token = ?');
$stmt->execute([$token]);

json_response(['ok' => true, 'logged_out' => true]);
