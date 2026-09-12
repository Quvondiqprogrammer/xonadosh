<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

$users = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xd_users WHERE deleted_at IS NULL');
$listings = admin_safe_count($pdo, "SELECT COUNT(*) FROM xonadosh_listings WHERE status='active'");
$listingsAll = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xonadosh_listings');
$profiles = admin_safe_count($pdo, "SELECT COUNT(*) FROM xonadosh_profiles WHERE status='looking'");
$unis = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xonadosh_universities');
$recipes = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xonadosh_recipes');
$reports = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xd_reports');
$chores = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xonadosh_chores');
$financesPending = admin_safe_count($pdo, "SELECT COUNT(*) FROM xonadosh_finances WHERE status='pending'");
$polls = admin_safe_count($pdo, "SELECT COUNT(*) FROM xonadosh_polls WHERE status='active'");
$karma = admin_safe_count($pdo, 'SELECT COUNT(*) FROM xonadosh_karma');
$nowMs = (int) (microtime(true) * 1000);
$sessions = admin_safe_count($pdo, "SELECT COUNT(*) FROM xd_sessions WHERE expires_at > {$nowMs}");

$recent = [];
try {
    $recent = $pdo->query(
        "SELECT id, title, city, district, price, currency, status, username, type, created_at
         FROM xonadosh_listings ORDER BY id DESC LIMIT 8"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $recent = [];
}

$recentReports = [];
try {
    $recentReports = $pdo->query(
        "SELECT id, reporter_username, target_type, target_id, reason, created_at
         FROM xd_reports ORDER BY id DESC LIMIT 6"
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $recentReports = [];
}

$pageTitle = 'Dashboard';
$active = 'overview';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Dashboard</h1>
        <p class="sub">XonaDosh Super Admin — platforma holati</p>
    </div>
</div>

<div class="grid">
    <a class="card kpi-link" href="users.php">
        <div class="label">Foydalanuvchilar</div>
        <div class="kpi"><?= $users ?></div>
    </a>
    <a class="card kpi-link" href="listings.php?status=active">
        <div class="label">Faol e'lonlar</div>
        <div class="kpi"><?= $listings ?></div>
    </a>
    <a class="card kpi-link" href="listings.php">
        <div class="label">Barcha e'lonlar</div>
        <div class="kpi"><?= $listingsAll ?></div>
    </a>
    <a class="card kpi-link" href="profiles.php?status=looking">
        <div class="label">Qidiruvchi anketalar</div>
        <div class="kpi"><?= $profiles ?></div>
    </a>
    <a class="card kpi-link" href="universities.php">
        <div class="label">OTMlar</div>
        <div class="kpi"><?= $unis ?></div>
    </a>
    <a class="card kpi-link" href="recipes.php">
        <div class="label">Retseptlar</div>
        <div class="kpi"><?= $recipes ?></div>
    </a>
    <a class="card kpi-link" href="reports.php">
        <div class="label">Shikoyatlar</div>
        <div class="kpi"><?= $reports ?></div>
    </a>
    <a class="card kpi-link" href="chores.php">
        <div class="label">Navbatchilik</div>
        <div class="kpi"><?= $chores ?></div>
    </a>
    <a class="card kpi-link" href="finances.php?status=pending">
        <div class="label">Moliya (pending)</div>
        <div class="kpi"><?= $financesPending ?></div>
    </a>
    <a class="card kpi-link" href="polls.php">
        <div class="label">Faol so'rovlar</div>
        <div class="kpi"><?= $polls ?></div>
    </a>
    <a class="card kpi-link" href="karma.php">
        <div class="label">Karma yozuvlari</div>
        <div class="kpi"><?= $karma ?></div>
    </a>
    <a class="card kpi-link" href="sessions.php">
        <div class="label">Faol sessiyalar</div>
        <div class="kpi"><?= $sessions ?></div>
    </a>
</div>

<div class="card" style="margin-bottom:1.25rem">
    <h2>Tezkor havolalar</h2>
    <div class="quick-links">
        <a class="btn btn-ghost btn-sm" href="listings.php">E'lonlar</a>
        <a class="btn btn-ghost btn-sm" href="users.php">Foydalanuvchilar</a>
        <a class="btn btn-ghost btn-sm" href="reports.php">Shikoyatlar</a>
        <a class="btn btn-ghost btn-sm" href="market.php">Bozor narxlari</a>
        <a class="btn btn-ghost btn-sm" href="meals.php">Taomnoma</a>
        <a class="btn btn-ghost btn-sm" href="universities.php">OTMlar</a>
        <a class="btn btn-ghost btn-sm" href="polls.php">So'rovlar</a>
        <a class="btn btn-ghost btn-sm" href="karma.php">Karma</a>
    </div>
</div>

<div class="split">
    <div class="card">
        <h2>So'nggi e'lonlar</h2>
        <?php if ($recent === []): ?>
            <p class="empty">Hali e'lon yo'q.</p>
        <?php else: ?>
            <table>
                <thead>
                <tr>
                    <th>ID</th>
                    <th>Sarlavha</th>
                    <th>Hudud</th>
                    <th>Narx</th>
                    <th>Holat</th>
                    <th>User</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($recent as $r): ?>
                    <tr>
                        <td class="mono">#<?= (int) $r['id'] ?></td>
                        <td>
                            <strong><?= h((string) $r['title']) ?></strong><br>
                            <span class="label"><?= h((string) ($r['type'] ?? '')) ?></span>
                        </td>
                        <td><?= h(trim(($r['city'] ?? '') . ' / ' . ($r['district'] ?? ''), ' /')) ?></td>
                        <td class="mono"><?= admin_money($r['price']) ?> <?= h((string) $r['currency']) ?></td>
                        <td>
                            <?php
                            $st = (string) ($r['status'] ?? '');
                            $badge = $st === 'active' ? '' : ($st === 'occupied' ? 'badge-occupied' : 'badge-off');
                            ?>
                            <span class="badge <?= $badge ?>"><?= h($st) ?></span>
                        </td>
                        <td><?= h((string) $r['username']) ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
            <p style="margin-top:.75rem"><a class="btn btn-ghost btn-sm" href="listings.php">Barchasi</a></p>
        <?php endif; ?>
    </div>

    <div class="card">
        <h2>So'nggi shikoyatlar</h2>
        <?php if ($recentReports === []): ?>
            <p class="empty">Shikoyat yo'q.</p>
        <?php else: ?>
            <table>
                <thead>
                <tr>
                    <th>ID</th>
                    <th>Maqsad</th>
                    <th>Sabab</th>
                    <th>Kim</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($recentReports as $rep): ?>
                    <tr>
                        <td class="mono">#<?= (int) $rep['id'] ?></td>
                        <td>
                            <span class="badge"><?= h((string) $rep['target_type']) ?></span>
                            <span class="mono"><?= h((string) $rep['target_id']) ?></span>
                        </td>
                        <td><?php
                            $reason = (string) $rep['reason'];
                            echo h(strlen($reason) > 80 ? substr($reason, 0, 79) . '…' : $reason);
                        ?></td>
                        <td><?= h((string) $rep['reporter_username']) ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
            <p style="margin-top:.75rem"><a class="btn btn-ghost btn-sm" href="reports.php">Barchasi</a></p>
        <?php endif; ?>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
