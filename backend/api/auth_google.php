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

$idToken = trim((string)($data['id_token'] ?? $data['token'] ?? ''));
$clientEmail = trim((string)($data['email'] ?? ''));
$clientName = trim((string)($data['name'] ?? ''));
$clientAvatar = trim((string)($data['avatar_url'] ?? ''));
$clientId = trim((string)($data['id'] ?? ''));

$googleSub = '';
$verifiedEmail = '';
$verifiedName = '';
$verifiedAvatar = '';

if (!empty($idToken)) {
    // Verify token with Google
    $ch = curl_init('https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200 && is_string($response)) {
        $payload = json_decode($response, true);
        if (is_array($payload)) {
            $googleSub = (string)($payload['sub'] ?? '');
            $verifiedEmail = (string)($payload['email'] ?? '');
            $verifiedName = (string)($payload['name'] ?? '');
            $verifiedAvatar = (string)($payload['picture'] ?? '');
        }
    }
}

if ($googleSub === '' && $clientId !== '') {
    $googleSub = $clientId;
}

if ($googleSub === '' && $clientEmail !== '') {
    $googleSub = md5($clientEmail);
}

if ($googleSub === '') {
    json_response(['ok' => false, 'error' => 'Google autentifikatsiyasini tasdiqlab bo‘lmadi', 'error_code' => 'invalid_google_token'], 401);
}

$email = $verifiedEmail !== '' ? $verifiedEmail : $clientEmail;
$name = $verifiedName !== '' ? $verifiedName : ($clientName !== '' ? $clientName : 'Google Foydalanuvchi');
$avatar = $verifiedAvatar !== '' ? $verifiedAvatar : $clientAvatar;

// 1. Check existing user by google sub prefix username or phone
$targetUsername = 'g_' . substr($googleSub, -12);
$stmt = $pdo->prepare('SELECT id, username, phone, full_name, avatar_url, is_blocked FROM xd_users WHERE username = ? AND deleted_at IS NULL LIMIT 1');
$stmt->execute([$targetUsername]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user && $email !== '') {
    // Check if username derived from email exists
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
} else {
    // Create new user in 1 tap
    $canonicalUsername = $targetUsername;
    // Ensure username is unique
    $check = $pdo->prepare('SELECT id FROM xd_users WHERE username = ? LIMIT 1');
    $check->execute([$canonicalUsername]);
    if ($check->fetch()) {
        $canonicalUsername = 'g_' . substr($googleSub, -8) . '_' . substr(md5(uniqid()), 0, 4);
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

    $ins = $pdo->prepare('INSERT INTO xd_users (username, phone, password_hash, full_name, avatar_url, is_blocked, created_at) VALUES (?, ?, ?, ?, ?, 0, ?)');
    $ins->execute([$canonicalUsername, $phone, $hash, $name, $avatar !== '' ? $avatar : null, $now]);
    $userId = (int)$pdo->lastInsertId();

    $user = [
        'id' => $userId,
        'username' => $canonicalUsername,
        'phone' => $phone,
        'full_name' => $name,
        'avatar_url' => $avatar !== '' ? $avatar : null,
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
