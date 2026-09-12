<?php

declare(strict_types=1);

if (!defined('JSON_THROW_ON_ERROR')) {
    define('JSON_THROW_ON_ERROR', 4194304);
}

@ini_set('display_errors', '0');
@ini_set('display_startup_errors', '0');
@ini_set('log_errors', '1');
error_reporting(E_ALL);

if (!function_exists('str_contains')) {
    function str_contains(string $haystack, string $needle): bool
    {
        return $needle === '' || strpos($haystack, $needle) !== false;
    }
}
if (!function_exists('str_starts_with')) {
    function str_starts_with(string $haystack, string $needle): bool
    {
        return strncmp($haystack, $needle, strlen($needle)) === 0;
    }
}
if (!function_exists('str_ends_with')) {
    function str_ends_with(string $haystack, string $needle): bool
    {
        return $needle === '' || substr_compare($haystack, $needle, -strlen($needle)) === 0;
    }
}

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');
header('Pragma: no-cache');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept, Origin, User-Agent, If-None-Match, X-Requested-With, X-Auth-Token, X-CSRF-Token');
header('Access-Control-Max-Age: 86400');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(200);
    exit;
}

/**
 * JSON API response helper.
 */
function json_response(array $data, int $code = 200): void
{
    http_response_code($code);
    try {
        $json = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
        if ($json === false) {
            $json = json_encode(['ok' => false, 'error' => 'JSON encoding error: ' . json_last_error_msg()]);
        }
        echo $json;
    } catch (Throwable $e) {
        echo json_encode(['ok' => false, 'error' => 'JSON exception: ' . $e->getMessage()]);
    }
    exit;
}

$configPath = dirname(__DIR__) . '/config.local.php';
if (!is_readable($configPath)) {
    json_response(['ok' => false, 'error' => 'Server config missing (copy config.example.php to config.local.php)'], 500);
}

/** @var array $cfg */
$cfg = require $configPath;

foreach (['db_host', 'db_name', 'db_user', 'db_pass'] as $key) {
    if (!isset($cfg[$key]) || $cfg[$key] === '') {
        json_response(['ok' => false, 'error' => 'Incomplete DB config'], 500);
    }
}
