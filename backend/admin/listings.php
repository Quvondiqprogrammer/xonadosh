<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $id = (int) ($_POST['id'] ?? 0);
    $action = (string) ($_POST['action'] ?? '');
    try {
        if ($id <= 0) {
            throw new RuntimeException('ID kerak');
        }
        if ($action === 'activate') {
            $pdo->prepare("UPDATE xonadosh_listings SET status='active' WHERE id=?")->execute([$id]);
            admin_flash("E'lon #$id faollashtirildi");
        } elseif ($action === 'deactivate') {
            $pdo->prepare("UPDATE xonadosh_listings SET status='inactive' WHERE id=?")->execute([$id]);
            admin_flash("E'lon #$id inactive qilindi");
        } elseif ($action === 'occupied') {
            $pdo->prepare("UPDATE xonadosh_listings SET status='occupied' WHERE id=?")->execute([$id]);
            admin_flash("E'lon #$id occupied qilindi");
        } elseif ($action === 'delete') {
            $pdo->prepare('DELETE FROM xonadosh_listings WHERE id=?')->execute([$id]);
            admin_flash("E'lon #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $qs = http_build_query(array_filter([
        'q' => $_GET['q'] ?? '',
        'status' => $_GET['status'] ?? '',
        'type' => $_GET['type'] ?? '',
        'page' => $_GET['page'] ?? '',
    ], static fn($v) => $v !== '' && $v !== null));
    admin_redirect('listings.php' . ($qs !== '' ? '?' . $qs : ''));
}

$q = trim((string) ($_GET['q'] ?? ''));
$status = trim((string) ($_GET['status'] ?? ''));
$type = trim((string) ($_GET['type'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($q !== '') {
    $where[] = '(title LIKE ? OR address LIKE ? OR username LIKE ? OR phone_number LIKE ? OR owner_name LIKE ?)';
    $like = '%' . $q . '%';
    array_push($params, $like, $like, $like, $like, $like);
}
if ($status !== '') {
    $where[] = 'status = ?';
    $params[] = $status;
}
if ($type !== '') {
    $where[] = 'type = ?';
    $params[] = $type;
}

$total = 0;
$listings = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_listings WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_listings WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $listings = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $listings = [];
}

$baseQuery = http_build_query(array_filter([
    'q' => $q,
    'status' => $status,
    'type' => $type,
], static fn($v) => $v !== ''));

$pageTitle = "E'lonlar";
$active = 'listings';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Turar-joy e'lonlari</h1>
        <p class="sub">Qidiruv, status/tur filtri, activate / deactivate / occupied / delete</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="sarlavha, user, telefon, manzil">
        </div>
        <div style="min-width:130px;flex:0 0 130px">
            <label>Holat</label>
            <select name="status">
                <option value="">Barchasi</option>
                <?php foreach (['active', 'inactive', 'occupied'] as $s): ?>
                    <option value="<?= $s ?>" <?= $status === $s ? 'selected' : '' ?>><?= $s ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div style="min-width:150px;flex:0 0 150px">
            <label>Tur</label>
            <select name="type">
                <option value="">Barchasi</option>
                <?php foreach (['rent', 'roommate_wanted', 'sell', 'buy'] as $t): ?>
                    <option value="<?= $t ?>" <?= $type === $t ? 'selected' : '' ?>><?= $t ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($listings === []): ?>
        <p class="empty">E'lon topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Sarlavha</th>
                <th>Narx</th>
                <th>Tur</th>
                <th>Hudud</th>
                <th>Xona</th>
                <th>Holat</th>
                <th>User</th>
                <th>Ko'rish</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($listings as $l): ?>
                <?php
                $st = (string) ($l['status'] ?? '');
                $badge = $st === 'active' ? '' : ($st === 'occupied' ? 'badge-occupied' : 'badge-off');
                ?>
                <tr>
                    <td class="mono">#<?= (int) $l['id'] ?></td>
                    <td>
                        <strong><?= h((string) $l['title']) ?></strong><br>
                        <span class="label"><?= h((string) ($l['owner_name'] ?? '')) ?></span>
                    </td>
                    <td class="mono"><?= admin_money($l['price']) ?> <?= h((string) $l['currency']) ?></td>
                    <td><?= h((string) $l['type']) ?></td>
                    <td><?= h(trim(($l['city'] ?? '') . ', ' . ($l['district'] ?? ''), ', ')) ?></td>
                    <td class="mono"><?= (int) ($l['rooms_count'] ?? 0) ?>x · <?= h((string) ($l['area_sqm'] ?? '')) ?> m²</td>
                    <td><span class="badge <?= $badge ?>"><?= h($st) ?></span></td>
                    <td>
                        <?= h((string) $l['username']) ?><br>
                        <span class="label mono"><?= h((string) ($l['phone_number'] ?? '')) ?></span>
                    </td>
                    <td class="mono"><?= (int) ($l['views_count'] ?? 0) ?></td>
                    <td>
                        <div class="actions">
                            <form method="post" onsubmit="return confirm('Ishonchingiz komilmi?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="id" value="<?= (int) $l['id'] ?>">
                                <?php if ($st !== 'active'): ?>
                                    <button class="btn btn-primary btn-sm" name="action" value="activate" type="submit">Faol</button>
                                <?php endif; ?>
                                <?php if ($st !== 'inactive'): ?>
                                    <button class="btn btn-ghost btn-sm" name="action" value="deactivate" type="submit">Inactive</button>
                                <?php endif; ?>
                                <?php if ($st !== 'occupied'): ?>
                                    <button class="btn btn-warn btn-sm" name="action" value="occupied" type="submit">Occupied</button>
                                <?php endif; ?>
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
