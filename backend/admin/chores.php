<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    $id = (int) ($_POST['id'] ?? 0);
    try {
        if ($id <= 0) {
            throw new RuntimeException('ID kerak');
        }
        if ($action === 'toggle') {
            $st = $pdo->prepare('SELECT is_completed FROM xonadosh_chores WHERE id=?');
            $st->execute([$id]);
            $cur = (int) $st->fetchColumn();
            $new = $cur === 1 ? 0 : 1;
            $pdo->prepare('UPDATE xonadosh_chores SET is_completed=?, completed_at=? WHERE id=?')
                ->execute([$new, $new === 1 ? date('Y-m-d H:i:s') : null, $id]);
            admin_flash("Navbatchilik #$id holati o'zgardi");
        } elseif ($action === 'delete') {
            $pdo->prepare('DELETE FROM xonadosh_chores WHERE id=?')->execute([$id]);
            admin_flash("Navbatchilik #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $g = trim((string) ($_GET['group'] ?? ''));
    admin_redirect('chores.php' . ($g !== '' ? '?group=' . urlencode($g) : ''));
}

$group = trim((string) ($_GET['group'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($group !== '') {
    $where[] = 'group_code = ?';
    $params[] = $group;
}

$total = 0;
$rows = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_chores WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_chores WHERE $sqlWhere
         ORDER BY group_code, FIELD(day_of_week,'dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba'), id
         LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $rows = [];
}

$baseQuery = http_build_query(array_filter(['group' => $group], static fn($v) => $v !== ''));

$pageTitle = 'Navbatchilik';
$active = 'chores';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Navbatchilik (chores)</h1>
        <p class="sub">Toggle complete, o'chirish, group_code filtri</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>group_code</label>
            <input type="text" name="group" value="<?= h($group) ?>" placeholder="home_default">
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($rows === []): ?>
        <p class="empty">Navbatchilik yo'q.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Guruh</th>
                <th>Kun</th>
                <th>Tur</th>
                <th>Vazifa</th>
                <th>Mas'ul</th>
                <th>Holat</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <?php $done = (int) ($r['is_completed'] ?? 0) === 1; ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td class="mono"><?= h((string) $r['group_code']) ?></td>
                    <td><?= h((string) $r['day_of_week']) ?></td>
                    <td><span class="badge"><?= h((string) $r['chore_type']) ?></span></td>
                    <td><?= h((string) $r['title']) ?></td>
                    <td><?= h((string) $r['assigned_name']) ?></td>
                    <td>
                        <?php if ($done): ?>
                            <span class="badge">completed</span>
                        <?php else: ?>
                            <span class="badge badge-pending">open</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <div class="actions">
                            <form method="post">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                                <button class="btn btn-ghost btn-sm" name="action" value="toggle" type="submit">
                                    <?= $done ? 'Undo' : 'Complete' ?>
                                </button>
                            </form>
                            <form method="post" onsubmit="return confirm('O\'chirish?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                                <button class="btn btn-danger btn-sm" name="action" value="delete" type="submit">Del</button>
                            </form>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        <?= admin_pager($page, $per, $total, $baseQuery) ?>
    <?php endif; ?>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
