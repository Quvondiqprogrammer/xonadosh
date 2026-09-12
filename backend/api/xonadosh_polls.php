<?php
declare(strict_types=1);
/**
 * API: Anonymous Topic Proposal & Poll/Voting System
 * - Xonadon ichida anonim masala/taklif tashlash va anonim ovoz berish
 */
require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    $pdo = null;
}

$groupCode = trim($_GET['group_code'] ?? 'home_default');
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Ensure tables exist
if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_polls` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
            `title` VARCHAR(255) NOT NULL,
            `description` TEXT NULL,
            `category` VARCHAR(50) NOT NULL DEFAULT 'rules',
            `status` ENUM('active','passed','rejected','closed') NOT NULL DEFAULT 'active',
            `votes_yes` INT NOT NULL DEFAULT 0,
            `votes_no` INT NOT NULL DEFAULT 0,
            `votes_neutral` INT NOT NULL DEFAULT 0,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_group_status` (`group_code`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_poll_votes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `poll_id` INT NOT NULL,
            `voter_hash` VARCHAR(64) NOT NULL,
            `vote` ENUM('yes','no','neutral') NOT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_poll_voter` (`poll_id`, `voter_hash`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    } catch (Throwable $e) {}
}

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?? $_POST;
    $action = $body['action'] ?? 'vote';

    if ($action === 'create_poll') {
        $title = trim((string)($body['title'] ?? ''));
        $desc = trim((string)($body['description'] ?? ''));
        $category = trim((string)($body['category'] ?? 'rules'));
        $gCode = trim((string)($body['group_code'] ?? $groupCode));

        if (empty($title)) {
            json_response(['ok' => false, 'error' => 'Masala sarlavhasi kiritilishi shart'], 400);
        }

        if ($pdo) {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_polls` (`group_code`, `title`, `description`, `category`, `status`, `created_at`) VALUES (?, ?, ?, ?, 'active', NOW())");
            $stmt->execute([$gCode, $title, $desc, $category]);
            $pollId = (int)$pdo->lastInsertId();
        } else {
            $pollId = time();
        }

        json_response([
            'ok' => true,
            'message' => 'Anonim masala muvaffaqiyatli o‘rtaga tashlandi! Xonadoshlar ovoz berishlari mumkin.',
            'poll_id' => $pollId
        ]);
    }

    if ($action === 'vote') {
        $pollId = (int)($body['poll_id'] ?? 0);
        $vote = trim((string)($body['vote'] ?? 'yes')); // yes, no, neutral
        $voterHash = trim((string)($body['voter_hash'] ?? ''));

        if (!in_array($vote, ['yes', 'no', 'neutral'], true)) {
            json_response(['ok' => false, 'error' => 'Noto‘g‘ri ovoz turi'], 400);
        }

        if (empty($voterHash)) {
            $voterHash = md5($_SERVER['REMOTE_ADDR'] . '-' . ($_SERVER['HTTP_USER_AGENT'] ?? 'agent'));
        }

        if ($pdo) {
            // Check if already voted
            $chk = $pdo->prepare("SELECT `vote` FROM `xonadosh_poll_votes` WHERE `poll_id` = ? AND `voter_hash` = ?");
            $chk->execute([$pollId, $voterHash]);
            $oldVote = $chk->fetchColumn();

            if ($oldVote) {
                // Update vote
                $upd = $pdo->prepare("UPDATE `xonadosh_poll_votes` SET `vote` = ?, `created_at` = NOW() WHERE `poll_id` = ? AND `voter_hash` = ?");
                $upd->execute([$vote, $pollId, $voterHash]);
            } else {
                $ins = $pdo->prepare("INSERT INTO `xonadosh_poll_votes` (`poll_id`, `voter_hash`, `vote`, `created_at`) VALUES (?, ?, ?, NOW())");
                $ins->execute([$pollId, $voterHash, $vote]);
            }

            // Recalculate totals
            $totalsStmt = $pdo->prepare("
                SELECT 
                    SUM(CASE WHEN `vote`='yes' THEN 1 ELSE 0 END) as yes_count,
                    SUM(CASE WHEN `vote`='no' THEN 1 ELSE 0 END) as no_count,
                    SUM(CASE WHEN `vote`='neutral' THEN 1 ELSE 0 END) as neutral_count
                FROM `xonadosh_poll_votes` WHERE `poll_id` = ?
            ");
            $totalsStmt->execute([$pollId]);
            $t = $totalsStmt->fetch(PDO::FETCH_ASSOC);

            $yesCount = (int)($t['yes_count'] ?? 0);
            $noCount = (int)($t['no_count'] ?? 0);
            $neutralCount = (int)($t['neutral_count'] ?? 0);
            $totalVotes = $yesCount + $noCount + $neutralCount;

            // Auto-determine status if enough votes
            $newStatus = 'active';
            if ($totalVotes >= 3) {
                if ($yesCount > $noCount) {
                    $newStatus = 'passed';
                } elseif ($noCount > $yesCount) {
                    $newStatus = 'rejected';
                }
            }

            $updPoll = $pdo->prepare("UPDATE `xonadosh_polls` SET `votes_yes` = ?, `votes_no` = ?, `votes_neutral` = ?, `status` = ? WHERE `id` = ?");
            $updPoll->execute([$yesCount, $noCount, $neutralCount, $newStatus, $pollId]);
        }

        json_response([
            'ok' => true,
            'message' => 'Ovozingiz anonim tarzda qabul qilindi!',
            'poll_id' => $pollId,
            'user_vote' => $vote
        ]);
    }

    if ($action === 'close_poll') {
        $pollId = (int)($body['poll_id'] ?? 0);
        $status = trim((string)($body['status'] ?? 'closed'));

        if ($pdo) {
            $stmt = $pdo->prepare("UPDATE `xonadosh_polls` SET `status` = ? WHERE `id` = ?");
            $stmt->execute([$status, $pollId]);
        }

        json_response(['ok' => true, 'message' => 'Masala yakunlandi']);
    }
}

