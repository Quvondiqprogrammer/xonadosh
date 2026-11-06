<?php
declare(strict_types=1);

/**
 * API: Raqamli Xonadoshlik Kodeksi (House Rules)
 * 5-point household rules agreement between roommates.
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$groupCode = trim((string)($_GET['group_code'] ?? 'home_default'));
if ($groupCode === '') {
    $groupCode = 'home_default';
}

if ($method === 'GET') {
    try {
        $stmt = $pdo->prepare("SELECT * FROM `xonadosh_house_rules` WHERE `group_code` = ?");
        $stmt->execute([$groupCode]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            // Default standards
            json_response([
                'ok' => true,
                'rules' => [
                    'group_code' => $groupCode,
                    'quiet_hours_start' => '23:00',
                    'rent_due_day' => 5,
                    'guest_policy' => 'Oldindan guruhda ogohlantirish sharti bilan',
                    'common_groceries' => 'Non, choy, yog‘, shakar va idish yuvish vositalari umumiy olinadi',
                    'move_out_notice_days' => 15,
                    'confirmed_by' => [],
                    'is_agreed' => false
                ]
            ]);
        }

        $confirmedBy = [];
        if (!empty($row['confirmed_by_json'])) {
            $dec = json_decode($row['confirmed_by_json'], true);
            if (is_array($dec)) $confirmedBy = $dec;
        }

        json_response([
            'ok' => true,
            'rules' => [
                'id' => (int)$row['id'],
                'group_code' => $row['group_code'],
                'quiet_hours_start' => $row['quiet_hours_start'],
                'rent_due_day' => (int)$row['rent_due_day'],
                'guest_policy' => $row['guest_policy'],
                'common_groceries' => $row['common_groceries'] ?? '',
                'move_out_notice_days' => (int)$row['move_out_notice_days'],
                'confirmed_by' => $confirmedBy,
                'is_agreed' => count($confirmedBy) >= 2,
                'updated_at' => $row['updated_at']
            ]
        ]);
    } catch (Throwable $e) {
        json_response(['ok' => false, 'error' => $e->getMessage()], 500);
    }
}

// POST: Save or Confirm Rules
$sess = auth_require_token($pdo);
$username = (string)$sess['username'];

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$groupCode = trim((string)($body['group_code'] ?? $groupCode));
$quietHours = trim((string)($body['quiet_hours_start'] ?? '23:00'));
$rentDueDay = max(1, min(31, (int)($body['rent_due_day'] ?? 5)));
$guestPolicy = trim((string)($body['guest_policy'] ?? 'Oldindan guruhda ogohlantirish sharti bilan'));
$commonGroceries = trim((string)($body['common_groceries'] ?? 'Non, choy, yog‘, shakar va idish yuvish vositalari'));
$moveOutNotice = max(1, min(90, (int)($body['move_out_notice_days'] ?? 15)));
$doConfirm = !empty($body['confirm']);

try {
    $stmt = $pdo->prepare("SELECT * FROM `xonadosh_house_rules` WHERE `group_code` = ?");
    $stmt->execute([$groupCode]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);

    $confirmedBy = [];
    if ($existing && !empty($existing['confirmed_by_json'])) {
        $dec = json_decode($existing['confirmed_by_json'], true);
        if (is_array($dec)) $confirmedBy = $dec;
    }

    if ($doConfirm && !in_array($username, $confirmedBy, true)) {
        $confirmedBy[] = $username;
    }

    if ($existing) {
        $upd = $pdo->prepare("UPDATE `xonadosh_house_rules` SET 
            `quiet_hours_start` = ?,
            `rent_due_day` = ?,
            `guest_policy` = ?,
            `common_groceries` = ?,
            `move_out_notice_days` = ?,
            `confirmed_by_json` = ?
            WHERE `group_code` = ?");
        $upd->execute([
            $quietHours,
            $rentDueDay,
            $guestPolicy,
            $commonGroceries,
            $moveOutNotice,
            json_encode($confirmedBy, JSON_UNESCAPED_UNICODE),
            $groupCode
        ]);
    } else {
        $ins = $pdo->prepare("INSERT INTO `xonadosh_house_rules` (
            `group_code`, `quiet_hours_start`, `rent_due_day`, `guest_policy`, 
            `common_groceries`, `move_out_notice_days`, `confirmed_by_json`
        ) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $ins->execute([
            $groupCode,
            $quietHours,
            $rentDueDay,
            $guestPolicy,
            $commonGroceries,
            $moveOutNotice,
            json_encode($confirmedBy, JSON_UNESCAPED_UNICODE)
        ]);
    }

    json_response([
        'ok' => true,
        'message' => 'Raqamli Xonadoshlik Kodeksi saqlandi!',
        'confirmed_by' => $confirmedBy,
        'confirmed_count' => count($confirmedBy)
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
