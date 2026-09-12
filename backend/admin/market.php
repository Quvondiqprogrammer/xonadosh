<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    try {
        if ($action === 'update') {
            $key = trim((string) ($_POST['item_key'] ?? ''));
            $avg = (float) ($_POST['avg_price_uzs'] ?? 0);
            $min = (float) ($_POST['min_price_uzs'] ?? 0);
            $max = (float) ($_POST['max_price_uzs'] ?? 0);
            $source = trim((string) ($_POST['cheapest_source'] ?? ''));
            if ($key === '' || $avg <= 0) {
                throw new RuntimeException('Narx noto\'g\'ri');
            }
            if ($min <= 0) {
                $min = $avg * 0.9;
            }
            if ($max <= 0) {
                $max = $avg * 1.1;
            }
            $pdo->prepare(
                'UPDATE xonadosh_market_prices SET avg_price_uzs=?, min_price_uzs=?, max_price_uzs=?, cheapest_source=? WHERE item_key=?'
            )->execute([$avg, $min, $max, $source, $key]);
            admin_flash("Narx yangilandi: $key");
        } elseif ($action === 'create') {
            $key = trim((string) ($_POST['item_key'] ?? ''));
            $name = trim((string) ($_POST['name_uz'] ?? ''));
            $category = trim((string) ($_POST['category'] ?? 'Asosiy'));
            $unit = trim((string) ($_POST['unit'] ?? 'kg'));
            $avg = (float) ($_POST['avg_price_uzs'] ?? 0);
            $min = (float) ($_POST['min_price_uzs'] ?? 0);
            $max = (float) ($_POST['max_price_uzs'] ?? 0);
            $source = trim((string) ($_POST['cheapest_source'] ?? ''));
            $bazaar = trim((string) ($_POST['bazaar_sample'] ?? 'Chorsu'));
            if ($key === '' || $name === '' || $avg <= 0) {
                throw new RuntimeException('item_key, nom va o\'rtacha narx kerak');
            }
            if ($min <= 0) {
                $min = $avg * 0.9;
            }
            if ($max <= 0) {
                $max = $avg * 1.1;
            }
            $pdo->prepare(
                'INSERT INTO xonadosh_market_prices
                (item_key, name_uz, category, unit, avg_price_uzs, min_price_uzs, max_price_uzs, bazaar_sample, cheapest_source)
                VALUES (?,?,?,?,?,?,?,?,?)'
            )->execute([$key, $name, $category, $unit, $avg, $min, $max, $bazaar, $source !== '' ? $source : '—']);
            admin_flash("Mahsulot qo'shildi: $key");
        } elseif ($action === 'delete') {
            $key = trim((string) ($_POST['item_key'] ?? ''));
            if ($key === '') {
                throw new RuntimeException('item_key kerak');
            }
            $pdo->prepare('DELETE FROM xonadosh_market_prices WHERE item_key=?')->execute([$key]);
            admin_flash("O'chirildi: $key");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    admin_redirect('market.php');
}

$q = trim((string) ($_GET['q'] ?? ''));
$prices = [];
try {
    if ($q !== '') {
        $st = $pdo->prepare(
            'SELECT * FROM xonadosh_market_prices WHERE name_uz LIKE ? OR item_key LIKE ? OR category LIKE ? ORDER BY category, name_uz'
        );
        $like = '%' . $q . '%';
        $st->execute([$like, $like, $like]);
        $prices = $st->fetchAll(PDO::FETCH_ASSOC);
    } else {
        $prices = $pdo->query('SELECT * FROM xonadosh_market_prices ORDER BY category, name_uz')->fetchAll(PDO::FETCH_ASSOC);
    }
} catch (Throwable $e) {
    $prices = [];
}

$pageTitle = 'Bozor narxlari';
$active = 'market';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Bozor narxlari</h1>
        <p class="sub">avg / min / max / cheapest_source yangilash, yangi mahsulot</p>
    </div>
</div>

<div class="card" style="margin-bottom:1.25rem">
    <h2>Yangi mahsulot</h2>
    <form method="post">
        <?= admin_csrf_field() ?>
        <input type="hidden" name="action" value="create">
        <div class="form-row">
            <div>
                <label>item_key</label>
                <input name="item_key" required placeholder="beef">
            </div>
            <div>
                <label>Nomi</label>
                <input name="name_uz" required>
            </div>
            <div>
                <label>Kategoriya</label>
                <input name="category" value="Asosiy">
            </div>
            <div>
                <label>Birlik</label>
                <input name="unit" value="kg">
            </div>
        </div>
        <div class="form-row">
            <div>
                <label>O'rtacha</label>
                <input type="number" name="avg_price_uzs" required>
            </div>
            <div>
                <label>Min</label>
                <input type="number" name="min_price_uzs">
            </div>
            <div>
                <label>Max</label>
                <input type="number" name="max_price_uzs">
            </div>
            <div>
                <label>Bozor namuna</label>
                <input name="bazaar_sample" value="Chorsu">
            </div>
        </div>
        <label>Eng arzon manba</label>
        <input name="cheapest_source" placeholder="Qo'yliq ulgurji…">
        <div class="form-actions">
            <button class="btn btn-primary" type="submit">Qo'shish</button>
        </div>
    </form>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="nom, key, kategoriya">
        </div>
        <button class="btn btn-primary" type="submit">Qidirish</button>
    </form>
</div>

<div class="card">
    <h2>Narxlar (<?= count($prices) ?>)</h2>
    <?php if ($prices === []): ?>
        <p class="empty">Mahsulot yo'q.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>Mahsulot</th>
                <th>O'rt / Min / Max</th>
                <th>Manba</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($prices as $p): ?>
                <tr>
                    <td>
                        <strong><?= h((string) $p['name_uz']) ?></strong><br>
                        <span class="label mono"><?= h((string) $p['item_key']) ?> · <?= h((string) $p['unit']) ?> · <?= h((string) $p['category']) ?></span>
                    </td>
                    <td>
                        <form method="post" class="actions" style="flex-direction:column;align-items:stretch;gap:.4rem">
                            <?= admin_csrf_field() ?>
                            <input type="hidden" name="action" value="update">
                            <input type="hidden" name="item_key" value="<?= h((string) $p['item_key']) ?>">
                            <div class="form-row" style="min-width:280px">
                                <input type="number" name="avg_price_uzs" value="<?= (int) $p['avg_price_uzs'] ?>" title="avg">
                                <input type="number" name="min_price_uzs" value="<?= (int) $p['min_price_uzs'] ?>" title="min">
                                <input type="number" name="max_price_uzs" value="<?= (int) $p['max_price_uzs'] ?>" title="max">
                            </div>
                            <input type="text" name="cheapest_source" value="<?= h((string) ($p['cheapest_source'] ?? '')) ?>">
                            <button class="btn btn-primary btn-sm" type="submit">Saqlash</button>
                        </form>
                    </td>
                    <td class="label"><?= h((string) ($p['cheapest_source'] ?? '')) ?></td>
                    <td>
                        <form method="post" onsubmit="return confirm('O\'chirish?')">
                            <?= admin_csrf_field() ?>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="item_key" value="<?= h((string) $p['item_key']) ?>">
                            <button class="btn btn-danger btn-sm" type="submit">Del</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