// GET list of polls
$polls = [];
if ($pdo) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM `xonadosh_polls` WHERE `group_code` = ? ORDER BY FIELD(status, 'active', 'passed', 'rejected', 'closed'), `id` DESC LIMIT 50");
        $stmt->execute([$groupCode]);
        $polls = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Throwable $e) {}
}

// Fallback seed data if empty
if (empty($polls)) {
    $polls = [
        [
            'id' => 1,
            'group_code' => $groupCode,
            'title' => 'Kechasi 23:00 dan keyin mehmon chaqirmaslik qoidasi',
            'description' => 'Dars vaqtida va imtihonlar mavsumida har kim to‘liq uxlab dam olishi uchun 23:00 dan so‘ng begona mehmonlarni chaqirmaslikni taklif qilaman.',
            'category' => 'rules',
            'status' => 'passed',
            'votes_yes' => 3,
            'votes_no' => 1,
            'votes_neutral' => 0,
            'created_at' => date('Y-m-d H:i:s', strtotime('-2 days'))
        ],
        [
            'id' => 2,
            'group_code' => $groupCode,
            'title' => 'Har yakshanba umumiy "Generalka" tozalik kuni qilaylik',
            'description' => 'Yakshanba soat 10:00 da 4 kishi birgalikda 1 soat hamma xonalarni chuqur tozalasa, hafta davomida xona doim tartibli turadi.',
            'category' => 'cleaning',
            'status' => 'active',
            'votes_yes' => 3,
            'votes_no' => 0,
            'votes_neutral' => 1,
            'created_at' => date('Y-m-d H:i:s', strtotime('-1 day'))
        ],
        [
            'id' => 3,
            'group_code' => $groupCode,
            'title' => 'Wi-Fi tezligini oshirish va yangi tarifga o‘tish',
            'description' => 'Hozirgi internet 30 Mbps, kechqurun hammamiz ulanganda sekinlashyapti. 100 Mbps tarifga o‘tsak kishi boshiga oyiga atigi 12 000 so‘m qo‘shiladi.',
            'category' => 'general',
            'status' => 'active',
            'votes_yes' => 2,
            'votes_no' => 1,
            'votes_neutral' => 1,
            'created_at' => date('Y-m-d H:i:s', strtotime('-3 hours'))
        ]
    ];
}

$formattedPolls = [];
foreach ($polls as $p) {
    $yes = (int)($p['votes_yes'] ?? 0);
    $no = (int)($p['votes_no'] ?? 0);
    $neu = (int)($p['votes_neutral'] ?? 0);
    $total = $yes + $no + $neu;

    $yesPct = $total > 0 ? (int)round(($yes / $total) * 100) : 0;
    $noPct  = $total > 0 ? (int)round(($no / $total) * 100) : 0;
    $neuPct = $total > 0 ? (int)round(($neu / $total) * 100) : 0;

    $formattedPolls[] = [
        'id' => (int)$p['id'],
        'title' => $p['title'],
        'description' => $p['description'] ?? '',
        'category' => $p['category'] ?? 'rules',
        'status' => $p['status'] ?? 'active',
        'votes_yes' => $yes,
        'votes_no' => $no,
        'votes_neutral' => $neu,
        'total_votes' => $total,
        'yes_percent' => $yesPct,
        'no_percent' => $noPct,
        'neutral_percent' => $neuPct,
        'created_at' => $p['created_at'] ?? date('Y-m-d H:i:s')
    ];
}

json_response([
    'ok' => true,
    'group_code' => $groupCode,
    'active_count' => count(array_filter($formattedPolls, fn($x) => $x['status'] === 'active')),
    'polls' => $formattedPolls
]);
