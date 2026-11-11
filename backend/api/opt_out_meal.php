<?php
declare(strict_types=1);

/**
 * API: "Bugun ovqatlanmayman" (Opt-out Meal & Grocery Split System)
 * Talaba darsda, ishda yoki safarda bo'lganda o'sha kungi xarajatdan adolatli chegirish
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';
require_once dirname(__DIR__) . '/includes/xonadosh_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_meal_opt_outs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL,
            `username` VARCHAR(100) NOT NULL,
            `opt_out_date` DATE NOT NULL,
            `meal_slot` ENUM('all','breakfast','lunch','dinner') NOT NULL DEFAULT 'all',
            `reason` VARCHAR(255) NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uq_user_date_slot` (`group_code`, `username`, `opt_out_date`, `meal_slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    } catch (Throwable $e) {}
}

$raw = file_get_contents('php://input');
$body = json_decode($raw ?: '{}', true);
if (!is_array($body)) {
    $body = $_POST;
}

$groupCode = xonadosh_get_group_code($body['group_code'] ?? ($_GET['group_code'] ?? null));
$action = $body['action'] ?? ($_GET['action'] ?? 'get_today');
$today = date('Y-m-d');

if ($action === 'get_today' || $action === 'list') {
    $targetDate = trim((string)($body['date'] ?? ($_GET['date'] ?? $today)));
    $stmt = $pdo->prepare("SELECT * FROM `xonadosh_meal_opt_outs` WHERE `group_code` = ? AND `opt_out_date` = ?");
    $stmt->execute([$groupCode, $targetDate]);
    $optOuts = $stmt->fetchAll();

    json_response([
        'ok' => true,
        'group_code' => $groupCode,
        'date' => $targetDate,
        'opt_out_users' => array_column($optOuts, 'username'),
        'details' => $optOuts
    ]);
}

if ($action === 'opt_out') {
    $username = trim((string)($body['username'] ?? 'Men'));
    $date = trim((string)($body['date'] ?? $today));
    $slot = (string)($body['meal_slot'] ?? 'all');
    $reason = trim((string)($body['reason'] ?? 'Bugun darsdaman / uyda ovqatlanmayman'));

    if (!in_array($slot, ['all', 'breakfast', 'lunch', 'dinner'], true)) {
        $slot = 'all';
    }

    $stmt = $pdo->prepare("INSERT INTO `xonadosh_meal_opt_outs` (`group_code`, `username`, `opt_out_date`, `meal_slot`, `reason`) 
        VALUES (?, ?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE `reason` = VALUES(`reason`), `meal_slot` = VALUES(`meal_slot`)");
    $stmt->execute([$groupCode, $username, $date, $slot, $reason]);

    json_response([
        'ok' => true,
        'message' => "Qayd etildi! {$username} bugun ({$date}) ovqatlanmaydi va bugungi bozorlik hisobidan chegiriladi.",
        'opt_out_date' => $date,
        'username' => $username,
        'is_opted_out' => true
    ]);
}

if ($action === 'cancel_opt_out') {
    $username = trim((string)($body['username'] ?? 'Men'));
    $date = trim((string)($body['date'] ?? $today));

    $stmt = $pdo->prepare("DELETE FROM `xonadosh_meal_opt_outs` WHERE `group_code` = ? AND `username` = ? AND `opt_out_date` = ?");
    $stmt->execute([$groupCode, $username, $date]);

    json_response([
        'ok' => true,
        'message' => "Bekor qilindi! {$username} yana ovqatlanuvchilar ro‘yxatiga qo‘shildi.",
        'is_opted_out' => false
    ]);
}

json_response(['ok' => false, 'error' => 'Noma’lum amal'], 400);
