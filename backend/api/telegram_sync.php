<?php
declare(strict_types=1);

/**
 * API: Household Telegram Group Bot Synchronization & Notification Hub
 * Xonadon Telegram guruhiga bildirishnomalar yuborish:
 * - Ijara to'lovi kuni
 * - Bugungi navbatchi
 * - Bugungi taom
 * - Bozorlik ro'yxati
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';
require_once dirname(__DIR__) . '/includes/xonadosh_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    $pdo = null;
}

if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_telegram_chats` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL,
            `chat_id` VARCHAR(100) NOT NULL,
            `chat_title` VARCHAR(150) NULL,
            `is_active` TINYINT NOT NULL DEFAULT 1,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uq_group_chat` (`group_code`, `chat_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    } catch (Throwable $e) {}
}

$raw = file_get_contents('php://input');
$body = json_decode($raw ?: '{}', true);
if (!is_array($body)) {
    $body = $_POST;
}

$groupCode = xonadosh_get_group_code($body['group_code'] ?? ($_GET['group_code'] ?? null));
$action = $body['action'] ?? ($_GET['action'] ?? 'status');

if ($action === 'bind_chat') {
    $chatId = trim((string)($body['chat_id'] ?? ''));
    $chatTitle = trim((string)($body['chat_title'] ?? 'Xonadon Guruhi'));

    if ($chatId === '') {
        json_response(['ok' => false, 'error' => 'chat_id talab qilinadi'], 400);
    }

    if ($pdo) {
        $stmt = $pdo->prepare("INSERT INTO `xonadosh_telegram_chats` (`group_code`, `chat_id`, `chat_title`) 
            VALUES (?, ?, ?) 
            ON DUPLICATE KEY UPDATE `chat_title` = VALUES(`chat_title`), `is_active` = 1");
        $stmt->execute([$groupCode, $chatId, $chatTitle]);
    }

    json_response([
        'ok' => true,
        'message' => "Telegram guruh muvaffaqiyatli ulandi! Endi barcha navbatchilik va ijara eslatmalari guruhga tushadi.",
        'group_code' => $groupCode,
        'chat_id' => $chatId
    ]);
}

if ($action === 'format_daily_digest') {
    // Collect today's chore, today's meal, upcoming bills
    $today = date('Y-m-d');
    $dayOfWeek = strtolower(substr(date('D'), 0, 3)); // mon, tue, etc.

    $chore = null;
    $meal = null;
    $unpaidBills = [];

    if ($pdo) {
        // Today's chore
        $cStmt = $pdo->prepare("SELECT * FROM `xonadosh_chores` WHERE `group_code` = ? AND `day_of_week` = ? LIMIT 1");
        $cStmt->execute([$groupCode, $dayOfWeek]);
        $chore = $cStmt->fetch();

        // Today's meal
        $mStmt = $pdo->prepare("SELECT m.*, r.title, r.estimated_cost_per_person 
            FROM `xonadosh_meal_plans` m 
            JOIN `xonadosh_recipes` r ON r.id = m.recipe_id 
            WHERE m.group_code = ? AND m.day_of_week = ? LIMIT 1");
        $mStmt->execute([$groupCode, $dayOfWeek]);
        $meal = $mStmt->fetch();

        // Pending bills
        $bStmt = $pdo->prepare("SELECT * FROM `xonadosh_finances` WHERE `group_code` = ? AND `status` != 'settled' LIMIT 3");
        $bStmt->execute([$groupCode]);
        $unpaidBills = $bStmt->fetchAll();
    }

    $msg = "☀️ *XAYRLI TONG, XONADOSHLAR!*\n" .
           "🏠 Xonadon: *{$groupCode}*\n" .
           "📅 Bugun: *" . date('d.m.Y (l)') . "*\n\n";

    if ($chore) {
        $msg .= "🧹 *Bugungi navbatchi:* *" . ($chore['assigned_name'] ?: 'Belgilanmagan') . "*\n" .
                "📌 Vazifa: {$chore['title']}\n\n";
    } else {
        $msg .= "🧹 *Navbatchilik:* Bugun umumiy dam olish kuni!\n\n";
    }

    if ($meal) {
        $msg .= "🍲 *Kechki taom:* *" . $meal['title'] . "*\n" .
                "💰 Taxminiy xarajat (1 kishiga): " . number_format((int)$meal['estimated_cost_per_person'], 0, '', ' ') . " so'm\n\n";
    }

    if (!empty($unpaidBills)) {
        $msg .= "💳 *Kutilayotgan to'lovlar:*\n";
        foreach ($unpaidBills as $b) {
            $msg .= "• {$b['title']}: *" . number_format((int)$b['amount_uzs'], 0, '', ' ') . " so'm*\n";
        }
        $msg .= "\n";
    }

    $msg .= "📱 _XonaDosh ilovasida to'liq ko'rish: https://xonadoshim.uz/app/_";

    json_response([
        'ok' => true,
        'group_code' => $groupCode,
        'digest_text' => $msg,
        'telegram_share_url' => "https://t.me/share/url?url=" . urlencode("https://xonadoshim.uz/join/{$groupCode}") . "&text=" . urlencode($msg)
    ]);
}

json_response([
    'ok' => true,
    'bot_username' => '@xonadosh_bot',
    'bot_link' => 'https://t.me/xonadosh_bot?start=' . urlencode($groupCode),
    'instructions' => "Telegram guruhingizga @xonadosh_bot ni admin qilib qo'shing va /start buyrug'ini yuboring."
]);
