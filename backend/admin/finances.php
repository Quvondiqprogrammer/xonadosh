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
            $pdo->prepare('DELETE FROM xonadosh_finances WHERE id=?')->execute([$id]);
            admin_flash("Moliya #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $qs = http_build_query(array_filter([
        'type' => $_GET['type'] ?? '',
        'status' => $_GET['status'] ?? '',
        'group' => $_GET['group'] ?? '',
        'page' => $_GET['page'] ?? '',
    ], static fn($v) => $v !== '' && $v !== null));
    admin_redirect('finances.php' . ($qs !== '' ? '?' . $qs : ''));
}

$type = trim((string) ($_GET['type'] ?? ''));
$status = trim((string) ($_GET['status'] ?? ''));
$group = trim((string) ($_GET['group'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($type !== '') {
    $where[] = 'type = ?';
    $params[] = $type;
}
if ($status !== '') {
    $where[] = 'status = ?';
    $params[] = $status;
}
if ($group !== '') {
    $where[] = 'group_code = ?';
    $params[] = $group;
}

$total = 0;
$rows = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_finances WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_finances WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $rows = [];
}

$baseQuery = http_build_query(array_filter([
    'type' => $type,
    'status' => $status,
    'group' => $group,
], static fn($v) => $v !== ''));

$pageTitle = 'Moliya';
$active = 'finances';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Moliya & qarz</h1>
        <p class="sub">type / status / group filtri, o'chirish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>group_code</label>
            <input type="text" name="group" value="<?= h($group) ?>" placeholder="home_default">
        </div>
        <div style="min-width:140px;flex:0 0 140px">
            <label>Tur</label>
            <select name="type">
                <option value="">Barchasi</option>
                <?php foreach (['rent', 'utility', 'expense_split', 'debt'] as $t): ?>
                    <option value="<?= $t ?>" <?= $type === $t ? 'selected' : '' ?>><?= $t ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div style="min-width:150px;flex:0 0 150px">
            <label>Holat</label>
            <select name="status">
                <option value="">Barchasi</option>
                <?php foreach (['pending', 'partially_paid', 'settled'] as $s): ?>
                    <option value="<?= $s ?>" <?= $status === $s ? 'selected' : '' ?>><?= $s ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($rows === []): ?>
        <p class="empty">Yozuv topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Guruh</th>
                <th>Tur</th>
                <th>Sarlavha</th>
                <th>Summa</th>
                <th>To'lovchi</th>
                <th>Holat</th>
                <th>Muddat</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <?php
                $st = (string) ($r['status'] ?? '');
                $badge = $st === 'settled' ? '' : ($st === 'pending' ? 'badge-pending' : 'badge-warn');
                ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td class="mono"><?= h((string) $r['group_code']) ?></td>
                    <td><span class="badge"><?= h((string) $r['type']) ?></span></td>
                    <td>
                        <strong><?= h((string) $r['title']) ?></strong><br>
                        <span class="label"><?= h((string) ($r['category'] ?? '')) ?></span>
                    </td>
                    <td class="mono"><?= admin_money($r['amount_uzs']) ?> UZS</td>
                    <td><?= h((string) $r['paid_by']) ?></td>
                    <td><span class="badge <?= $badge ?>"><?= h($st) ?></span></td>
                    <td class="muted"><?= h((string) ($r['due_date'] ?? '—')) ?></td>
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
