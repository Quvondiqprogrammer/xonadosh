<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

$days = ['dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'];
$meals = ['breakfast', 'lunch', 'dinner'];

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    try {
        if ($action === 'delete') {
            $id = (int) ($_POST['id'] ?? 0);
            if ($id <= 0) {
                throw new RuntimeException('ID kerak');
            }
            $pdo->prepare('DELETE FROM xonadosh_meal_plans WHERE id=?')->execute([$id]);
            admin_flash("Taomnoma #$id o'chirildi");
        } elseif ($action === 'create') {
            $group = trim((string) ($_POST['group_code'] ?? 'home_default'));
            $day = (string) ($_POST['day_of_week'] ?? 'dushanba');
            $meal = (string) ($_POST['meal_time'] ?? 'dinner');
            $recipeId = isset($_POST['recipe_id']) && $_POST['recipe_id'] !== '' ? (int) $_POST['recipe_id'] : null;
            $recipeName = trim((string) ($_POST['recipe_name'] ?? ''));
            $cook = trim((string) ($_POST['cook_name'] ?? 'Navbatchi'));
            if ($recipeName === '' || $group === '') {
                throw new RuntimeException('group_code va recipe_name kerak');
            }
            if (!in_array($day, $days, true)) {
                $day = 'dushanba';
            }
            if (!in_array($meal, $meals, true)) {
                $meal = 'dinner';
            }
            $pdo->prepare(
                'INSERT INTO xonadosh_meal_plans
                (group_code, day_of_week, meal_time, recipe_id, recipe_name, cook_name)
                VALUES (?,?,?,?,?,?)'
            )->execute([$group, $day, $meal, $recipeId, $recipeName, $cook]);
            admin_flash('Taomnoma qo\'shildi');
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $g = trim((string) ($_GET['group'] ?? $_POST['group_code'] ?? ''));
    admin_redirect('meals.php' . ($g !== '' ? '?group=' . urlencode($g) : ''));
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
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_meal_plans WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_meal_plans WHERE $sqlWhere
         ORDER BY group_code, FIELD(day_of_week,'dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba'),
         FIELD(meal_time,'breakfast','lunch','dinner')
         LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $rows = [];
}

$baseQuery = http_build_query(array_filter(['group' => $group], static fn($v) => $v !== ''));

$pageTitle = 'Taomnoma';
$active = 'meals';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Taomnoma (meal plans)</h1>
        <p class="sub">Guruh bo'yicha ro'yxat, qo'shish, o'chirish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1.25rem">
    <h2>Yangi slot</h2>
    <form method="post">
        <?= admin_csrf_field() ?>
        <input type="hidden" name="action" value="create">
        <div class="form-row">
            <div>
                <label>group_code</label>
                <input name="group_code" value="<?= h($group !== '' ? $group : 'home_default') ?>" required>
            </div>
            <div>
                <label>Kun</label>
                <select name="day_of_week">
                    <?php foreach ($days as $d): ?>
                        <option value="<?= $d ?>"><?= $d ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div>
                <label>Mahal</label>
                <select name="meal_time">
                    <?php foreach ($meals as $m): ?>
                        <option value="<?= $m ?>"><?= $m ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div>
                <label>recipe_id</label>
                <input type="number" name="recipe_id" placeholder="ixtiyoriy">
            </div>
        </div>
        <div class="form-row">
            <div>
                <label>Retsept nomi</label>
                <input name="recipe_name" required>
            </div>
            <div>
                <label>Oshpaz</label>
                <input name="cook_name" value="Navbatchi">
            </div>
        </div>
        <div class="form-actions">
            <button class="btn btn-primary" type="submit">Qo'shish</button>
        </div>
    </form>
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
        <p class="empty">Taomnoma yo'q.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Guruh</th>
                <th>Kun</th>
                <th>Mahal</th>
                <th>Retsept</th>
                <th>Oshpaz</th>
                <th>Jadval</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td class="mono"><?= h((string) $r['group_code']) ?></td>
                    <td><?= h((string) $r['day_of_week']) ?></td>
                    <td><span class="badge"><?= h((string) $r['meal_time']) ?></span></td>
                    <td>
                        <?= h((string) $r['recipe_name']) ?>
                        <?php if (!empty($r['recipe_id'])): ?>
                            <span class="label mono">#<?= (int) $r['recipe_id'] ?></span>
                        <?php endif; ?>
                    </td>
                    <td><?= h((string) $r['cook_name']) ?></td>
                    <td class="label"><?= h((string) ($r['prep_schedule'] ?? '')) ?></td>
                    <td>
                        <form method="post" onsubmit="return confirm('O\'chirish?')">
                            <?= admin_csrf_field() ?>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                            <button class="btn btn-danger btn-sm" type="submit">Del</button>
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
