<?php
declare(strict_types=1);

/**
 * API: Upload listing / profile photo (multipart).
 * Web + mobile Flutter clients use the same endpoint.
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

auth_require_token($pdo);

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    json_response(['ok' => false, 'error' => 'POST required'], 405);
}

if (!isset($_FILES['file']) || !is_array($_FILES['file'])) {
    json_response(['ok' => false, 'error' => 'file field required'], 400);
}

$file = $_FILES['file'];
if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    json_response(['ok' => false, 'error' => 'Upload failed (code ' . (int)($file['error'] ?? 0) . ')'], 400);
}

$maxBytes = 5 * 1024 * 1024; // 5 MB
$size = (int)($file['size'] ?? 0);
if ($size <= 0 || $size > $maxBytes) {
    json_response(['ok' => false, 'error' => 'File too large (max 5MB)'], 400);
}

$tmp = (string)($file['tmp_name'] ?? '');
if ($tmp === '' || !is_uploaded_file($tmp)) {
    json_response(['ok' => false, 'error' => 'Invalid upload'], 400);
}

$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($tmp) ?: '';
$allowed = [
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
];
if (!isset($allowed[$mime])) {
    json_response(['ok' => false, 'error' => 'Only JPEG/PNG/WebP/GIF allowed'], 400);
}

$ext = $allowed[$mime];
$dir = dirname(__DIR__) . '/uploads/listings';
if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
    json_response(['ok' => false, 'error' => 'Cannot create upload dir'], 500);
}

$name = bin2hex(random_bytes(16)) . '.' . $ext;
$dest = $dir . '/' . $name;
if (!move_uploaded_file($tmp, $dest)) {
    json_response(['ok' => false, 'error' => 'Failed to save file'], 500);
}

@chmod($dest, 0644);

$base = rtrim((string)($cfg['base_url'] ?? 'https://honadosh.uz'), '/');
$url = $base . '/uploads/listings/' . $name;

json_response([
    'ok' => true,
    'url' => $url,
    'mime' => $mime,
    'size' => $size,
]);
