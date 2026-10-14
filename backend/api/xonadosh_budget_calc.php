<?php
declare(strict_types=1);

/**
 * API: Roommate Budget, Rent & Utility Expense Split Calculator Micro-service
 * Supports equal and customized distribution for 2 to 8 roommates,
 * debts ledger, and Telegram report export.
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/xonadosh_lib.php';

$raw = file_get_contents('php://input');
$data = json_decode($raw, true) ?? $_REQUEST;

$groupCode = xonadosh_get_group_code($data['group_code'] ?? null);
$roommatesCount = max(2, min(8, (int)($data['roommates_count'] ?? $data['roommates'] ?? 4)));

// Standard default roommate names if not passed
$defaultNames = ['Jasur', 'Azizbek', 'Bekzod', 'Sardor', 'Diyor', 'Javohir', 'Shaxboz', 'Bobur'];
$roommates = isset($data['roommate_names']) && is_array($data['roommate_names']) && count($data['roommate_names']) >= $roommatesCount
    ? array_slice($data['roommate_names'], 0, $roommatesCount)
    : array_slice($defaultNames, 0, $roommatesCount);

// Expense categories
$rent = max(0, (int)($data['rent_uzs'] ?? 3600000));
$electricity = max(0, (int)($data['electricity_uzs'] ?? 180000));
$gas = max(0, (int)($data['gas_uzs'] ?? 90000));
$water = max(0, (int)($data['water_uzs'] ?? 60000));
$internet = max(0, (int)($data['internet_uzs'] ?? 140000));
$trash = max(0, (int)($data['trash_uzs'] ?? 20000));
$household = max(0, (int)($data['household_supplies_uzs'] ?? 80000));

$customExpenses = isset($data['custom_expenses']) && is_array($data['custom_expenses'])
    ? $data['custom_expenses']
    : [];

$customTotal = 0;
$items = [
    ['key' => 'rent', 'title' => 'Uy ijarasi', 'amount_uzs' => $rent, 'icon' => '🏡', 'category' => 'rent'],
    ['key' => 'electricity', 'title' => 'Elektr energiyasi (Svet)', 'amount_uzs' => $electricity, 'icon' => '⚡', 'category' => 'utility'],
    ['key' => 'gas', 'title' => 'Gaz to‘lovi', 'amount_uzs' => $gas, 'icon' => '🔥', 'category' => 'utility'],
    ['key' => 'water', 'title' => 'Suv to‘lovi (issiq/sovuq)', 'amount_uzs' => $water, 'icon' => '💧', 'category' => 'utility'],
    ['key' => 'internet', 'title' => 'Wi-Fi Internet (Optika)', 'amount_uzs' => $internet, 'icon' => '🌐', 'category' => 'utility'],
    ['key' => 'trash', 'title' => 'Axlat to‘lovi', 'amount_uzs' => $trash, 'icon' => '🗑', 'category' => 'utility'],
    ['key' => 'household', 'title' => 'Xo‘jalik mollari (yuvish vositalari)', 'amount_uzs' => $household, 'icon' => '🧼', 'category' => 'household'],
];

foreach ($customExpenses as $ce) {
    if (isset($ce['title'], $ce['amount_uzs']) && (int)$ce['amount_uzs'] > 0) {
        $amt = (int)$ce['amount_uzs'];
        $customTotal += $amt;
        $items[] = [
            'key' => 'custom_' . substr(md5($ce['title']), 0, 6),
            'title' => trim((string)$ce['title']),
            'amount_uzs' => $amt,
            'icon' => $ce['icon'] ?? '📦',
            'category' => 'other'
        ];
    }
}

$totalSpend = $rent + $electricity + $gas + $water + $internet + $trash + $household + $customTotal;
$perPerson = (int)round($totalSpend / $roommatesCount);

// Who paid status
$paidMap = $data['paid_status'] ?? [];
$roommateStatuses = [];
$totalPaid = 0;
$totalPending = 0;

foreach ($roommates as $idx => $rName) {
    $isPaid = !empty($paidMap[$rName]);
    // By default first 2-3 paid in demo if not provided
    if (empty($paidMap)) {
        $isPaid = ($idx !== 2); // e.g. Bekzod is pending
    }

    if ($isPaid) {
        $totalPaid += $perPerson;
    } else {
        $totalPending += $perPerson;
    }

    $roommateStatuses[] = [
        'name' => $rName,
        'per_person_uzs' => $perPerson,
        'is_paid' => $isPaid,
        'due_amount_uzs' => $isPaid ? 0 : $perPerson
    ];
}

$monthName = date('F Y');
$monthTranslations = [
    'January' => 'Yanvar', 'February' => 'Fevral', 'March' => 'Mart',
    'April' => 'Aprel', 'May' => 'May', 'June' => 'Iyun',
    'July' => 'Iyul', 'August' => 'Avgust', 'September' => 'Sentabr',
    'October' => 'Oktabr', 'November' => 'Noyabr', 'December' => 'Dekabr'
];
$currentMonth = date('F');
$monthUz = ($monthTranslations[$currentMonth] ?? $currentMonth) . ' ' . date('Y');

$telegramText = xonadosh_format_telegram_expense_report(
    $monthUz,
    $roommatesCount,
    $items,
    $totalSpend,
    $perPerson,
    $roommateStatuses
);

json_response([
    'ok' => true,
    'group_code' => $groupCode,
    'roommates_count' => $roommatesCount,
    'summary' => [
        'total_spend_uzs' => $totalSpend,
        'total_paid_uzs' => $totalPaid,
        'total_pending_uzs' => $totalPending,
        'per_person_uzs' => $perPerson,
        'rent_total_uzs' => $rent,
        'utilities_total_uzs' => $electricity + $gas + $water + $internet + $trash,
        'household_total_uzs' => $household + $customTotal
    ],
    'items' => $items,
    'roommates' => $roommateStatuses,
    'telegram_text' => $telegramText
]);
