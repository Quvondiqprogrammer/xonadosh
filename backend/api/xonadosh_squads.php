<?php
declare(strict_types=1);

/**
 * API: Xonadosh Jamoasi (Coliving Squads)
 * 2-4 students group up to pool budget and rent an apartment together.
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

if ($method === 'GET') {
    $uniId = isset($_GET['university_id']) && is_numeric($_GET['university_id']) ? (int)$_GET['university_id'] : null;
    $gender = isset($_GET['gender']) && is_string($_GET['gender']) ? trim($_GET['gender']) : null;
    $district = isset($_GET['district']) && is_string($_GET['district']) ? trim($_GET['district']) : null;
    $status = isset($_GET['status']) && is_string($_GET['status']) ? trim($_GET['status']) : 'recruiting';

    $sql = "SELECT s.*, u.short_name as uni_short_name 
            FROM `xonadosh_squads` s
            LEFT JOIN `xonadosh_universities` u ON s.target_university_id = u.id
            WHERE 1=1";
    $params = [];

    if ($status !== 'all') {
        $sql .= " AND s.status = ?";
        $params[] = $status;
    }

    if ($uniId !== null && $uniId > 0) {
        $sql .= " AND s.target_university_id = ?";
        $params[] = $uniId;
    }

    if ($gender !== null && $gender !== 'any') {
        $sql .= " AND (s.target_gender = ? OR s.target_gender = 'any')";
        $params[] = $gender;
    }

    if ($district !== null && $district !== '' && $district !== 'Barchasi') {
        $sql .= " AND s.target_district = ?";
        $params[] = $district;
    }

    $sql .= " ORDER BY s.id DESC LIMIT 50";

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $squads = [];
        foreach ($rows as $r) {
            $members = [];
            if (!empty($r['members_json'])) {
                $dec = json_decode($r['members_json'], true);
                if (is_array($dec)) $members = $dec;
            }

            $currentCount = count($members);
            $targetCount = (int)$r['looking_for_count'];
            $spotsLeft = max(0, $targetCount - $currentCount);

            $squads[] = [
                'id' => (int)$r['id'],
                'name' => $r['name'],
                'target_university_id' => $r['target_university_id'] !== null ? (int)$r['target_university_id'] : null,
                'target_university_name' => $r['target_university_name'] ?? ($r['uni_short_name'] ?? 'OTM'),
                'target_district' => $r['target_district'] ?? 'Toshkent',
                'total_budget_uzs' => (float)$r['total_budget_uzs'],
                'target_gender' => $r['target_gender'],
                'creator_username' => $r['creator_username'],
                'creator_phone' => $r['creator_phone'],
                'members' => $members,
                'members_count' => $currentCount,
                'looking_for_count' => $targetCount,
                'spots_left' => $spotsLeft,
                'description' => $r['description'] ?? '',
                'status' => $r['status'],
                'created_at' => $r['created_at']
            ];
        }

        json_response([
            'ok' => true,
            'count' => count($squads),
            'squads' => $squads
        ]);
    } catch (Throwable $e) {
        json_response(['ok' => false, 'error' => $e->getMessage()], 500);
    }
}

// POST: Create squad OR Join squad
$sess = auth_require_token($pdo);
$username = (string)$sess['username'];
$userPhone = (string)($sess['phone_number'] ?? '');
$displayName = (string)($sess['display_name'] ?? ($sess['username'] ?? 'Foydalanuvchi'));

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$action = (string)($body['action'] ?? 'create');

if ($action === 'join') {
    $squadId = isset($body['squad_id']) && is_numeric($body['squad_id']) ? (int)$body['squad_id'] : null;
    $memberBudget = (float)($body['member_budget_uzs'] ?? 1000000);

    if ($squadId === null) {
        json_response(['ok' => false, 'error' => 'squad_id kiritilishi shart'], 400);
    }

    try {
        $stmt = $pdo->prepare("SELECT * FROM `xonadosh_squads` WHERE id = ? FOR UPDATE");
        $stmt->execute([$squadId]);
        $squad = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$squad) {
            json_response(['ok' => false, 'error' => 'Jamoa topilmadi'], 404);
        }

        $members = [];
        if (!empty($squad['members_json'])) {
            $dec = json_decode($squad['members_json'], true);
            if (is_array($dec)) $members = $dec;
        }

        // Check if user is already a member
        foreach ($members as $m) {
            if (($m['username'] ?? '') === $username) {
                json_response(['ok' => false, 'error' => 'Siz ushbu jamoaga allaqachon qo‘shilgansiz'], 400);
            }
        }

        if (count($members) >= (int)$squad['looking_for_count']) {
            json_response(['ok' => false, 'error' => 'Ushbu jamoada bo‘sh joy qolmagan'], 400);
        }

        $members[] = [
            'username' => $username,
            'name' => $displayName,
            'phone' => $userPhone,
            'budget_uzs' => $memberBudget,
            'joined_at' => date('Y-m-d H:i:s')
        ];

        $newTotal = 0;
        foreach ($members as $m) {
            $newTotal += (float)($m['budget_uzs'] ?? 0);
        }

        $newStatus = count($members) >= (int)$squad['looking_for_count'] ? 'ready' : 'recruiting';

        $upd = $pdo->prepare("UPDATE `xonadosh_squads` SET 
            `members_json` = ?,
            `total_budget_uzs` = ?,
            `status` = ?
            WHERE id = ?");
        $upd->execute([
            json_encode($members, JSON_UNESCAPED_UNICODE),
            $newTotal,
            $newStatus,
            $squadId
        ]);

        json_response([
            'ok' => true,
            'message' => 'Tabriklaymiz, Xonadosh Jamoasiga muvaffaqiyatli qo‘shildingiz!',
            'squad_id' => $squadId,
            'members_count' => count($members),
            'total_budget_uzs' => $newTotal,
            'status' => $newStatus
        ]);
    } catch (Throwable $e) {
        json_response(['ok' => false, 'error' => $e->getMessage()], 500);
    }
}

// Action: Create Squad
$name = trim((string)($body['name'] ?? ''));
if ($name === '') {
    $name = 'Jamoa: ' . $displayName;
}

$uniId = isset($body['target_university_id']) && is_numeric($body['target_university_id']) ? (int)$body['target_university_id'] : null;
$uniName = trim((string)($body['target_university_name'] ?? ''));
$targetDistrict = trim((string)($body['target_district'] ?? ''));
$targetGender = (string)($body['target_gender'] ?? 'any');
$myBudget = (float)($body['my_budget_uzs'] ?? 1000000);
$lookingForCount = max(2, min(6, (int)($body['looking_for_count'] ?? 3)));
$description = trim((string)($body['description'] ?? ''));

if ($userPhone === '') {
    $userPhone = trim((string)($body['phone'] ?? ''));
}

$initialMembers = [
    [
        'username' => $username,
        'name' => $displayName,
        'phone' => $userPhone,
        'budget_uzs' => $myBudget,
        'is_creator' => true,
        'joined_at' => date('Y-m-d H:i:s')
    ]
];

try {
    $stmt = $pdo->prepare("INSERT INTO `xonadosh_squads` (
        `name`, `target_university_id`, `target_university_name`, `target_district`,
        `total_budget_uzs`, `target_gender`, `creator_username`, `creator_phone`,
        `members_json`, `looking_for_count`, `description`, `status`
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'recruiting')");

    $stmt->execute([
        $name, $uniId, $uniName, $targetDistrict,
        $myBudget, $targetGender, $username, $userPhone,
        json_encode($initialMembers, JSON_UNESCAPED_UNICODE),
        $lookingForCount, $description
    ]);

    $newId = (int)$pdo->lastInsertId();

    json_response([
        'ok' => true,
        'message' => 'Xonadosh Jamoasi tuzildi! Sheriklar qo‘shilgach xabardor qilamiz.',
        'squad_id' => $newId
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
