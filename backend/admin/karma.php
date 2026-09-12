<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    $id = (int) ($_POST['id'] ?? 0);
    try {
        if ($action === 'delete' && $id > 0) {
            $pdo->prepare('DELETE FROM xonadosh_karma WHERE id=?')->execute([$id]);
            admin_flash("Karma #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $g = trim((string) ($_GET['group'] ?? ''));
    admin_redirect('karma.php' . ($g !== '' ? '?group=' . urlencode($g) . (isset($_GET['page']) ? '&page=' . (int) $_GET['page'] : '') : ''));
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
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_karma WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_karma WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $rows = [];
}

$baseQuery = http_build_query(array_filter(['group' => $group], static fn($v) => $v !== ''));

$pageTitle = 'Karma';
$active = 'karma';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Obro' & karma</h1>
        <p class="sub">Tarix, guruh filtri, yozuvni o'chirish</p>
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
        <p class="empty">Karma yozuvi yo'q.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Guruh</th>
                <th>Kimdan</th>
                <th>Kimga</th>
                <th>Badge</th>
                <th>Ball</th>
                <th>Izoh</th>
                <th>Sana</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td class="mono"><?= h((string) $r['group_code']) ?></td>
                    <td><?= h((string) $r['from_name']) ?></td>
                    <td><strong><?= h((string) $r['to_name']) ?></strong></td>
                    <td>
                        <span class="badge"><?= h((string) $r['badge_name']) ?></span>
                        <span class="label mono"><?= h((string) $r['badge_key']) ?></span>
                    </td>
                    <td class="mono"><?= (int) ($r['points'] ?? 0) ?></td>
                    <td><?= h((string) ($r['comment'] ?? '')) ?></td>
                    <td class="muted"><?= h((string) ($r['created_at'] ?? '')) ?></td>
                    <td>
                        <form method="post" onsubmit="return confirm('O\'chirish?')">
                            <?= admin_csrf_field() ?>
                            <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                            <button class="btn btn-danger btn-sm" name="action" value="delete" type="submit">Del</button>
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
