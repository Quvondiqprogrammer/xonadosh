<?php
declare(strict_types=1);

/**
 * API: Roommate Chore Swap & Proof-of-Clean System
 * "Bugun darsim ko'p, navbatni almashtiraylik" va bajarilgan ish rasmini yuklash
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

// Table setup
if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_chore_swaps` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL,
            `chore_id` INT NOT NULL,
            `requester_name` VARCHAR(100) NOT NULL,
            `target_name` VARCHAR(100) NULL,
            `reason` VARCHAR(255) NOT NULL,
            `status` ENUM('pending','accepted','declined') NOT NULL DEFAULT 'pending',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_group_swap` (`group_code`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        // Safe column addition for proof_photo_url on xonadosh_chores
        $cols = $pdo->query("SHOW COLUMNS FROM `xonadosh_chores`")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('proof_photo_url', $cols, true)) {
            $pdo->exec("ALTER TABLE `xonadosh_chores` ADD COLUMN `proof_photo_url` VARCHAR(255) NULL AFTER `is_completed`");
        }
    } catch (Throwable $e) {}
}

$raw = file_get_contents('php://input');
$body = json_decode($raw ?: '{}', true);
if (!is_array($body)) {
    $body = $_POST;
}

$groupCode = xonadosh_get_group_code($body['group_code'] ?? ($_GET['group_code'] ?? null));
$action = $body['action'] ?? ($_GET['action'] ?? 'list');

if ($action === 'list') {
    $stmt = $pdo->prepare("SELECT s.*, c.title AS chore_title, c.day_of_week, c.time_slot 
        FROM `xonadosh_chore_swaps` s 
        LEFT JOIN `xonadosh_chores` c ON c.id = s.chore_id 
        WHERE s.group_code = ? AND s.status = 'pending' 
        ORDER BY s.id DESC");
    $stmt->execute([$groupCode]);
    $swaps = $stmt->fetchAll();

    json_response([
        'ok' => true,
        'group_code' => $groupCode,
        'swaps' => $swaps
    ]);
}

if ($action === 'request_swap') {
    $choreId = (int)($body['chore_id'] ?? 0);
    $requester = trim((string)($body['requester_name'] ?? 'Men'));
    $target = trim((string)($body['target_name'] ?? ''));
    $reason = trim((string)($body['reason'] ?? 'Bugun darsim ko‘p, navbatni almashtiraylik'));

    if ($choreId <= 0) {
        json_response(['ok' => false, 'error' => 'chore_id talab qilinadi'], 400);
    }

    $stmt = $pdo->prepare("INSERT INTO `xonadosh_chore_swaps` (`group_code`, `chore_id`, `requester_name`, `target_name`, `reason`, `status`) 
        VALUES (?, ?, ?, ?, ?, 'pending')");
    $stmt->execute([$groupCode, $choreId, $requester, $target ?: null, $reason]);
    $swapId = (int)$pdo->lastInsertId();

    json_response([
        'ok' => true,
        'message' => 'Navbatchilikni almashtirish so‘rovi xonadoshlarga yuborildi!',
        'swap_id' => $swapId
    ]);
}

if ($action === 'accept_swap') {
    $swapId = (int)($body['swap_id'] ?? 0);
    $acceptedBy = trim((string)($body['accepted_by'] ?? 'Sherik'));

    $stmt = $pdo->prepare("SELECT * FROM `xonadosh_chore_swaps` WHERE id = ?");
    $stmt->execute([$swapId]);
    $swap = $stmt->fetch();

    if (!$swap) {
        json_response(['ok' => false, 'error' => 'So‘rov topilmadi'], 404);
    }

    // 1. Update chore assignee
    $upChore = $pdo->prepare("UPDATE `xonadosh_chores` SET `assigned_name` = ? WHERE `id` = ?");
    $upChore->execute([$acceptedBy, (int)$swap['chore_id']]);

    // 2. Mark swap accepted
    $upSwap = $pdo->prepare("UPDATE `xonadosh_chore_swaps` SET `status` = 'accepted' WHERE `id` = ?");
    $upSwap->execute([$swapId]);

    json_response([
        'ok' => true,
        'message' => "Rahmat! Navbatchilik {$acceptedBy} ga muvaffaqiyatli o‘tkazildi.",
        'swap_id' => $swapId,
        'new_assigned_name' => $acceptedBy
    ]);
}

if ($action === 'upload_proof') {
    $choreId = (int)($body['chore_id'] ?? 0);
    $proofPhotoUrl = trim((string)($body['proof_photo_url'] ?? ''));
    $completedBy = trim((string)($body['completed_by'] ?? ''));

    if ($choreId <= 0 || $proofPhotoUrl === '') {
        json_response(['ok' => false, 'error' => 'chore_id va proof_photo_url talab qilinadi'], 400);
    }

    $stmt = $pdo->prepare("UPDATE `xonadosh_chores` SET `is_completed` = 1, `completed_at` = NOW(), `proof_photo_url` = ? WHERE `id` = ?");
    $stmt->execute([$proofPhotoUrl, $choreId]);

    // Reward with Karma points for cleanliness proof
    try {
        if ($completedBy !== '') {
            $kStmt = $pdo->prepare("INSERT INTO `xonadosh_karma` (`group_code`, `username`, `points`, `action_type`, `description`) 
                VALUES (?, ?, 15, 'clean_proof', 'Navbatchilikni foto-isbot bilan a’lo darajada bajardi')");
            $kStmt->execute([$groupCode, $completedBy]);
        }
    } catch (Throwable $e) {}

    json_response([
        'ok' => true,
        'message' => 'Tozalik isboti (foto) yuklandi va navbatchilik tasdiqlandi! +15 Karma olindi.',
        'chore_id' => $choreId,
        'proof_photo_url' => $proofPhotoUrl
    ]);
}

json_response(['ok' => false, 'error' => 'Noma’lum amal'], 400);
