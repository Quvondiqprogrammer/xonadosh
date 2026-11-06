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

$appleSub = '';
$verifiedEmail = '';

// Attempt to parse sub & email from identityToken JWT if provided
if ($identityToken !== '') {
    $parts = explode('.', $identityToken);
    if (count($parts) >= 2) {
        $jwtPayload = json_decode(base64_decode(strtr($parts[1], '-_', '+/')), true);
        if (is_array($jwtPayload)) {
            $appleSub = (string)($jwtPayload['sub'] ?? '');
            if (!empty($jwtPayload['email'])) {
                $verifiedEmail = (string)$jwtPayload['email'];
            }
        }
    }
}

if ($appleSub === '' && $appleId !== '') {
    $appleSub = $appleId;
}

if ($appleSub === '' && $clientEmail !== '') {
    $appleSub = md5($clientEmail);
}

if ($appleSub === '') {
    json_response(['ok' => false, 'error' => 'Apple hisob ma\'lumotlari yetarli emas', 'error_code' => 'missing_apple_creds'], 400);
}

$email = $verifiedEmail !== '' ? $verifiedEmail : $clientEmail;
$name = $clientName !== '' ? $clientName : 'Apple Foydalanuvchi';

// Ensure apple_id column exists
try {
    $cols = $pdo->query("SHOW COLUMNS FROM `xd_users`")->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('apple_id', $cols, true)) {
        $pdo->exec("ALTER TABLE `xd_users` ADD COLUMN `apple_id` VARCHAR(191) NULL DEFAULT NULL AFTER `avatar_url`, ADD INDEX `idx_apple_id` (`apple_id`)");
    }
} catch (Throwable $ignore) {}

// 1. Check existing user by apple_id first, then by target username or email
$stmt = $pdo->prepare('SELECT id, username, phone, full_name, avatar_url, is_blocked FROM xd_users WHERE apple_id = ? AND deleted_at IS NULL LIMIT 1');
$stmt->execute([$appleSub]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

$targetUsername = 'a_' . substr(preg_replace('/[^a-zA-Z0-9_]/', '', $appleSub), -12);
if (!$user) {
    $stmt = $pdo->prepare('SELECT id, username, phone, full_name, avatar_url, is_blocked FROM xd_users WHERE username = ? AND deleted_at IS NULL LIMIT 1');
    $stmt->execute([$targetUsername]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
}

if (!$user && $email !== '') {
    $emailPrefix = preg_replace('/[^a-zA-Z0-9_]/', '', explode('@', $email)[0]);
    if ($emailPrefix !== '') {
        $stmt = $pdo->prepare('SELECT id, username, phone, full_name, avatar_url, is_blocked FROM xd_users WHERE LOWER(username) = LOWER(?) AND deleted_at IS NULL LIMIT 1');
        $stmt->execute([$emailPrefix]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
    }
}

if ($user) {
    if (!empty($user['is_blocked'])) {
        json_response(['ok' => false, 'error' => 'Hisobingiz ma\'muriyat tomonidan bloklangan', 'error_code' => 'blocked'], 403);
    }
    $userId = (int)$user['id'];
    $canonicalUsername = (string)$user['username'];
    try {
        $upd = $pdo->prepare('UPDATE xd_users SET apple_id = COALESCE(apple_id, ?) WHERE id = ?');
        $upd->execute([$appleSub, $userId]);
    } catch (Throwable $e) {}
} else {
    // Create new user in 1 tap
    $canonicalUsername = $targetUsername;
    $check = $pdo->prepare('SELECT id FROM xd_users WHERE username = ? LIMIT 1');
    $check->execute([$canonicalUsername]);
    if ($check->fetch()) {
        $canonicalUsername = 'a_' . substr(preg_replace('/[^a-zA-Z0-9_]/', '', $appleSub), -8) . '_' . substr(md5(uniqid()), 0, 4);
    }

    $phone = '+998' . mt_rand(900000000, 999999999);
    for ($i = 0; $i < 5; $i++) {
        $pCheck = $pdo->prepare('SELECT id FROM xd_users WHERE phone = ? LIMIT 1');
        $pCheck->execute([$phone]);
        if (!$pCheck->fetch()) break;
        $phone = '+998' . mt_rand(900000000, 999999999);
    }

    $hash = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT);
    $now = date('Y-m-d H:i:s');

    $ins = $pdo->prepare('INSERT INTO xd_users (username, phone, password_hash, full_name, avatar_url, apple_id, is_blocked, created_at) VALUES (?, ?, ?, ?, ?, ?, 0, ?)');
    $ins->execute([$canonicalUsername, $phone, $hash, $name, null, $appleSub, $now]);
    $userId = (int)$pdo->lastInsertId();

    $user = [
        'id' => $userId,
        'username' => $canonicalUsername,
        'phone' => $phone,
        'full_name' => $name,
        'avatar_url' => null,
        'is_blocked' => 0,
    ];
}

$session = create_user_session($pdo, $canonicalUsername, 30 * 24 * 3600, 90 * 24 * 3600);

json_response([
    'ok' => true,
    'user_id' => $userId,
    'token' => $session['token'],
    'refresh_token' => $session['refresh_token'],
    'user' => [
        'id' => $userId,
        'username' => $canonicalUsername,
        'phone' => (string)($user['phone'] ?? ''),
        'full_name' => (string)($user['full_name'] ?? $name),
        'avatar_url' => $user['avatar_url'] ?? null,
    ],
]);
