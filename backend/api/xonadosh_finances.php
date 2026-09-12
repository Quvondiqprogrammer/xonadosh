<?php
declare(strict_types=1);
/**
 * API: Roommate Finances, Rent & Utilities, Debt & Split-Bill Manager
 * - Ijara to'lovlari nazorati
 * - Kommunal to'lovlar (Svet, Gaz, Suv, Wi-Fi) taqsimoti
 * - Qarz oldi-berdi & xarajatlarni o'zaro teng bo'lish (Splitwise style)
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

// Ensure table exists
if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `xonadosh_finances` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `group_code` VARCHAR(50) NOT NULL DEFAULT 'home_default',
            `type` ENUM('rent','utility','expense_split','debt') NOT NULL DEFAULT 'expense_split',
            `title` VARCHAR(200) NOT NULL,
            `amount_uzs` BIGINT NOT NULL,
            `paid_by` VARCHAR(100) NOT NULL,
            `category` VARCHAR(50) NOT NULL DEFAULT 'general',
            `due_date` VARCHAR(50) NULL,
            `status` ENUM('pending','partially_paid','settled') NOT NULL DEFAULT 'pending',
            `split_json` TEXT NOT NULL,
            `notes` VARCHAR(255) NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_group_type` (`group_code`, `type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    } catch (Throwable $e) {}
}

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?? $_POST;
    $action = $body['action'] ?? 'add_expense';

    if ($action === 'add_expense' || $action === 'add_bill') {
        $type = (string)($body['type'] ?? 'expense_split');
        $title = trim((string)($body['title'] ?? ''));
        $amount = max(1000, (int)($body['amount_uzs'] ?? 0));
        $paidBy = trim((string)($body['paid_by'] ?? 'Jasur'));
        $category = trim((string)($body['category'] ?? 'general'));
        $dueDate = trim((string)($body['due_date'] ?? ''));
        $notes = trim((string)($body['notes'] ?? ''));
        $splits = $body['splits'] ?? [];
        $gCode = trim((string)($body['group_code'] ?? $groupCode));

        if (empty($title)) {
            json_response(['ok' => false, 'error' => 'To‘lov nomi kiritilishi shart'], 400);
        }

        // If splits not provided, automatically split among 4 default roommates
        if (empty($splits)) {
            $defaultMembers = ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];
            $perPerson = (int)round($amount / count($defaultMembers));
            $splits = [];
            foreach ($defaultMembers as $m) {
                $splits[] = [
                    'name' => $m,
                    'amount_uzs' => $perPerson,
                    'is_paid' => ($m === $paidBy && $type === 'expense_split')
                ];
            }
        }

        $allPaid = true;
        foreach ($splits as $s) {
            if (empty($s['is_paid'])) { $allPaid = false; break; }
        }
        $status = $allPaid ? 'settled' : 'pending';

        if ($pdo) {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_finances` (`group_code`, `type`, `title`, `amount_uzs`, `paid_by`, `category`, `due_date`, `status`, `split_json`, `notes`, `created_at`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())");
            $stmt->execute([$gCode, $type, $title, $amount, $paidBy, $category, $dueDate, $status, json_encode($splits, JSON_UNESCAPED_UNICODE), $notes]);
            $fid = (int)$pdo->lastInsertId();
        } else {
            $fid = time();
        }

        json_response([
            'ok' => true,
            'message' => 'To‘lov/xarajat muvaffaqiyatli qo‘shildi va xonadoshlar o‘rtasida taqsimlandi!',
            'finance_id' => $fid
        ]);
    }

    if ($action === 'toggle_member_paid') {
        $financeId = (int)($body['finance_id'] ?? 0);
        $memberName = trim((string)($body['member_name'] ?? ''));
        $isPaid = !empty($body['is_paid']);

        if ($pdo && $financeId > 0) {
            $st = $pdo->prepare("SELECT `split_json` FROM `xonadosh_finances` WHERE `id` = ?");
            $st->execute([$financeId]);
            $json = $st->fetchColumn();
            if ($json) {
                $splits = json_decode($json, true) ?? [];
                $allPaid = true;
                foreach ($splits as &$s) {
                    if (strcasecmp($s['name'], $memberName) === 0) {
                        $s['is_paid'] = $isPaid;
                    }
                    if (empty($s['is_paid'])) {
                        $allPaid = false;
                    }
                }
                unset($s);
                $newStatus = $allPaid ? 'settled' : 'partially_paid';

                $upd = $pdo->prepare("UPDATE `xonadosh_finances` SET `split_json` = ?, `status` = ? WHERE `id` = ?");
                $upd->execute([json_encode($splits, JSON_UNESCAPED_UNICODE), $newStatus, $financeId]);
            }
        }

        json_response([
            'ok' => true,
            'message' => "To‘lov holati yangilandi ({$memberName}: " . ($isPaid ? 'To‘ladi' : 'To‘lanmagan') . ')'
        ]);
    }

    if ($action === 'delete_finance') {
        $financeId = (int)($body['finance_id'] ?? 0);
        if ($pdo) {
            $pdo->prepare("DELETE FROM `xonadosh_finances` WHERE `id` = ?")->execute([$financeId]);
        }
        json_response(['ok' => true, 'message' => 'To‘lov o‘chirildi']);
    }
}

// GET all finance items
$items = [];
if ($pdo) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM `xonadosh_finances` WHERE `group_code` = ? ORDER BY FIELD(status, 'pending', 'partially_paid', 'settled'), `id` DESC LIMIT 100");
        $stmt->execute([$groupCode]);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Throwable $e) {}
}

// Fallback seed data if DB is empty
if (empty($items)) {
    $items = [
        [
            'id' => 1,
            'group_code' => $groupCode,
            'type' => 'rent',
            'title' => 'Oylik ijara to‘lovi (Mart oyi)',
            'amount_uzs' => 4000000,
            'paid_by' => 'Uy egasiga',
            'category' => 'rent',
            'due_date' => 'Har oyning 5-sanasi',
            'status' => 'partially_paid',
            'split_json' => json_encode([
                ['name' => 'Jasur',   'amount_uzs' => 1000000, 'is_paid' => true],
                ['name' => 'Azizbek', 'amount_uzs' => 1000000, 'is_paid' => true],
                ['name' => 'Bekzod',  'amount_uzs' => 1000000, 'is_paid' => false],
                ['name' => 'Sardor',  'amount_uzs' => 1000000, 'is_paid' => true],
            ], JSON_UNESCAPED_UNICODE),
            'notes' => 'Bekzod stipendiyasi tushishi bilan 5-martgacha to‘laydi',
            'created_at' => date('Y-m-d H:i:s', strtotime('-5 days'))
        ],
        [
            'id' => 2,
            'group_code' => $groupCode,
            'type' => 'utility',
            'title' => 'Svet & Elektr energiyasi (Hisoblagich)',
            'amount_uzs' => 180000,
            'paid_by' => 'Jasur',
            'category' => 'electricity',
            'due_date' => '10-martgacha',
            'status' => 'partially_paid',
            'split_json' => json_encode([
                ['name' => 'Jasur',   'amount_uzs' => 45000, 'is_paid' => true],
                ['name' => 'Azizbek', 'amount_uzs' => 45000, 'is_paid' => true],
                ['name' => 'Bekzod',  'amount_uzs' => 45000, 'is_paid' => false],
                ['name' => 'Sardor',  'amount_uzs' => 45000, 'is_paid' => false],
            ], JSON_UNESCAPED_UNICODE),
            'notes' => 'Jasur o‘z hisobidan Click orqali to‘lab qo‘ydi, qolganlar unga beradi',
            'created_at' => date('Y-m-d H:i:s', strtotime('-3 days'))
        ],
        [
            'id' => 3,
            'group_code' => $groupCode,
            'type' => 'utility',
            'title' => 'Optik Wi-Fi Internet (100 Mbps)',
            'amount_uzs' => 140000,
            'paid_by' => 'Sardor',
            'category' => 'internet',
            'due_date' => '1-martgacha',
            'status' => 'settled',
            'split_json' => json_encode([
                ['name' => 'Jasur',   'amount_uzs' => 35000, 'is_paid' => true],
                ['name' => 'Azizbek', 'amount_uzs' => 35000, 'is_paid' => true],
                ['name' => 'Bekzod',  'amount_uzs' => 35000, 'is_paid' => true],
                ['name' => 'Sardor',  'amount_uzs' => 35000, 'is_paid' => true],
            ], JSON_UNESCAPED_UNICODE),
            'notes' => 'Hamma to‘liq hisob-kitob qildi',
            'created_at' => date('Y-m-d H:i:s', strtotime('-1 day'))
        ],
        [
            'id' => 4,
            'group_code' => $groupCode,
            'type' => 'expense_split',
            'title' => 'Katta bozorlik (Go‘sht, yog‘, guruch, sabzavot)',
            'amount_uzs' => 320000,
            'paid_by' => 'Azizbek',
            'category' => 'grocery_shared',
            'due_date' => 'Tezkor',
            'status' => 'partially_paid',
            'split_json' => json_encode([
                ['name' => 'Jasur',   'amount_uzs' => 80000, 'is_paid' => true],
                ['name' => 'Azizbek', 'amount_uzs' => 80000, 'is_paid' => true],
                ['name' => 'Bekzod',  'amount_uzs' => 80000, 'is_paid' => false],
                ['name' => 'Sardor',  'amount_uzs' => 80000, 'is_paid' => true],
            ], JSON_UNESCAPED_UNICODE),
            'notes' => 'Qo‘yliq bozoridan olingan oziq-ovqatlar',
            'created_at' => date('Y-m-d H:i:s', strtotime('-2 days'))
        ],
    ];
}

$formatted = [];
$totalMonthlySpend = 0;
$totalPendingUzs = 0;
$netBalances = [];

foreach ($items as $row) {
    $splits = json_decode($row['split_json'] ?? '[]', true) ?? [];
    $amt = (int)$row['amount_uzs'];
    $totalMonthlySpend += $amt;

    $paidSum = 0;
    $pendingSum = 0;
    foreach ($splits as $s) {
        $sAmt = (int)($s['amount_uzs'] ?? 0);
        $sName = (string)($s['name'] ?? '');
        $isPaid = !empty($s['is_paid']);

        if ($isPaid) {
            $paidSum += $sAmt;
        } else {
            $pendingSum += $sAmt;
            $totalPendingUzs += $sAmt;

            // Track who owes to whom
            $debtor = $sName;
            $creditor = $row['paid_by'];
            if ($creditor !== 'Uy egasiga' && $debtor !== $creditor) {
                $pairKey = "{$debtor} ➔ {$creditor}";
                if (!isset($netBalances[$pairKey])) {
                    $netBalances[$pairKey] = [
                        'debtor' => $debtor,
                        'creditor' => $creditor,
                        'amount_uzs' => 0,
                        'reason' => $row['title']
                    ];
                }
                $netBalances[$pairKey]['amount_uzs'] += $sAmt;
            }
        }
    }

    $formatted[] = [
        'id' => (int)$row['id'],
        'type' => $row['type'],
        'title' => $row['title'],
        'amount_uzs' => $amt,
        'paid_by' => $row['paid_by'],
        'category' => $row['category'],
        'due_date' => $row['due_date'] ?? '',
        'status' => $row['status'],
        'paid_amount_uzs' => $paidSum,
        'pending_amount_uzs' => $pendingSum,
        'splits' => $splits,
        'notes' => $row['notes'] ?? '',
        'created_at' => $row['created_at'] ?? date('Y-m-d H:i:s')
    ];
}

// Group into rent, utilities, and expenses
$rents = array_values(array_filter($formatted, fn($x) => $x['type'] === 'rent'));
$utilities = array_values(array_filter($formatted, fn($x) => $x['type'] === 'utility'));
$expenses = array_values(array_filter($formatted, fn($x) => in_array($x['type'], ['expense_split', 'debt'], true)));

json_response([
    'ok' => true,
    'group_code' => $groupCode,
    'summary' => [
        'total_spend_uzs' => $totalMonthlySpend,
        'total_pending_uzs' => $totalPendingUzs,
        'rent_total_uzs' => array_sum(array_column($rents, 'amount_uzs')),
        'utility_total_uzs' => array_sum(array_column($utilities, 'amount_uzs')),
        'expense_total_uzs' => array_sum(array_column($expenses, 'amount_uzs')),
    ],
    'debt_balances' => array_values($netBalances),
    'rent_items' => $rents,
    'utility_items' => $utilities,
    'expense_items' => $expenses,
    'all_items' => $formatted
]);
