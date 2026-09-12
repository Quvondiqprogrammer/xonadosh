<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();
$nowMs = (int) (microtime(true) * 1000);

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    try {
        if ($action === 'revoke') {
            $token = trim((string) ($_POST['token'] ?? ''));
            if ($token === '') {
                throw new RuntimeException('Token kerak');
            }
            $pdo->prepare('DELETE FROM xd_sessions WHERE token=?')->execute([$token]);
            admin_flash('Sessiya bekor qilindi');
        } elseif ($action === 'purge_expired') {
            $st = $pdo->prepare('DELETE FROM xd_sessions WHERE expires_at <= ?');
            $st->execute([$nowMs]);
            admin_flash('Muddati o\'tgan sessiyalar tozalandi: ' . $st->rowCount());
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    admin_redirect('sessions.php');
}

$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;
$q = trim((string) ($_GET['q'] ?? ''));

$where = ['expires_at > ?'];
$params = [$nowMs];
if ($q !== '') {
    $where[] = 'username LIKE ?';
    $params[] = '%' . $q . '%';
}

$total = 0;
$sessions = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xd_sessions WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xd_sessions WHERE $sqlWhere ORDER BY expires_at DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $sessions = [];
}

$baseQuery = http_build_query(array_filter(['q' => $q], static fn($v) => $v !== ''));

$pageTitle = 'Sessiyalar';
$active = 'sessions';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Faol sessiyalar</h1>
        <p class="sub">expires_at &gt; hozir (ms). Token bo'yicha bekor qilish.</p>
    </div>
    <form method="post" onsubmit="return confirm('Muddati o\'tgan sessiyalar o\'chirilsinmi?')">
        <?= admin_csrf_field() ?>
        <button class="btn btn-warn" name="action" value="purge_expired" type="submit">Expired tozalash</button>
    </form>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Username</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="username">
        </div>
        <button class="btn btn-primary" type="submit">Qidirish</button>
    </form>
</div>

<div class="card">
    <?php if ($sessions === []): ?>
        <p class="empty">Faol sessiya yo'q.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>Username</th>
                <th>Token</th>
                <th>Yaratilgan</th>
                <th>Tugash</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($sessions as $s): ?>
                <?php
                $created = (int) ($s['created_at'] ?? 0);
                $expires = (int) ($s['expires_at'] ?? 0);
                $token = (string) $s['token'];
                $short = strlen($token) > 16 ? substr($token, 0, 8) . '…' . substr($token, -6) : $token;
                ?>
                <tr>
                    <td><strong><?= h((string) $s['username']) ?></strong></td>
                    <td class="mono" title="<?= h($token) ?>"><?= h($short) ?></td>
                    <td class="muted"><?= $created > 0 ? h(date('Y-m-d H:i', (int) ($created / 1000))) : '—' ?></td>
                    <td class="muted"><?= $expires > 0 ? h(date('Y-m-d H:i', (int) ($expires / 1000))) : '—' ?></td>
                    <td>
                        <form method="post" class="actions" onsubmit="return confirm('Sessiya bekor qilinsinmi?')">
                            <?= admin_csrf_field() ?>
                            <input type="hidden" name="token" value="<?= h($token) ?>">
                            <button class="btn btn-danger btn-sm" name="action" value="revoke" type="submit">Revoke</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        <?= admin_pager($page, $per, $total, $baseQuery) ?>
    <?php endif; ?>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
