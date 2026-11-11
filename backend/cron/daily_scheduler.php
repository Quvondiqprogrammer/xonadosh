<?php
declare(strict_types=1);

/**
 * XONADOSH — cPanel Daily Automation & Cron Scheduler
 * CLI Usage: php /home/user/public_html/cron/daily_scheduler.php
 * HTTP Usage: curl -s "https://xonadoshim.uz/cron/daily_scheduler.php?key=Asad03@18"
 */

$isCli = (php_sapi_name() === 'cli');

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

// Gate security check for HTTP trigger
if (!$isCli) {
    $key = $_GET['key'] ?? '';
    $expectedKey = $cfg['admin_gate_key'] ?? 'Asad03@18';
    if ($key !== $expectedKey) {
        http_response_code(403);
        echo json_encode(['ok' => false, 'error' => 'Forbidden — Invalid cron gate key']);
        exit;
    }
}

header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    echo json_encode(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$results = [
    'ok' => true,
    'timestamp' => date('Y-m-d H:i:s'),
    'tasks' => []
];

// 1. Expire stale listings (72h dynamic TTL)
try {
    $expStmt = $pdo->prepare("UPDATE `xonadosh_listings` 
        SET `status` = 'archived' 
        WHERE `status` = 'active' AND `expires_at` IS NOT NULL AND `expires_at` < NOW()");
    $expStmt->execute();
    $expiredCount = $expStmt->rowCount();
    $results['tasks']['expired_listings'] = $expiredCount;
} catch (Throwable $e) {
    $results['tasks']['expired_listings_error'] = $e->getMessage();
}

// 2. Crowd-moderation: Quarantine listings with 3+ broker reports
try {
    $qStmt = $pdo->prepare("UPDATE `xonadosh_listings` 
        SET `status` = 'quarantine' 
        WHERE `status` = 'active' AND `crowd_broker_reports` >= 3");
    $qStmt->execute();
    $quarantinedCount = $qStmt->rowCount();
    $results['tasks']['quarantined_broker_listings'] = $quarantinedCount;
} catch (Throwable $e) {
    $results['tasks']['quarantine_error'] = $e->getMessage();
}

// 3. Purge expired session tokens
try {
    $sessStmt = $pdo->prepare("DELETE FROM `xd_sessions` WHERE `expires_at` < NOW()");
    $sessStmt->execute();
    $purgedSessions = $sessStmt->rowCount();
    $results['tasks']['purged_expired_sessions'] = $purgedSessions;
} catch (Throwable $e) {
    $results['tasks']['purged_sessions_error'] = $e->getMessage();
}

// 4. Clean old chore swaps (> 14 days)
try {
    $swStmt = $pdo->prepare("DELETE FROM `xonadosh_chore_swaps` WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 14 DAY)");
    $swStmt->execute();
    $results['tasks']['purged_old_swaps'] = $swStmt->rowCount();
} catch (Throwable $e) {}

// 5. Clean old opt-outs (> 7 days past)
try {
    $ooStmt = $pdo->prepare("DELETE FROM `xonadosh_meal_opt_outs` WHERE `opt_out_date` < DATE_SUB(CURDATE(), INTERVAL 7 DAY)");
    $ooStmt->execute();
    $results['tasks']['purged_old_opt_outs'] = $ooStmt->rowCount();
} catch (Throwable $e) {}

echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
