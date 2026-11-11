<?php
declare(strict_types=1);

/**
 * API: Upload listing / profile photo (multipart).
 * Automatically optimizes images via GD:
 * - Auto-corrects EXIF rotation
 * - Downsamples oversized photos to max 1440px
 * - Encodes to high-efficiency WebP format (82% quality)
 * - Generates micro-thumbnails (360px) for fast feed rendering
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

$maxBytes = 15 * 1024 * 1024; // Up to 15MB before compression
$size = (int)($file['size'] ?? 0);
if ($size <= 0 || $size > $maxBytes) {
    json_response(['ok' => false, 'error' => 'File too large (max 15MB)'], 400);
}

$tmp = (string)($file['tmp_name'] ?? '');
if ($tmp === '' || !is_uploaded_file($tmp)) {
    json_response(['ok' => false, 'error' => 'Invalid upload'], 400);
}

$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($tmp) ?: '';
$allowed = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
    'image/gif'  => 'gif',
];
if (!isset($allowed[$mime])) {
    json_response(['ok' => false, 'error' => 'Faqat JPEG, PNG, WebP yoki GIF formatdagi rasmlar qabul qilinadi'], 400);
}

$dir = dirname(__DIR__) . '/uploads/listings';
if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
    json_response(['ok' => false, 'error' => 'Yuklash papkasini yaratib bo‘lmadi'], 500);
}

$hash = bin2hex(random_bytes(16));
$mainName = $hash . '.webp';
$thumbName = $hash . '_thumb.webp';
$destMain = $dir . '/' . $mainName;
$destThumb = $dir . '/' . $thumbName;

$savedWidth = 0;
$savedHeight = 0;
$finalSize = 0;
$hasThumb = false;

// Attempt GD optimization
$optimized = false;
if (extension_loaded('gd') && function_exists('imagewebp')) {
    try {
        $sourceImg = @imagecreatefromstring((string)file_get_contents($tmp));
        if ($sourceImg !== false) {
            // EXIF Orientation check for JPEG
            if ($mime === 'image/jpeg' && function_exists('exif_read_data')) {
                $exif = @exif_read_data($tmp);
                $orientation = $exif['Orientation'] ?? 1;
                switch ($orientation) {
                    case 3:
                        $sourceImg = imagerotate($sourceImg, 180, 0);
                        break;
                    case 6:
                        $sourceImg = imagerotate($sourceImg, -90, 0);
                        break;
                    case 8:
                        $sourceImg = imagerotate($sourceImg, 90, 0);
                        break;
                }
            }

            $origW = imagesx($sourceImg);
            $origH = imagesy($sourceImg);

            // 1. Main image: Max 1440px bounding box
            $maxDim = 1440;
            $scale = min(1.0, $maxDim / max($origW, $origH));
            $newW = (int)round($origW * $scale);
            $newH = (int)round($origH * $scale);

            if ($scale < 1.0) {
                $mainImg = imagescale($sourceImg, $newW, $newH, IMG_BILINEAR_FIXED);
            } else {
                $mainImg = $sourceImg;
            }

            if ($mainImg !== false) {
                // Ensure alpha transparency is preserved for PNG/WebP
                imagealphablending($mainImg, true);
                imagesavealpha($mainImg, true);

                if (imagewebp($mainImg, $destMain, 82)) {
                    $savedWidth = $newW;
                    $savedHeight = $newH;
                    $finalSize = (int)filesize($destMain);
                    $optimized = true;
                }
            }

            // 2. Micro Thumbnail: Max 360px bounding box
            $thumbDim = 360;
            $thumbScale = min(1.0, $thumbDim / max($origW, $origH));
            $thumbW = (int)round($origW * $thumbScale);
            $thumbH = (int)round($origH * $thumbScale);
            $thumbImg = imagescale($sourceImg, $thumbW, $thumbH, IMG_BILINEAR_FIXED);
            if ($thumbImg !== false) {
                imagealphablending($thumbImg, true);
                imagesavealpha($thumbImg, true);
                if (imagewebp($thumbImg, $destThumb, 75)) {
                    $hasThumb = true;
                    @chmod($destThumb, 0644);
                }
            }
        }
    } catch (Throwable $e) {
        $optimized = false;
    }
}

// Fallback to direct upload if GD failed
if (!$optimized) {
    $fallbackName = $hash . '.' . $allowed[$mime];
    $destMain = $dir . '/' . $fallbackName;
    if (!move_uploaded_file($tmp, $destMain)) {
        json_response(['ok' => false, 'error' => 'Faylni saqlashda xatolik yuz berdi'], 500);
    }
    $mainName = $fallbackName;
    $finalSize = (int)filesize($destMain);
}

@chmod($destMain, 0644);

$base = rtrim((string)($cfg['base_url'] ?? 'https://xonadoshim.uz'), '/');
$url = $base . '/uploads/listings/' . $mainName;
$thumbUrl = $hasThumb ? ($base . '/uploads/listings/' . $thumbName) : $url;

json_response([
    'ok' => true,
    'url' => $url,
    'thumb_url' => $thumbUrl,
    'mime' => $optimized ? 'image/webp' : $mime,
    'size' => $finalSize,
    'width' => $savedWidth,
    'height' => $savedHeight,
    'optimized' => $optimized,
]);
