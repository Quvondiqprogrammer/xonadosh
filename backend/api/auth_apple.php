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

$data = request_payload();
if ($data === []) {
    json_response(['ok' => false, 'error' => 'Invalid JSON', 'error_code' => 'invalid_json'], 400);
}

$identityToken = trim((string)($data['identity_token'] ?? $data['token'] ?? ''));
$clientEmail = trim((string)($data['email'] ?? ''));
$clientName = trim((string)($data['name'] ?? ''));
$appleId = trim((string)($data['apple_id'] ?? $data['id'] ?? ''));

$appleSub = $appleId !== '' ? $appleId : ($clientEmail !== '' ? md5($clientEmail) : '');

if ($appleSub === '' && $identityToken === '') {
    json_response(['ok' => false, 'error' => 'Apple hisob ma\'lumotlari yetarli emas', 'error_code' => 'missing_apple_creds'], 400);
}

$email = $clientEmail;
$name = $clientName !== '' ? $clientName : 'Apple Foydalanuvchi';

// Ensure apple_id column exists
try {
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_id VARCHAR(191) DEFAULT NULL");
} catch (Throwable $ignore) {}

$stmt = $pdo->prepare('SELECT * FROM users WHERE (apple_id IS NOT NULL AND apple_id = ?) OR (email IS NOT NULL AND email = ?) LIMIT 1');
$stmt->execute([$appleSub, $email !== '' ? $email : '__none__']);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

$now = date('Y-m-d H:i:s');
$isNew = false;

if ($user) {
    $userId = (int)$user['id'];
    $phone = (string)($user['phone'] ?? '');
    try {
        $upd = $pdo->prepare('UPDATE users SET apple_id = COALESCE(apple_id, ?), email = COALESCE(email, ?), updated_at = ? WHERE id = ?');
        $upd->execute([$appleSub, $email !== '' ? $email : null, $now, $userId]);
    } catch (Throwable $e) {}
} else {
    $isNew = true;
    $fakePhone = '+99899' . random_int(1000000, 9999999);
    $dummyHash = password_hash('apple_auth_' . bin2hex(random_bytes(16)), PASSWORD_DEFAULT);
    
    $ins = $pdo->prepare('INSERT INTO users (phone, full_name, email, apple_id, password_hash, is_verified, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 1, ?, ?)');
    $ins->execute([
        $fakePhone,
        $name,
        $email !== '' ? $email : null,
        $appleSub,
        $dummyHash,
        $now,
        $now
    ]);
    $userId = (int)$pdo->lastInsertId();
    $phone = $fakePhone;
}

$token = bin2hex(random_bytes(32));
$refreshToken = bin2hex(random_bytes(32));
$expiresAt = date('Y-m-d H:i:s', time() + (30 * 86400));

try {
    $sess = $pdo->prepare('INSERT INTO user_sessions (user_id, token, refresh_token, expires_at, created_at) VALUES (?, ?, ?, ?, ?)');
    $sess->execute([$userId, $token, $refreshToken, $expiresAt, $now]);
} catch (Throwable $e) {}

json_response([
    'ok' => true,
    'is_new' => $isNew,
    'user_id' => $userId,
    'token' => $token,
    'refresh_token' => $refreshToken,
    'expires_at' => $expiresAt,
    'user' => [
        'id' => $userId,
        'phone' => $phone,
        'full_name' => $name,
        'email' => $email,
    ],
]);
