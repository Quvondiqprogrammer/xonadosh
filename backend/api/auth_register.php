<?php

declare(strict_types=1);

require dirname(__DIR__) . '/includes/bootstrap.php';
require dirname(__DIR__) . '/includes/db.php';
require dirname(__DIR__) . '/includes/auth_lib.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    auth_fail('method_not_allowed', 'Method not allowed', 405);
}

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    auth_fail('db', 'Database connection failed', 500);
}

$data = request_payload();

$username = normalize_username(isset($data['username']) ? (string) $data['username'] : '');
$password = isset($data['password']) ? (string) $data['password'] : '';
$phoneRaw = isset($data['phone']) ? trim((string) $data['phone']) : '';
if ($phoneRaw === '' && isset($data['phone_number'])) {
    $phoneRaw = trim((string) $data['phone_number']);
}
$fullName = normalize_full_name(isset($data['full_name']) ? (string) $data['full_name'] : '');

$ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '');
$ratePath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'xd_register_' . hash('sha256', $ip) . '.json';
$attempts = 0;
if (is_readable($ratePath)) {
    $blob = json_decode((string) file_get_contents($ratePath), true);
    if (is_array($blob) && isset($blob['n'], $blob['t']) && (time() - (int) $blob['t']) <= 600) {
        $attempts = (int) $blob['n'];
    }
}
if ($attempts >= 8) {
    auth_fail('rate_limited', 'Too many attempts', 429);
}

if ($username === '') {
    auth_fail('invalid_username', 'Login kiriting', 400);
}
if (!username_is_valid($username)) {
    auth_fail('invalid_username', 'Login: 3–32 belgi, harf, raqam, _ yoki .', 400);
}
if (strlen($password) < 8 || strlen($password) > 128) {
    auth_fail('weak_password', 'Parol kamida 8 belgi bo‘lishi kerak', 400);
}
if ($fullName === '' || mb_strlen($fullName) < 2) {
    auth_fail('invalid_name', 'To‘liq ismni kiriting', 400);
}
if (mb_strlen($fullName) > 150) {
    $fullName = mb_substr($fullName, 0, 150);
}

$phone = e164_normalize($phoneRaw);
if ($phone === '') {
    auth_fail('invalid_phone', 'To‘g‘ri telefon raqam kiriting', 400);
}

if (username_taken($pdo, $username)) {
    @file_put_contents($ratePath, json_encode(['n' => $attempts + 1, 't' => time()]), LOCK_EX);
    auth_fail('username_taken', 'Bu login band', 409);
}
if (phone_taken($pdo, $phone)) {
    @file_put_contents($ratePath, json_encode(['n' => $attempts + 1, 't' => time()]), LOCK_EX);
    auth_fail('phone_taken', 'Bu telefon raqam band', 409);
}

$hash = password_hash($password, PASSWORD_BCRYPT);
$now = date('Y-m-d H:i:s');

try {
    $stmt = $pdo->prepare(
        'INSERT INTO xd_users (username, phone, password_hash, full_name, is_blocked, created_at)
         VALUES (?, ?, ?, ?, 0, ?)'
    );
    $stmt->execute([$username, $phone, $hash, $fullName, $now]);
} catch (PDOException $e) {
    error_log('auth_register: ' . $e->getMessage());
    $msg = $e->getMessage();
    if (str_contains($msg, 'uq_username') || str_contains($msg, 'username')) {
        auth_fail('username_taken', 'Bu login band', 409);
    }
    if (str_contains($msg, 'uq_phone') || str_contains($msg, 'phone')) {
        auth_fail('phone_taken', 'Bu telefon raqam band', 409);
    }
    auth_fail('register_failed', 'Ro‘yxatdan o‘tishda xatolik', 500);
} catch (Throwable $e) {
    error_log('auth_register: ' . $e->getMessage());
    auth_fail('register_failed', 'Ro‘yxatdan o‘tishda xatolik', 500);
}

@unlink($ratePath);

$userId = (int) $pdo->lastInsertId();

// Ekotizim sinxronizatsiyasi: yangi foydalanuvchini Hamyon AI bazasida ham yaratish
try {
    $hamyonPdo = new PDO(
        'mysql:host=' . ($cfg['db_host'] ?? 'localhost') . ';dbname=69561c631190f_hamyonai;charset=utf8mb4',
        '69561c631190f_hamyonai',
        (string)($cfg['db_pass'] ?? 'Asad03@18'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $nowMs = (int) round(microtime(true) * 1000);
    $hIns = $hamyonPdo->prepare(
        'INSERT INTO api_users (username, phone_number, password_hash, full_name, is_blocked, created_at, updated_at, last_active_at)
         VALUES (?, ?, ?, ?, 0, ?, ?, ?)
         ON DUPLICATE KEY UPDATE updated_at = VALUES(updated_at)'
    );
    $hIns->execute([$username, $phone, $hash, $fullName, $nowMs, $nowMs, $nowMs]);
} catch (Throwable $ignore) {
}

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
        'phone_number' => $phone,
        'avatar_url' => null,
        'display_name' => $fullName,
    ],
]);
