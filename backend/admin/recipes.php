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
            $category = trim((string) ($_POST['category'] ?? 'Kechki ovqat'));
            $prep = (int) ($_POST['prep_time_min'] ?? 30);
            $cost = (string) ($_POST['cost_level'] ?? 'budget');
            $instructions = trim((string) ($_POST['instructions_uz'] ?? ''));
            $calories = (int) ($_POST['calories_kcal'] ?? 400);
            $image = trim((string) ($_POST['image_url'] ?? ''));
            $ingredientsRaw = trim((string) ($_POST['ingredients_json'] ?? '[]'));
            $decoded = json_decode($ingredientsRaw, true);
            if (!is_array($decoded)) {
                throw new RuntimeException('ingredients_json noto\'g\'ri JSON');
            }
            $ingredientsJson = json_encode($decoded, JSON_UNESCAPED_UNICODE);
            if ($name === '') {
                throw new RuntimeException('Taom nomi kerak');
            }
            if (!in_array($cost, ['budget', 'medium', 'high'], true)) {
                $cost = 'budget';
            }
            if ($action === 'create') {
                $pdo->prepare(
                    'INSERT INTO xonadosh_recipes
                    (name_uz, category, prep_time_min, cost_level, ingredients_json, instructions_uz, calories_kcal, image_url)
                    VALUES (?,?,?,?,?,?,?,?)'
                )->execute([
                    $name, $category, $prep, $cost, $ingredientsJson, $instructions, $calories,
                    $image !== '' ? $image : null,
                ]);
                admin_flash('Retsept qo\'shildi');
            } else {
                if ($id <= 0) {
                    throw new RuntimeException('ID kerak');
                }
                $pdo->prepare(
                    'UPDATE xonadosh_recipes SET name_uz=?, category=?, prep_time_min=?, cost_level=?,
                     ingredients_json=?, instructions_uz=?, calories_kcal=?, image_url=? WHERE id=?'
                )->execute([
                    $name, $category, $prep, $cost, $ingredientsJson, $instructions, $calories,
                    $image !== '' ? $image : null, $id,
                ]);
                admin_flash("Retsept #$id yangilandi");
            }
        } elseif ($action === 'delete') {
            $id = (int) ($_POST['id'] ?? 0);
            if ($id <= 0) {
                throw new RuntimeException('ID kerak');
            }
            $pdo->prepare('DELETE FROM xonadosh_recipes WHERE id=?')->execute([$id]);
            admin_flash("Retsept #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    admin_redirect('recipes.php' . (isset($_GET['edit']) && $action !== 'delete' ? '?edit=' . (int) ($_POST['id'] ?? 0) : ''));
}

$editId = isset($_GET['edit']) ? (int) $_GET['edit'] : 0;
$edit = null;
if ($editId > 0) {
    try {
        $st = $pdo->prepare('SELECT * FROM xonadosh_recipes WHERE id=?');
        $st->execute([$editId]);
        $edit = $st->fetch(PDO::FETCH_ASSOC) ?: null;
    } catch (Throwable $e) {
        $edit = null;
    }
}

$q = trim((string) ($_GET['q'] ?? ''));
$recipes = [];
try {
    if ($q !== '') {
        $st = $pdo->prepare('SELECT * FROM xonadosh_recipes WHERE name_uz LIKE ? OR category LIKE ? ORDER BY id ASC');
        $like = '%' . $q . '%';
        $st->execute([$like, $like]);
        $recipes = $st->fetchAll(PDO::FETCH_ASSOC);
    } else {
        $recipes = $pdo->query('SELECT * FROM xonadosh_recipes ORDER BY id ASC')->fetchAll(PDO::FETCH_ASSOC);
    }
} catch (Throwable $e) {
    $recipes = [];
}

$pageTitle = 'Retseptlar';
$active = 'recipes';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Retseptlar</h1>
        <p class="sub">CRUD — nom, kategoriya, ingredientlar, ko'rsatmalar</p>
    </div>
</div>

<div class="card" style="margin-bottom:1.25rem">
    <h2><?= $edit ? 'Retseptni tahrirlash #' . (int) $edit['id'] : 'Yangi retsept' ?></h2>
    <form method="post">
        <?= admin_csrf_field() ?>
        <input type="hidden" name="action" value="<?= $edit ? 'update' : 'create' ?>">
        <?php if ($edit): ?><input type="hidden" name="id" value="<?= (int) $edit['id'] ?>"><?php endif; ?>
        <label>Nomi (name_uz)</label>
        <input name="name_uz" required value="<?= h((string) ($edit['name_uz'] ?? '')) ?>">
        <div class="form-row">
            <div>
                <label>Kategoriya</label>
                <input name="category" value="<?= h((string) ($edit['category'] ?? 'Kechki ovqat')) ?>">
            </div>
            <div>
                <label>Tayyorlash (daq)</label>
                <input type="number" name="prep_time_min" value="<?= (int) ($edit['prep_time_min'] ?? 30) ?>">
            </div>
            <div>
                <label>Narx darajasi</label>
                <select name="cost_level">
                    <?php foreach (['budget', 'medium', 'high'] as $c): ?>
                        <option value="<?= $c ?>" <?= (($edit['cost_level'] ?? 'budget') === $c) ? 'selected' : '' ?>><?= $c ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div>
                <label>Kaloriya</label>
                <input type="number" name="calories_kcal" value="<?= (int) ($edit['calories_kcal'] ?? 400) ?>">
            </div>
        </div>
        <label>Image URL</label>
        <input name="image_url" value="<?= h((string) ($edit['image_url'] ?? '')) ?>">
        <label>Ingredients JSON</label>
        <textarea name="ingredients_json" rows="5"><?= h((string) ($edit['ingredients_json'] ?? '[]')) ?></textarea>
        <label>Ko'rsatmalar (instructions_uz)</label>
        <textarea name="instructions_uz" rows="4" style="font-family:var(--font)"><?= h((string) ($edit['instructions_uz'] ?? '')) ?></textarea>
        <div class="form-actions">
            <button class="btn btn-primary" type="submit"><?= $edit ? 'Saqlash' : 'Qo\'shish' ?></button>
            <?php if ($edit): ?><a class="btn btn-ghost" href="recipes.php">Bekor</a><?php endif; ?>
        </div>
    </form>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="nom yoki kategoriya">
        </div>
        <button class="btn btn-primary" type="submit">Qidirish</button>
    </form>
</div>

<div class="card">
    <h2>Ro'yxat (<?= count($recipes) ?>)</h2>
    <?php if ($recipes === []): ?>
        <p class="empty">Retsept yo'q.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Nomi</th>
                <th>Kat.</th>
                <th>Daq</th>
                <th>Narx</th>
                <th>kcal</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($recipes as $r): ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td><?= h((string) $r['name_uz']) ?></td>
                    <td><?= h((string) $r['category']) ?></td>
                    <td class="mono"><?= (int) $r['prep_time_min'] ?></td>
                    <td><span class="badge"><?= h((string) $r['cost_level']) ?></span></td>
                    <td class="mono"><?= (int) $r['calories_kcal'] ?></td>
                    <td>
                        <div class="actions">
                            <a class="btn btn-ghost btn-sm" href="recipes.php?edit=<?= (int) $r['id'] ?>">Edit</a>
                            <form method="post" onsubmit="return confirm('O\'chirish?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                                <button class="btn btn-danger btn-sm" type="submit">Del</button>
                            </form>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
