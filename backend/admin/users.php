<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    $id = (int) ($_POST['id'] ?? 0);
    $username = trim((string) ($_POST['username'] ?? ''));
    try {
        if ($action === 'block' && $id > 0) {
            $pdo->prepare('UPDATE xd_users SET is_blocked=1 WHERE id=?')->execute([$id]);
            admin_flash("Foydalanuvchi #$id bloklandi");
        } elseif ($action === 'unblock' && $id > 0) {
            $pdo->prepare('UPDATE xd_users SET is_blocked=0 WHERE id=?')->execute([$id]);
            admin_flash("Foydalanuvchi #$id blokdan chiqarildi");
        } elseif ($action === 'soft_delete' && $id > 0) {
            $pdo->prepare('UPDATE xd_users SET deleted_at=NOW() WHERE id=?')->execute([$id]);
            admin_flash("Foydalanuvchi #$id soft-delete qilindi");
        } elseif ($action === 'restore' && $id > 0) {
            $pdo->prepare('UPDATE xd_users SET deleted_at=NULL WHERE id=?')->execute([$id]);
            admin_flash("Foydalanuvchi #$id tiklandi");
        } elseif ($action === 'revoke_sessions' && $username !== '') {
            $pdo->prepare('DELETE FROM xd_sessions WHERE username=?')->execute([$username]);
            admin_flash("Sessiyalar bekor qilindi: $username");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $qs = http_build_query(array_filter([
        'q' => $_GET['q'] ?? ($_POST['q'] ?? ''),
        'blocked' => $_GET['blocked'] ?? ($_POST['blocked'] ?? ''),
        'page' => $_GET['page'] ?? '',
    ], static fn($v) => $v !== '' && $v !== null));
    admin_redirect('users.php' . ($qs !== '' ? '?' . $qs : ''));
}

$q = trim((string) ($_GET['q'] ?? ''));
$blocked = trim((string) ($_GET['blocked'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($q !== '') {
    $where[] = '(username LIKE ? OR full_name LIKE ? OR phone LIKE ?)';
    $like = '%' . $q . '%';
    array_push($params, $like, $like, $like);
}
if ($blocked === '1') {
    $where[] = 'is_blocked = 1';
} elseif ($blocked === '0') {
    $where[] = 'is_blocked = 0';
} elseif ($blocked === 'deleted') {
    $where[] = 'deleted_at IS NOT NULL';
} else {
    $where[] = 'deleted_at IS NULL';
}

$total = 0;
$users = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xd_users WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xd_users WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $users = [];
}

$baseQuery = http_build_query(array_filter(['q' => $q, 'blocked' => $blocked], static fn($v) => $v !== ''));

$pageTitle = 'Foydalanuvchilar';
$active = 'users';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Foydalanuvchilar</h1>
        <p class="sub">Qidirish, bloklash, soft-delete, sessiyalarni bekor qilish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>Qidiruv</label>
            <input type="text" name="q" value="<?= h($q) ?>" placeholder="username, ism, telefon">
        </div>
        <div style="min-width:160px;flex:0 0 160px">
            <label>Holat</label>
            <select name="blocked">
                <option value="" <?= $blocked === '' ? 'selected' : '' ?>>Faol (o'chirilmagan)</option>
                <option value="1" <?= $blocked === '1' ? 'selected' : '' ?>>Bloklangan</option>
                <option value="0" <?= $blocked === '0' ? 'selected' : '' ?>>Bloklanmagan</option>
                <option value="deleted" <?= $blocked === 'deleted' ? 'selected' : '' ?>>Soft-delete</option>
            </select>
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($users === []): ?>
        <p class="empty">Foydalanuvchi topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Ism</th>
                <th>Telefon</th>
                <th>Holat</th>
                <th>Yaratilgan</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($users as $u): ?>
                <?php
                $isBlocked = (int) ($u['is_blocked'] ?? 0) === 1;
                $isDeleted = !empty($u['deleted_at']);
                ?>
                <tr>
                    <td class="mono">#<?= (int) $u['id'] ?></td>
                    <td><strong><?= h((string) $u['username']) ?></strong></td>
                    <td><?= h((string) $u['full_name']) ?></td>
                    <td class="mono"><?= h((string) ($u['phone'] ?? '')) ?></td>
                    <td>
                        <?php if ($isDeleted): ?>
                            <span class="badge badge-off">deleted</span>
                        <?php elseif ($isBlocked): ?>
                            <span class="badge badge-blocked">blocked</span>
                        <?php else: ?>
                            <span class="badge">active</span>
                        <?php endif; ?>
                    </td>
                    <td class="muted"><?= h((string) ($u['created_at'] ?? '')) ?></td>
                    <td>
                        <div class="actions">
                            <?php if (!$isDeleted): ?>
                                <?php if ($isBlocked): ?>
                                    <form method="post" onsubmit="return confirm('Blokdan chiqarilsinmi?')">
                                        <?= admin_csrf_field() ?>
                                        <input type="hidden" name="id" value="<?= (int) $u['id'] ?>">
                                        <button class="btn btn-primary btn-sm" name="action" value="unblock" type="submit">Unblock</button>
                                    </form>
                                <?php else: ?>
                                    <form method="post" onsubmit="return confirm('Bloklansinmi?')">
                                        <?= admin_csrf_field() ?>
                                        <input type="hidden" name="id" value="<?= (int) $u['id'] ?>">
                                        <button class="btn btn-warn btn-sm" name="action" value="block" type="submit">Block</button>
                                    </form>
                                <?php endif; ?>
                                <form method="post" onsubmit="return confirm('Soft-delete?')">
                                    <?= admin_csrf_field() ?>
                                    <input type="hidden" name="id" value="<?= (int) $u['id'] ?>">
                                    <button class="btn btn-danger btn-sm" name="action" value="soft_delete" type="submit">O'chirish</button>
                                </form>
                            <?php else: ?>
                                <form method="post">
                                    <?= admin_csrf_field() ?>
                                    <input type="hidden" name="id" value="<?= (int) $u['id'] ?>">
                                    <button class="btn btn-primary btn-sm" name="action" value="restore" type="submit">Restore</button>
                                </form>
                            <?php endif; ?>
                            <form method="post" onsubmit="return confirm('Barcha sessiyalar bekor qilinsinmi?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="username" value="<?= h((string) $u['username']) ?>">
                                <button class="btn btn-ghost btn-sm" name="action" value="revoke_sessions" type="submit">Sessiyalar</button>
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
