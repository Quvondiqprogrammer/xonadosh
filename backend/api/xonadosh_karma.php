<?php
declare(strict_types=1);
/**
 * API: Roommate Karma & Peer Reputation System
 * - Xonadoshlar o'zaro bir-biriga obro' / karma berishi va nishonlar topshirishi
 */
require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    $pdo = null;
}

$groupCode = trim($_GET['group_code'] ?? 'home_default');
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Ensure table exists
if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_karma` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
            `from_name` VARCHAR(100) NOT NULL,
            `to_name` VARCHAR(100) NOT NULL,
            `badge_key` VARCHAR(50) NOT NULL,
            `badge_name` VARCHAR(100) NOT NULL,
            `comment` TEXT NULL,
            `points` INT NOT NULL DEFAULT 1,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_group_to` (`group_code`, `to_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    } catch (Throwable $e) {}
}

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?? $_POST;
    $action = $body['action'] ?? 'give_karma';

    if ($action === 'give_karma') {
        $fromName  = trim((string)($body['from_name'] ?? 'Xonadosh'));
        $toName    = trim((string)($body['to_name'] ?? ''));
        $badgeKey  = trim((string)($body['badge_key'] ?? 'cleanliness_master'));
        $badgeName = trim((string)($body['badge_name'] ?? 'Tozalik ustasi'));
        $comment   = trim((string)($body['comment'] ?? ''));
        $points    = max(1, min(5, (int)($body['points'] ?? 1)));
        $gCode     = trim((string)($body['group_code'] ?? $groupCode));

        if (empty($toName)) {
            json_response(['ok' => false, 'error' => 'Kimgadir obro‘ berish uchun xonadosh tanlanishi shart'], 400);
        }

        if (strcasecmp($fromName, $toName) === 0) {
            json_response(['ok' => false, 'error' => 'O‘zingizga obro‘ bera olmaysiz!'], 400);
        }

        if ($pdo) {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_karma` (`group_code`, `from_name`, `to_name`, `badge_key`, `badge_name`, `comment`, `points`, `created_at`) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())");
            $stmt->execute([$gCode, $fromName, $toName, $badgeKey, $badgeName, $comment, $points]);
        }

        json_response([
            'ok' => true,
            'message' => "🎉 {$toName}ga \"{$badgeName}\" nishoni va +{$points} obro‘ berildi!",
        ]);
    }
}

// Available Badges master catalog
$availableBadges = [
    ['key' => 'cleanliness_master', 'name' => 'Tozalik ustasi', 'icon' => '🧹', 'description' => 'Xonani chinnidek toza tutgani va navbatchilikni a’lo bajargani uchun'],
    ['key' => 'chef_pro',           'name' => 'Mohir oshpaz',   'icon' => '👨‍🍳', 'description' => 'Mazali, to‘yimli taomlar tayyorlab xonadoshlarni xushnud qilgani uchun'],
    ['key' => 'ontime_payer',       'name' => 'Vaqtida to‘lovchi','icon' => '⏱', 'description' => 'Ijara, kommunal va umumiy xarajatlarni hech kechiktirmay to‘lagani uchun'],
    ['key' => 'quiet_peacekeeper',  'name' => 'Tinchlik posboni','icon' => '🤫', 'description' => 'Kechki payt va dars paytida osoyishtalikni saqlagani uchun'],
    ['key' => 'helpful_friend',     'name' => 'Do‘stona xonadosh','icon' => '🤝', 'description' => 'Har qanday vaziyatda yordamga shay, samimiy va ishonchli bo‘lgani uchun'],
    ['key' => 'wake_up_hero',       'name' => 'Tonggi uyg‘otuvchi','icon' => '⏰', 'description' => 'Darsga kechikmaslik uchun barchani o‘z vaqtida uyg‘otgani uchun'],
];

// Default roommates list
$roommates = ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];

$records = [];
if ($pdo) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM `xonadosh_karma` WHERE `group_code` = ? ORDER BY `id` DESC LIMIT 100");
        $stmt->execute([$groupCode]);
        $records = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Throwable $e) {}
}

