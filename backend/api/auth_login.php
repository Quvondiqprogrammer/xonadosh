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

$login = isset($data['username']) ? trim((string) $data['username']) : '';
if ($login === '' && isset($data['phone'])) {
    $login = trim((string) $data['phone']);
}
if ($login === '' && isset($data['phone_number'])) {
    $login = trim((string) $data['phone_number']);
}
$password = isset($data['password']) ? (string) $data['password'] : '';

if ($login === '' || $password === '') {
    json_response(['ok' => false, 'error' => 'Login yoki parol noto‘g‘ri'], 400);
}

$cacheKey = hash('sha256', $login . "\0" . ($_SERVER['REMOTE_ADDR'] ?? ''));
$path = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'xd_login_' . $cacheKey . '.json';
$attempts = 0;
if (is_readable($path)) {
    $blob = json_decode((string) file_get_contents($path), true);
    if (is_array($blob) && isset($blob['n'], $blob['t']) && (time() - (int) $blob['t']) <= 300) {
        $attempts = (int) $blob['n'];
    }
}
if ($attempts >= 5) {
    json_response(['ok' => false, 'error' => 'Too many attempts'], 429);
}

$stmt = $pdo->prepare(
    'SELECT id, username, phone, password_hash, full_name, avatar_url, is_blocked, deleted_at
     FROM xd_users
     WHERE (username = ? OR phone = ?) AND deleted_at IS NULL
     LIMIT 1'
);
$stmt->execute([$login, $login]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user || !password_verify($password, (string) $user['password_hash'])) {
    @file_put_contents($path, json_encode(['n' => $attempts + 1, 't' => time()]), LOCK_EX);
    json_response(['ok' => false, 'error' => 'Login yoki parol noto‘g‘ri'], 401);
}

if (!empty($user['is_blocked'])) {
    json_response(['ok' => false, 'error' => 'Hisob bloklangan'], 403);
}

@unlink($path);

$canonicalUsername = (string) $user['username'];
$session = create_user_session($pdo, $canonicalUsername, 30 * 24 * 3600, 90 * 24 * 3600);
$userId = (int) $user['id'];

json_response([
    'ok' => true,
    'user_id' => $userId,
    'token' => $session['token'],
    'refresh_token' => $session['refresh_token'],
    'expires_at' => $session['expires_at'],
    'refresh_expires_at' => $session['refresh_expires_at'],
    'username' => $canonicalUsername,
    'user' => [
        'user_id' => $userId,
        'username' => $canonicalUsername,
        'full_name' => $user['full_name'],
        'phone_number' => $user['phone'],
        'avatar_url' => $user['avatar_url'],
        'display_name' => $user['full_name'] ?? $canonicalUsername,
    ],
    'profile' => [
        'full_name' => $user['full_name'],
        'phone_number' => $user['phone'],
        'avatar_url' => $user['avatar_url'],
    ],
]);
