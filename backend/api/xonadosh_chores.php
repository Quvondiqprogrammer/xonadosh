<?php
declare(strict_types=1);

/**
 * API: Roommate Chore & Duty Roster (Navbatchilik Jadvali)
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

$groupCode = isset($_GET['group_code']) ? trim($_GET['group_code']) : 'home_default';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?? $_POST;
    $action = $body['action'] ?? 'add';

    if ($action === 'toggle_done') {
        $choreId = (int)($body['chore_id'] ?? 0);
        $isCompleted = !empty($body['is_completed']) ? 1 : 0;

        $stmt = $pdo->prepare("UPDATE `xonadosh_chores` SET `is_completed` = ? WHERE `id` = ?");
        $stmt->execute([$isCompleted, $choreId]);

        json_response([
            'ok' => true,
            'message' => $isCompleted ? 'Navbatchilik bajarildi deb belgilandi!' : 'Navbatchilik holati yangilandi',
            'chore_id' => $choreId,
            'is_completed' => (bool)$isCompleted
        ]);
    }

    if ($action === 'assign') {
        $choreId = (int)($body['chore_id'] ?? 0);
        $assignedName = trim((string)($body['assigned_name'] ?? ''));

        $stmt = $pdo->prepare("UPDATE `xonadosh_chores` SET `assigned_name` = ? WHERE `id` = ?");
        $stmt->execute([$assignedName, $choreId]);

        json_response([
            'ok' => true,
            'message' => 'Navbatchi biriktirildi!',
            'chore_id' => $choreId,
            'assigned_name' => $assignedName
        ]);
    }

    if ($action === 'add') {
        $title = trim((string)($body['title'] ?? ''));
        $choreType = (string)($body['chore_type'] ?? 'cleaning');
        $dayOfWeek = (string)($body['day_of_week'] ?? 'dushanba');
        $assignedName = trim((string)($body['assigned_name'] ?? 'Xonadosh'));
        $notes = trim((string)($body['notes'] ?? ''));
        $creator = (string)($body['creator_username'] ?? 'talaba');

        if (empty($title)) {
            json_response(['ok' => false, 'error' => 'Topshiriq nomi kiritilishi shart'], 400);
        }

        $stmt = $pdo->prepare("INSERT INTO `xonadosh_chores` (`group_code`, `creator_username`, `title`, `chore_type`, `day_of_week`, `assigned_name`, `is_completed`, `notes`) VALUES (?, ?, ?, ?, ?, ?, 0, ?)");
        $stmt->execute([$groupCode, $creator, $title, $choreType, $dayOfWeek, $assignedName, $notes]);

        json_response([
            'ok' => true,
            'message' => 'Yangi navbatchilik qo‘shildi!',
            'chore_id' => (int)$pdo->lastInsertId()
        ]);
    }

    if ($action === 'delete') {
        $choreId = (int)($body['chore_id'] ?? 0);
        $stmt = $pdo->prepare("DELETE FROM `xonadosh_chores` WHERE `id` = ?");
        $stmt->execute([$choreId]);

        json_response(['ok' => true, 'message' => 'Navbatchilik o‘chirildi']);
    }
}

// GET: list chores organized by day of week
$stmt = $pdo->prepare("SELECT * FROM `xonadosh_chores` WHERE group_code = ? ORDER BY FIELD(day_of_week, 'dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'), id ASC");
$stmt->execute([$groupCode]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Map Uzbek day of week to English day for today's highlight
$daysMap = [
    1 => 'dushanba',
    2 => 'seshanba',
    3 => 'chorshanba',
    4 => 'payshanba',
    5 => 'juma',
    6 => 'shanba',
    7 => 'yakshanba'
];
$todayUz = $daysMap[(int)date('N')];

$chores = [];
$todayDuties = [];

foreach ($rows as $r) {
    $item = [
        'id' => (int)$r['id'],
        'group_code' => $r['group_code'],
        'title' => $r['title'],
        'chore_type' => $r['chore_type'],
        'day_of_week' => $r['day_of_week'],
        'assigned_name' => $r['assigned_name'],
        'is_completed' => (bool)$r['is_completed'],
        'notes' => $r['notes'] ?? '',
        'created_at' => $r['created_at']
    ];
    $chores[] = $item;

    if ($r['day_of_week'] === $todayUz) {
        $todayDuties[] = $item;
    }
}

json_response([
    'ok' => true,
    'today_day' => $todayUz,
    'today_duties' => $todayDuties,
    'all_chores' => $chores
]);
