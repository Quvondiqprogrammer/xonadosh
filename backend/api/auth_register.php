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

$username = isset($data['username']) ? trim((string) $data['username']) : '';
$password = isset($data['password']) ? (string) $data['password'] : '';
$phone = isset($data['phone']) ? trim((string) $data['phone']) : '';
if ($phone === '' && isset($data['phone_number'])) {
    $phone = trim((string) $data['phone_number']);
}
$fullName = isset($data['full_name']) ? trim((string) $data['full_name']) : '';

if ($username === '' && $phone === '') {
    json_response(['ok' => false, 'error' => 'Username yoki telefon raqam kerak'], 400);
}
if (strlen($password) < 8) {
    json_response(['ok' => false, 'error' => 'Parol kamida 8 belgi bo‘lishi kerak'], 400);
}
if ($fullName === '') {
    $fullName = $username !== '' ? $username : ('User' . substr(preg_replace('/\D/', '', $phone) ?: '0', -4));
}

if ($username === '') {
    $digits = preg_replace('/\D+/', '', $phone) ?: '';
    $username = 'u' . ($digits !== '' ? $digits : bin2hex(random_bytes(4)));
}

if (strlen($username) > 100) {
    json_response(['ok' => false, 'error' => 'Username juda uzun'], 400);
}

$stmt = $pdo->prepare('SELECT 1 FROM xd_users WHERE username = ? AND deleted_at IS NULL LIMIT 1');
$stmt->execute([$username]);
if ($stmt->fetchColumn()) {
    json_response(['ok' => false, 'error' => 'Bu login band'], 409);
}

if ($phone !== '') {
    $stmt = $pdo->prepare('SELECT 1 FROM xd_users WHERE phone = ? AND deleted_at IS NULL LIMIT 1');
    $stmt->execute([$phone]);
    if ($stmt->fetchColumn()) {
        json_response(['ok' => false, 'error' => 'Bu telefon raqam band'], 409);
    }
}

$hash = password_hash($password, PASSWORD_BCRYPT);
$now = date('Y-m-d H:i:s');

try {
    $stmt = $pdo->prepare(
        'INSERT INTO xd_users (username, phone, password_hash, full_name, is_blocked, created_at)
         VALUES (?, ?, ?, ?, 0, ?)'
    );
    $stmt->execute([
        $username,
        $phone !== '' ? $phone : null,
        $hash,
        $fullName,
        $now,
    ]);
} catch (Throwable $e) {
    error_log('auth_register: ' . $e->getMessage());
    json_response(['ok' => false, 'error' => 'Ro‘yxatdan o‘tishda xatolik'], 500);
}

$userId = (int) $pdo->lastInsertId();
$session = create_user_session($pdo, $username, 30 * 24 * 3600, 90 * 24 * 3600);

json_response([
    'ok' => true,
    'user_id' => $userId,
    'token' => $session['token'],
    'refresh_token' => $session['refresh_token'],
    'expires_at' => $session['expires_at'],
    'refresh_expires_at' => $session['refresh_expires_at'],
    'username' => $username,
    'user' => [
        'user_id' => $userId,
        'username' => $username,
        'full_name' => $fullName,
        'phone_number' => $phone !== '' ? $phone : null,
        'avatar_url' => null,
        'display_name' => $fullName,
    ],
]);
