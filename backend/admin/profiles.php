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
        if ($action === 'pause') {
            $pdo->prepare("UPDATE xonadosh_profiles SET status='paused' WHERE id=?")->execute([$id]);
            admin_flash("Anketa #$id paused");
        } elseif ($action === 'looking') {
            $pdo->prepare("UPDATE xonadosh_profiles SET status='looking' WHERE id=?")->execute([$id]);
            admin_flash("Anketa #$id looking");
        } elseif ($action === 'delete') {
            $pdo->prepare('DELETE FROM xonadosh_profiles WHERE id=?')->execute([$id]);
            admin_flash("Anketa #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $qs = http_build_query(array_filter([
        'status' => $_GET['status'] ?? '',
        'q' => $_GET['q'] ?? '',
        'page' => $_GET['page'] ?? '',
    ], static fn($v) => $v !== '' && $v !== null));
    admin_redirect('profiles.php' . ($qs !== '' ? '?' . $qs : ''));
}

$status = trim((string) ($_GET['status'] ?? ''));
$q = trim((string) ($_GET['q'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($status !== '') {
    $where[] = 'status = ?';
    $params[] = $status;
}
if ($q !== '') {
    $where[] = '(username LIKE ? OR full_name LIKE ? OR phone_number LIKE ? OR university_name LIKE ?)';
    $like = '%' . $q . '%';
    array_push($params, $like, $like, $like, $like);
}

$total = 0;
$profiles = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_profiles WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_profiles WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $profiles = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $profiles = [];
}

$baseQuery = http_build_query(array_filter(['status' => $status, 'q' => $q], static fn($v) => $v !== ''));

$pageTitle = 'Anketalar';
$active = 'profiles';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Roommate anketalari</h1>
        <p class="sub">looking / paused / o'chirish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="ism, user, OTM">
        </div>
        <div style="min-width:140px;flex:0 0 140px">
            <label>Holat</label>
            <select name="status">
                <option value="">Barchasi</option>
                <option value="looking" <?= $status === 'looking' ? 'selected' : '' ?>>looking</option>
                <option value="paused" <?= $status === 'paused' ? 'selected' : '' ?>>paused</option>
            </select>
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($profiles === []): ?>
        <p class="empty">Anketa topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Ism</th>
                <th>User</th>
                <th>OTM</th>
                <th>Byudjet</th>
                <th>Jins / Yosh</th>
                <th>Holat</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($profiles as $p): ?>
                <?php $st = (string) ($p['status'] ?? ''); ?>
                <tr>
                    <td class="mono">#<?= (int) $p['id'] ?></td>
                    <td>
                        <strong><?= h((string) $p['full_name']) ?></strong><br>
                        <span class="label mono"><?= h((string) ($p['phone_number'] ?? '')) ?></span>
                    </td>
                    <td><?= h((string) $p['username']) ?></td>
                    <td><?= h((string) ($p['university_name'] ?? '—')) ?></td>
                    <td class="mono"><?= admin_money($p['budget_min'] ?? 0) ?> – <?= admin_money($p['budget_max'] ?? 0) ?></td>
                    <td><?= h((string) ($p['gender'] ?? '')) ?> · <?= (int) ($p['age'] ?? 0) ?></td>
                    <td>
                        <span class="badge <?= $st === 'looking' ? '' : 'badge-paused' ?>"><?= h($st) ?></span>
                    </td>
                    <td>
                        <div class="actions">
                            <form method="post" onsubmit="return confirm('Ishonchingiz komilmi?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="id" value="<?= (int) $p['id'] ?>">
                                <?php if ($st !== 'paused'): ?>
                                    <button class="btn btn-warn btn-sm" name="action" value="pause" type="submit">Pause</button>
                                <?php endif; ?>
                                <?php if ($st !== 'looking'): ?>
                                    <button class="btn btn-primary btn-sm" name="action" value="looking" type="submit">Looking</button>
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
