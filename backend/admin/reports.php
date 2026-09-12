<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    $id = (int) ($_POST['id'] ?? 0);
    try {
        if (($action === 'delete' || $action === 'dismiss') && $id > 0) {
            $pdo->prepare('DELETE FROM xd_reports WHERE id=?')->execute([$id]);
            admin_flash("Shikoyat #$id o'chirildi / dismiss qilindi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    admin_redirect('reports.php');
}

$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;
$q = trim((string) ($_GET['q'] ?? ''));
$type = trim((string) ($_GET['type'] ?? ''));

$where = ['1=1'];
$params = [];
if ($q !== '') {
    $where[] = '(reporter_username LIKE ? OR reason LIKE ? OR target_id LIKE ?)';
    $like = '%' . $q . '%';
    array_push($params, $like, $like, $like);
}
if ($type !== '') {
    $where[] = 'target_type = ?';
    $params[] = $type;
}

$total = 0;
$reports = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xd_reports WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xd_reports WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $reports = [];
}

$baseQuery = http_build_query(array_filter(['q' => $q, 'type' => $type], static fn($v) => $v !== ''));

$pageTitle = 'Shikoyatlar';
$active = 'reports';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Shikoyatlar</h1>
        <p class="sub">Foydalanuvchi hisobotlari — dismiss / o'chirish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="reporter, sabab, target_id">
        </div>
        <div style="min-width:140px;flex:0 0 140px">
            <label>target_type</label>
            <input type="text" name="type" value="<?= h($type) ?>" placeholder="listing / user…">
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($reports === []): ?>
        <p class="empty">Shikoyat topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>target_type</th>
                <th>target_id</th>
                <th>Sabab</th>
                <th>Reporter</th>
                <th>Sana</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($reports as $r): ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td><span class="badge"><?= h((string) $r['target_type']) ?></span></td>
                    <td class="mono"><?= h((string) $r['target_id']) ?></td>
                    <td><?= h((string) $r['reason']) ?></td>
                    <td><?= h((string) $r['reporter_username']) ?></td>
                    <td class="muted"><?= h((string) ($r['created_at'] ?? '')) ?></td>
                    <td>
                        <div class="actions">
                            <form method="post" onsubmit="return confirm('Dismiss / o\'chirish?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                                <button class="btn btn-ghost btn-sm" name="action" value="dismiss" type="submit">Dismiss</button>
                                <button class="btn btn-danger btn-sm" name="action" value="delete" type="submit">O'chirish</button>
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
