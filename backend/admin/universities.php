<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    try {
        if ($action === 'create' || $action === 'update') {
            $id = (int) ($_POST['id'] ?? 0);
            $name = trim((string) ($_POST['name_uz'] ?? ''));
            $short = trim((string) ($_POST['short_name'] ?? ''));
            $city = trim((string) ($_POST['city'] ?? 'Toshkent'));
            $district = trim((string) ($_POST['district'] ?? ''));
            $address = trim((string) ($_POST['address'] ?? ''));
            $lat = (float) ($_POST['latitude'] ?? 0);
            $lng = (float) ($_POST['longitude'] ?? 0);
            $metro = trim((string) ($_POST['nearest_metro'] ?? ''));
            $metroDist = isset($_POST['metro_distance_m']) && $_POST['metro_distance_m'] !== '' ? (int) $_POST['metro_distance_m'] : null;
            if ($name === '' || $short === '' || $district === '' || $address === '') {
                throw new RuntimeException('Majburiy maydonlar to\'ldirilishi kerak');
            }
            if ($action === 'create') {
                $pdo->prepare(
                    'INSERT INTO xonadosh_universities
                    (name_uz, short_name, city, district, address, latitude, longitude, nearest_metro, metro_distance_m)
                    VALUES (?,?,?,?,?,?,?,?,?)'
                )->execute([
                    $name, $short, $city, $district, $address, $lat, $lng,
                    $metro !== '' ? $metro : null, $metroDist,
                ]);
                admin_flash('OTM qo\'shildi');
            } else {
                if ($id <= 0) {
                    throw new RuntimeException('ID kerak');
                }
                $pdo->prepare(
                    'UPDATE xonadosh_universities SET name_uz=?, short_name=?, city=?, district=?, address=?,
                     latitude=?, longitude=?, nearest_metro=?, metro_distance_m=? WHERE id=?'
                )->execute([
                    $name, $short, $city, $district, $address, $lat, $lng,
                    $metro !== '' ? $metro : null, $metroDist, $id,
                ]);
                admin_flash("OTM #$id yangilandi");
            }
        } elseif ($action === 'delete') {
            $id = (int) ($_POST['id'] ?? 0);
            if ($id <= 0) {
                throw new RuntimeException('ID kerak');
            }
            $pdo->prepare('DELETE FROM xonadosh_universities WHERE id=?')->execute([$id]);
            admin_flash("OTM #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    admin_redirect('universities.php');
}

$editId = isset($_GET['edit']) ? (int) $_GET['edit'] : 0;
$edit = null;
if ($editId > 0) {
    try {
        $st = $pdo->prepare('SELECT * FROM xonadosh_universities WHERE id=?');
        $st->execute([$editId]);
        $edit = $st->fetch(PDO::FETCH_ASSOC) ?: null;
    } catch (Throwable $e) {
        $edit = null;
    }
}

$q = trim((string) ($_GET['q'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($q !== '') {
    $where[] = '(name_uz LIKE ? OR short_name LIKE ? OR city LIKE ? OR district LIKE ?)';
    $like = '%' . $q . '%';
    array_push($params, $like, $like, $like, $like);
}

$total = 0;
$unis = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_universities WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_universities WHERE $sqlWhere ORDER BY city, name_uz LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $unis = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $unis = [];
}

$baseQuery = http_build_query(array_filter(['q' => $q], static fn($v) => $v !== ''));

$pageTitle = 'OTMlar';
$active = 'universities';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Universitetlar (OTM)</h1>
        <p class="sub">CRUD — qo'shish, tahrirlash, o'chirish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1.25rem">
    <h2><?= $edit ? 'OTMni tahrirlash #' . (int) $edit['id'] : 'Yangi OTM' ?></h2>
    <form method="post">
        <?= admin_csrf_field() ?>
        <input type="hidden" name="action" value="<?= $edit ? 'update' : 'create' ?>">
        <?php if ($edit): ?><input type="hidden" name="id" value="<?= (int) $edit['id'] ?>"><?php endif; ?>
        <label>To'liq nomi</label>
        <input name="name_uz" required value="<?= h((string) ($edit['name_uz'] ?? '')) ?>">
        <div class="form-row">
            <div>
                <label>Qisqa nom</label>
                <input name="short_name" required value="<?= h((string) ($edit['short_name'] ?? '')) ?>">
            </div>
            <div>
                <label>Shahar</label>
                <input name="city" value="<?= h((string) ($edit['city'] ?? 'Toshkent')) ?>">
            </div>
            <div>
                <label>Tuman</label>
                <input name="district" required value="<?= h((string) ($edit['district'] ?? '')) ?>">
            </div>
        </div>
        <label>Manzil</label>
        <input name="address" required value="<?= h((string) ($edit['address'] ?? '')) ?>">
        <div class="form-row">
            <div>
                <label>Latitude</label>
                <input type="number" step="any" name="latitude" value="<?= h((string) ($edit['latitude'] ?? '41.31')) ?>">
            </div>
            <div>
                <label>Longitude</label>
                <input type="number" step="any" name="longitude" value="<?= h((string) ($edit['longitude'] ?? '69.24')) ?>">
            </div>
            <div>
                <label>Metro</label>
                <input name="nearest_metro" value="<?= h((string) ($edit['nearest_metro'] ?? '')) ?>">
            </div>
            <div>
                <label>Metro masofa (m)</label>
                <input type="number" name="metro_distance_m" value="<?= h((string) ($edit['metro_distance_m'] ?? '')) ?>">
            </div>
        </div>
        <div class="form-actions">
            <button class="btn btn-primary" type="submit"><?= $edit ? 'Saqlash' : 'Qo\'shish' ?></button>
            <?php if ($edit): ?><a class="btn btn-ghost" href="universities.php">Bekor</a><?php endif; ?>
        </div>
    </form>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="nom, shahar, tuman">
        </div>
        <button class="btn btn-primary" type="submit">Qidirish</button>
    </form>
</div>

<div class="card">
    <?php if ($unis === []): ?>
        <p class="empty">OTM topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Nomi</th>
                <th>Hudud</th>
                <th>Metro</th>
                <th>Koordinata</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($unis as $u): ?>
                <tr>
                    <td class="mono">#<?= (int) $u['id'] ?></td>
                    <td>
                        <strong><?= h((string) $u['short_name']) ?></strong><br>
                        <span class="label"><?= h((string) $u['name_uz']) ?></span>
                    </td>
                    <td><?= h((string) $u['city']) ?> / <?= h((string) $u['district']) ?></td>
                    <td><?= h((string) ($u['nearest_metro'] ?? '—')) ?></td>
                    <td class="mono"><?= h((string) $u['latitude']) ?>, <?= h((string) $u['longitude']) ?></td>
                    <td>
                        <div class="actions">
                            <a class="btn btn-ghost btn-sm" href="universities.php?edit=<?= (int) $u['id'] ?>">Edit</a>
                            <form method="post" onsubmit="return confirm('O\'chirish?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= (int) $u['id'] ?>">
                                <button class="btn btn-danger btn-sm" type="submit">O'chirish</button>
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