// If database has no karma records yet, provide rich defaults
if (empty($records)) {
    $records = [
        ['id' => 1, 'from_name' => 'Azizbek', 'to_name' => 'Jasur', 'badge_key' => 'chef_pro', 'badge_name' => 'Mohir oshpaz', 'points' => 3, 'comment' => 'Dushanba kungi palov juda mazali chiqdi!', 'created_at' => date('Y-m-d H:i:s', strtotime('-1 day'))],
        ['id' => 2, 'from_name' => 'Jasur', 'to_name' => 'Bekzod', 'badge_key' => 'cleanliness_master', 'badge_name' => 'Tozalik ustasi', 'points' => 2, 'comment' => 'Oshxona va zalni chinnidek yuvib qo‘ydi', 'created_at' => date('Y-m-d H:i:s', strtotime('-2 days'))],
        ['id' => 3, 'from_name' => 'Sardor', 'to_name' => 'Azizbek', 'badge_key' => 'ontime_payer', 'badge_name' => 'Vaqtida to‘lovchi', 'points' => 3, 'comment' => 'Wi-Fi va svet pulini 1-bo‘lib to‘ladi', 'created_at' => date('Y-m-d H:i:s', strtotime('-3 days'))],
        ['id' => 4, 'from_name' => 'Bekzod', 'to_name' => 'Sardor', 'badge_key' => 'quiet_peacekeeper', 'badge_name' => 'Tinchlik posboni', 'points' => 2, 'comment' => 'Imtihon oldidan kechasi juda sokin muhit yaratdi', 'created_at' => date('Y-m-d H:i:s', strtotime('-4 days'))],
        ['id' => 5, 'from_name' => 'Jasur', 'to_name' => 'Azizbek', 'badge_key' => 'helpful_friend', 'badge_name' => 'Do‘stona xonadosh', 'points' => 2, 'comment' => 'Bozorlik yuklarini ko‘tarishda yordam berdi', 'created_at' => date('Y-m-d H:i:s', strtotime('-5 days'))],
    ];
}

// Aggregate karma stats per roommate
$stats = [];
foreach ($roommates as $name) {
    $stats[$name] = [
        'name' => $name,
        'total_points' => 0,
        'badges_count' => 0,
        'badges_summary' => [],
        'recent_praises' => []
    ];
}

foreach ($records as $r) {
    $to = $r['to_name'];
    if (!isset($stats[$to])) {
        $stats[$to] = [
            'name' => $to,
            'total_points' => 0,
            'badges_count' => 0,
            'badges_summary' => [],
            'recent_praises' => []
        ];
    }
    $pts = (int)($r['points'] ?? 1);
    $bKey = $r['badge_key'] ?? 'helpful_friend';
    $bName = $r['badge_name'] ?? 'Do‘stona xonadosh';

    $stats[$to]['total_points'] += $pts;
    $stats[$to]['badges_count'] += 1;

    if (!isset($stats[$to]['badges_summary'][$bKey])) {
        $stats[$to]['badges_summary'][$bKey] = ['key' => $bKey, 'name' => $bName, 'count' => 0];
    }
    $stats[$to]['badges_summary'][$bKey]['count'] += 1;

    if (count($stats[$to]['recent_praises']) < 3) {
        $stats[$to]['recent_praises'][] = [
            'from_name' => $r['from_name'],
            'badge_name' => $bName,
            'comment' => $r['comment'] ?? '',
            'created_at' => $r['created_at'] ?? ''
        ];
    }
}

// Convert badges_summary to indexed array and sort roommates by highest karma
$roommateLeaderboard = array_values($stats);
foreach ($roommateLeaderboard as &$rm) {
    $rm['badges_summary'] = array_values($rm['badges_summary']);
}
unset($rm);

usort($roommateLeaderboard, fn($a, $b) => $b['total_points'] <=> $a['total_points']);

json_response([
    'ok' => true,
    'group_code' => $groupCode,
    'available_badges' => $availableBadges,
    'roommates' => $roommates,
    'leaderboard' => $roommateLeaderboard,
    'history' => $records
]);
