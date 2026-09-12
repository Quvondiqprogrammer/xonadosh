<?php

declare(strict_types=1);

function generate_token(): string
{
    return bin2hex(random_bytes(32));
}

function generate_refresh_token(): string
{
    return bin2hex(random_bytes(32));
}

function bearer_token(): ?string
{
    $candidates = [];

    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $candidates[] = (string) $_SERVER['HTTP_AUTHORIZATION'];
    }
    if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $candidates[] = (string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }
    if (!empty($_SERVER['HTTP_X_AUTH_TOKEN'])) {
        $candidates[] = (string) $_SERVER['HTTP_X_AUTH_TOKEN'];
    }
    if (!empty($_SERVER['HTTP_X_AUTHORIZATION'])) {
        $candidates[] = (string) $_SERVER['HTTP_X_AUTHORIZATION'];
    }
    if (!empty($_ENV['HTTP_AUTHORIZATION'])) {
        $candidates[] = (string) $_ENV['HTTP_AUTHORIZATION'];
    }
    $envAuth = getenv('HTTP_AUTHORIZATION');
    if ($envAuth !== false && $envAuth !== '') {
        $candidates[] = (string) $envAuth;
    }

    if (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        if (is_array($headers)) {
            foreach ($headers as $name => $value) {
                if (strcasecmp((string) $name, 'Authorization') === 0 ||
                    strcasecmp((string) $name, 'X-Auth-Token') === 0 ||
                    strcasecmp((string) $name, 'X-Authorization') === 0) {
                    $candidates[] = (string) $value;
                }
            }
        }
    }

    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        if (is_array($headers)) {
            foreach ($headers as $name => $value) {
                if (strcasecmp((string) $name, 'Authorization') === 0 ||
                    strcasecmp((string) $name, 'X-Auth-Token') === 0 ||
                    strcasecmp((string) $name, 'X-Authorization') === 0) {
                    $candidates[] = (string) $value;
                }
            }
        }
    }

    foreach ($candidates as $h) {
        $h = trim($h);
        if (stripos($h, 'Bearer ') === 0) {
            $token = trim(substr($h, 7));
            if ($token !== '') {
                return $token;
            }
        } elseif (strlen($h) === 64 && ctype_xdigit($h)) {
            return $h;
        }
    }

    if (!empty($_POST['token'])) {
        $t = trim((string) $_POST['token']);
        if (strlen($t) === 64 && ctype_xdigit($t)) {
            return $t;
        }
    }

    $rawInput = file_get_contents('php://input');
    if ($rawInput !== false && $rawInput !== '') {
        $decoded = json_decode($rawInput, true);
        if (is_array($decoded) && !empty($decoded['token'])) {
            $t = trim((string) $decoded['token']);
            if (strlen($t) === 64 && ctype_xdigit($t)) {
                return $t;
            }
        }
    }

    return null;
}

/**
 * @return array{username:string, user_id?:int|null, phone_number?:string|null, display_name?:string|null}|null
 */
function session_from_token(PDO $pdo, ?string $token): ?array
{
    if ($token === null || strlen($token) !== 64 || !ctype_xdigit($token)) {
        return null;
    }

    $now = time() * 1000;
    $stmt = $pdo->prepare(
        'SELECT u.id AS user_id, u.username AS username, u.phone AS phone_number, u.full_name AS display_name
         FROM xd_sessions s
         INNER JOIN xd_users u ON u.username = s.username
         WHERE s.token = ? AND s.expires_at > ? AND u.is_blocked = 0 AND u.deleted_at IS NULL
         LIMIT 1'
    );
    $stmt->execute([$token, $now]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        return null;
    }

    return [
        'username' => (string) $row['username'],
        'user_id' => isset($row['user_id']) ? (int) $row['user_id'] : null,
        'phone_number' => $row['phone_number'] ?? null,
        'display_name' => $row['display_name'] ?? null,
    ];
}

/**
 * @return array{user_id:int, username:string, full_name:?string, phone_number:?string, avatar_url:?string, display_name:?string}|null
 */
function auth_get_user_by_token(PDO $pdo, ?string $token): ?array
{
    $session = session_from_token($pdo, $token);
    if (!$session) {
        return null;
    }

    $stmt = $pdo->prepare(
        'SELECT id AS user_id, username, full_name, phone AS phone_number, avatar_url
         FROM xd_users
         WHERE username = ? AND deleted_at IS NULL
         LIMIT 1'
    );
    $stmt->execute([$session['username']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        return null;
    }

    $user['user_id'] = (int) $user['user_id'];
    $user['display_name'] = $user['full_name'] ?? $user['username'];
    $user['id'] = $user['user_id'];

    return $user;
}

/**
 * @return array{token:string, refresh_token:string, expires_at:int, refresh_expires_at:int}
 */
function create_user_session(PDO $pdo, string $username, int $accessDurationSec = 86400, int $refreshDurationSec = 2592000): array
{
    $token = generate_token();
    $refreshToken = generate_refresh_token();
    $nowMs = (int) round(microtime(true) * 1000);
    $expiresAt = $nowMs + ($accessDurationSec * 1000);
    $refreshExpiresAt = $nowMs + ($refreshDurationSec * 1000);

    $stmt = $pdo->prepare(
        'INSERT INTO xd_sessions (token, username, created_at, expires_at, refresh_token, refresh_expires_at)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $stmt->execute([$token, $username, $nowMs, $expiresAt, $refreshToken, $refreshExpiresAt]);

    return [
        'token' => $token,
        'refresh_token' => $refreshToken,
        'expires_at' => $expiresAt,
        'refresh_expires_at' => $refreshExpiresAt,
    ];
}

/**
 * @return array{token:string, refresh_token:string, expires_at:int, refresh_expires_at:int, username:string}|null
 */
function auth_rotate_refresh_token(PDO $pdo, string $refreshToken): ?array
{
    if (strlen($refreshToken) !== 64 || !ctype_xdigit($refreshToken)) {
        return null;
    }

    $nowMs = (int) round(microtime(true) * 1000);
    $stmt = $pdo->prepare(
        'SELECT s.username, u.is_blocked, u.deleted_at
         FROM xd_sessions s
         INNER JOIN xd_users u ON u.username = s.username
         WHERE s.refresh_token = ? AND (s.refresh_expires_at IS NULL OR s.refresh_expires_at > ?)
           AND u.is_blocked = 0 AND u.deleted_at IS NULL
         LIMIT 1'
    );
    $stmt->execute([$refreshToken, $nowMs]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        return null;
    }

    $username = (string) $row['username'];
    $del = $pdo->prepare('DELETE FROM xd_sessions WHERE refresh_token = ?');
    $del->execute([$refreshToken]);

    $newSession = create_user_session($pdo, $username);
    $newSession['username'] = $username;

    return $newSession;
}

/**
 * @return array{username:string, user_id:int, full_name:?string, phone_number:?string, avatar_url:?string, display_name:?string, id:int}
 */
function auth_require_token(PDO $pdo): array
{
    $token = bearer_token();
    if ($token === null) {
        json_response(['ok' => false, 'error' => 'Authorization token missing'], 401);
    }

    $user = auth_get_user_by_token($pdo, $token);
    if ($user) {
        return $user;
    }

    json_response(['ok' => false, 'error' => 'Invalid or expired authorization token'], 401);
}
