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

$login = isset($data['username']) ? trim((string) $data['username']) : '';
if ($login === '' && isset($data['phone'])) {
    $login = trim((string) $data['phone']);
}
if ($login === '' && isset($data['phone_number'])) {
    $login = trim((string) $data['phone_number']);
}
$password = isset($data['password']) ? (string) $data['password'] : '';

if ($login === '' || $password === '') {
    json_response(['ok' => false, 'error' => 'Login yoki parol noto‘g‘ri', 'error_code' => 'invalid_credentials'], 400);
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
    json_response(['ok' => false, 'error' => 'Too many attempts', 'error_code' => 'rate_limited'], 429);
}

$clauses = ['LOWER(username) = LOWER(?)', 'username = ?', 'phone = ?'];
$params = [$login, $login, $login];

$usernameNorm = normalize_username($login);
if ($usernameNorm !== '' && $usernameNorm !== strtolower($login)) {
    $clauses[] = 'LOWER(username) = ?';
    $params[] = $usernameNorm;
}

$phoneNorm = e164_normalize($login);
if ($phoneNorm !== '') {
    $variants = e164_variants($phoneNorm);
    $clauses[] = 'phone IN (' . implode(',', array_fill(0, count($variants), '?')) . ')';
    $params = array_merge($params, $variants);
    $digitKey = e164_digits($phoneNorm);
    $clauses[] = "REPLACE(REPLACE(REPLACE(REPLACE(IFNULL(phone,''), '+', ''), ' ', ''), '-', ''), '(', '') = ?";
    $params[] = $digitKey;
    if (e164_is_uz($phoneNorm)) {
        $clauses[] = "RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(IFNULL(phone,''), '+', ''), ' ', ''), '-', ''), '(', ''), 9) = ?";
        $params[] = substr($digitKey, 3);
    }
}

$sql = 'SELECT id, username, phone, password_hash, full_name, avatar_url, is_blocked, deleted_at
     FROM xd_users
     WHERE (' . implode(' OR ', $clauses) . ') AND deleted_at IS NULL
     LIMIT 1';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user || !password_verify($password, (string) $user['password_hash'])) {
    // Cross-Ecosystem Auto-Sync: Hamyon AI foydalanuvchilar bazasidan tekshirish va sinxronlash
    $hamyonSynced = false;
    try {
        $hamyonPdo = new PDO(
            'mysql:host=' . ($cfg['db_host'] ?? 'localhost') . ';dbname=69561c631190f_hamyonai;charset=utf8mb4',
            '69561c631190f_hamyonai',
            (string)($cfg['db_pass'] ?? 'Asad03@18'),
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
        $cleanPhone9 = substr((string) preg_replace('/\D/', '', $login), -9);
        $hStmt = $hamyonPdo->prepare(
            'SELECT user_id, username, phone_number, password_hash, full_name, profile_image_url, is_blocked
             FROM api_users
             WHERE (username = ? OR phone_number = ? OR RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(IFNULL(phone_number,""), "+", ""), " ", ""), "-", ""), "(", ""), 9) = ?)
             LIMIT 1'
        );
        $hStmt->execute([$login, $login, $cleanPhone9]);
        $hUser = $hStmt->fetch(PDO::FETCH_ASSOC);

        if ($hUser && password_verify($password, (string) $hUser['password_hash']) && empty($hUser['is_blocked'])) {
            $nowTime = date('Y-m-d H:i:s');
            $newUname = (string) $hUser['username'];
            $newPhone = (string) ($hUser['phone_number'] ?? $login);
            $newFullName = (string) ($hUser['full_name'] ?? $newUname);
            $newPassHash = (string) $hUser['password_hash'];
            $newAvatar = $hUser['profile_image_url'] ?? null;

            $ins = $pdo->prepare(
                'INSERT INTO xd_users (username, phone, password_hash, full_name, avatar_url, created_at)
                 VALUES (?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), full_name = VALUES(full_name)'
            );
            $ins->execute([$newUname, $newPhone, $newPassHash, $newFullName, $newAvatar, $nowTime]);

            $stmt = $pdo->prepare('SELECT id, username, phone, password_hash, full_name, avatar_url, is_blocked FROM xd_users WHERE username = ? LIMIT 1');
            $stmt->execute([$newUname]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($user) {
                $hamyonSynced = true;
            }
        }
    } catch (Throwable $ignore) {
    }

    if (!$hamyonSynced) {
        @file_put_contents($path, json_encode(['n' => $attempts + 1, 't' => time()]), LOCK_EX);
        json_response(['ok' => false, 'error' => 'Login yoki parol noto‘g‘ri', 'error_code' => 'invalid_credentials'], 401);
    }
}

if (!empty($user['is_blocked'])) {
    json_response(['ok' => false, 'error' => 'Hisob bloklangan', 'error_code' => 'blocked'], 403);
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
