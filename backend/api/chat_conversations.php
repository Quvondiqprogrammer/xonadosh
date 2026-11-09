<?php
declare(strict_types=1);

/**
 * API: List all chat conversations for the authenticated user.
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

$user = auth_require_token($pdo);
$username = (string)$user['username'];

// Ensure chat tables exist
try {
    $pdo->query("SELECT 1 FROM `xd_conversations` LIMIT 1");
} catch (Throwable $e) {
    // Run lazy migration if not created yet
    $pdo->exec("CREATE TABLE IF NOT EXISTS `xd_conversations` (
        `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
        `type` ENUM('direct','coliving_group','listing_inquiry') NOT NULL DEFAULT 'direct',
        `listing_id` INT NULL,
        `coliving_group_code` VARCHAR(50) NULL,
        `title` VARCHAR(150) NULL,
        `last_message_text` VARCHAR(255) NULL,
        `last_message_sender` VARCHAR(100) NULL,
        `last_message_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_last_msg` (`last_message_at`),
        INDEX `idx_listing` (`listing_id`),
        INDEX `idx_group` (`coliving_group_code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $pdo->exec("CREATE TABLE IF NOT EXISTS `xd_chat_participants` (
        `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
        `conversation_id` BIGINT NOT NULL,
        `username` VARCHAR(100) NOT NULL,
        `unread_count` INT NOT NULL DEFAULT 0,
        `last_read_at` DATETIME NULL,
        `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY `uk_conv_user` (`conversation_id`, `username`),
        INDEX `idx_user` (`username`),
        INDEX `idx_conv` (`conversation_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $pdo->exec("CREATE TABLE IF NOT EXISTS `xd_chat_messages` (
        `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
        `conversation_id` BIGINT NOT NULL,
        `sender_username` VARCHAR(100) NOT NULL,
        `message_type` ENUM('text','image','location','system_event') NOT NULL DEFAULT 'text',
        `body` TEXT NOT NULL,
        `metadata_json` JSON NULL,
        `is_read` TINYINT(1) NOT NULL DEFAULT 0,
        `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_conv_time` (`conversation_id`, `created_at`),
        INDEX `idx_sender` (`sender_username`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
}

$stmt = $pdo->prepare(
    "SELECT c.id, c.type, c.listing_id, c.coliving_group_code, c.title,
            c.last_message_text, c.last_message_sender, c.last_message_at, c.created_at,
            cp.unread_count, cp.last_read_at
     FROM xd_chat_participants cp
     JOIN xd_conversations c ON c.id = cp.conversation_id
     WHERE cp.username = ?
     ORDER BY c.last_message_at DESC
     LIMIT 50"
);
$stmt->execute([$username]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$conversations = [];

foreach ($rows as $r) {
    $convId = (int)$r['id'];

    // Get other participant(s)
    $partStmt = $pdo->prepare(
        "SELECT cp.username, u.full_name, u.avatar_url, p.avatar_url as profile_avatar, p.full_name as profile_name
         FROM xd_chat_participants cp
         LEFT JOIN xd_users u ON u.username = cp.username
         LEFT JOIN xonadosh_profiles p ON p.username = cp.username
         WHERE cp.conversation_id = ? AND cp.username != ?
         LIMIT 1"
    );
    $partStmt->execute([$convId, $username]);
    $other = $partStmt->fetch(PDO::FETCH_ASSOC);

    $otherUsername = $other ? (string)$other['username'] : '';
    $otherName = $other ? ($other['profile_name'] ?: ($other['full_name'] ?: $otherUsername)) : ($r['title'] ?: 'Xonadosh suhbati');
    $otherAvatar = $other ? ($other['profile_avatar'] ?: ($other['avatar_url'] ?: '')) : '';

    // Attached listing info if inquiry
    $listingInfo = null;
    if (!empty($r['listing_id'])) {
        $lStmt = $pdo->prepare("SELECT id, title, price, photos_json, district FROM xonadosh_listings WHERE id = ?");
        $lStmt->execute([(int)$r['listing_id']]);
        $lRow = $lStmt->fetch(PDO::FETCH_ASSOC);
        if ($lRow) {
            $photos = json_decode((string)($lRow['photos_json'] ?? '[]'), true);
            $listingInfo = [
                'id' => (int)$lRow['id'],
                'title' => (string)$lRow['title'],
                'price' => (float)$lRow['price'],
                'district' => (string)($lRow['district'] ?? ''),
                'thumb' => is_array($photos) && count($photos) > 0 ? (string)$photos[0] : null,
            ];
        }
    }

    $conversations[] = [
        'id' => $convId,
        'type' => (string)$r['type'],
        'title' => $otherName,
        'other_username' => $otherUsername,
        'avatar_url' => $otherAvatar,
        'last_message' => (string)($r['last_message_text'] ?? ''),
        'last_message_sender' => (string)($r['last_message_sender'] ?? ''),
        'last_message_at' => (string)$r['last_message_at'],
        'unread_count' => (int)$r['unread_count'],
        'listing' => $listingInfo,
        'coliving_group_code' => $r['coliving_group_code'],
    ];
}

json_response([
    'ok' => true,
    'conversations' => $conversations,
    'total' => count($conversations),
]);
