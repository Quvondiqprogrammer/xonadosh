<?php

declare(strict_types=1);

/**
 * Self-service account deletion (Apple Guideline 5.1.1(v)).
 * Soft-deletes the user, revokes sessions, removes listings/profiles.
 */

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

$user = auth_require_token($pdo);
$username = (string) ($user['username'] ?? '');
if ($username === '') {
    json_response(['ok' => false, 'error' => 'Unauthorized'], 401);
}

$raw = file_get_contents('php://input');
$data = json_decode($raw ?: '{}', true);
if (!is_array($data)) {
    json_response(['ok' => false, 'error' => 'Invalid JSON'], 400);
}

$password = isset($data['password']) ? (string) $data['password'] : '';
$confirm = isset($data['confirm']) ? (string) $data['confirm'] : '';
if ($password === '') {
    json_response(['ok' => false, 'error' => 'Password required'], 400);
}
if (strtolower(trim($confirm)) !== 'delete') {
    json_response(['ok' => false, 'error' => 'Confirmation required'], 400);
}

$stmt = $pdo->prepare('SELECT password_hash FROM xd_users WHERE username = ? AND deleted_at IS NULL LIMIT 1');
$stmt->execute([$username]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$row || empty($row['password_hash'])) {
    json_response(['ok' => false, 'error' => 'User not found'], 404);
}
if (!password_verify($password, (string) $row['password_hash'])) {
    json_response(['ok' => false, 'error' => 'Invalid password'], 403);
}

$pdo->beginTransaction();
try {
    $pdo->prepare('DELETE FROM xd_sessions WHERE username = ?')->execute([$username]);

    try {
        $pdo->prepare('DELETE FROM xonadosh_listings WHERE username = ?')->execute([$username]);
    } catch (Throwable $e) {
        // ignore
    }
    try {
        $pdo->prepare('DELETE FROM xonadosh_profiles WHERE username = ?')->execute([$username]);
    } catch (Throwable $e) {
        // ignore
    }

    $del = $pdo->prepare('UPDATE xd_users SET deleted_at = NOW(), phone = NULL WHERE username = ? AND deleted_at IS NULL');
    $del->execute([$username]);
    if ($del->rowCount() < 1) {
        throw new RuntimeException('Delete failed');
    }

    $pdo->commit();
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('account_delete failed: ' . $e->getMessage());
    json_response(['ok' => false, 'error' => 'Delete failed'], 500);
}

json_response(['ok' => true, 'deleted' => true]);
