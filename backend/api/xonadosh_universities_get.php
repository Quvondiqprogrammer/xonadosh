<?php
declare(strict_types=1);

/**
 * API: Get Universities for Xonadosh Hub
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

$city = isset($_GET['city']) && is_string($_GET['city']) ? trim($_GET['city']) : null;
$q = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : null;

$sql = "SELECT id, name_uz, short_name, city, district, address, latitude, longitude, nearest_metro, metro_distance_m FROM `xonadosh_universities` WHERE 1=1";
$params = [];

if ($city !== null && $city !== '' && $city !== 'Barchasi') {
    $sql .= " AND `city` = ?";
    $params[] = $city;
}

if ($q !== null && $q !== '') {
    $sql .= " AND (`name_uz` LIKE ? OR `short_name` LIKE ? OR `district` LIKE ?)";
    $like = '%' . $q . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$sql .= " ORDER BY CASE WHEN `city` = 'Toshkent' THEN 0 ELSE 1 END, `name_uz` ASC";

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($items as &$item) {
        $item['id'] = (int)$item['id'];
        $item['latitude'] = (float)$item['latitude'];
        $item['longitude'] = (float)$item['longitude'];
        $item['metro_distance_m'] = $item['metro_distance_m'] !== null ? (int)$item['metro_distance_m'] : null;
    }
    unset($item);

    json_response([
        'ok' => true,
        'count' => count($items),
        'universities' => $items
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
