<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
admin_require_login();

$pdo = xd_pdo();

if (admin_post_ok()) {
    $action = (string) ($_POST['action'] ?? '');
    $id = (int) ($_POST['id'] ?? 0);
    try {
        if ($id <= 0) {
            throw new RuntimeException('ID kerak');
        }
        if ($action === 'close') {
            $pdo->prepare("UPDATE xonadosh_polls SET status='closed' WHERE id=?")->execute([$id]);
            admin_flash("So'rov #$id yopildi");
        } elseif ($action === 'delete') {
            try {
                $pdo->prepare('DELETE FROM xonadosh_poll_votes WHERE poll_id=?')->execute([$id]);
            } catch (Throwable $e) {
                // votes table may be missing
            }
            $pdo->prepare('DELETE FROM xonadosh_polls WHERE id=?')->execute([$id]);
            admin_flash("So'rov #$id o'chirildi");
        } else {
            admin_flash('Noto\'g\'ri amal', 'err');
        }
    } catch (Throwable $e) {
        admin_flash($e->getMessage(), 'err');
    }
    $qs = http_build_query(array_filter([
        'group' => $_GET['group'] ?? '',
        'status' => $_GET['status'] ?? '',
        'page' => $_GET['page'] ?? '',
    ], static fn($v) => $v !== '' && $v !== null));
    admin_redirect('polls.php' . ($qs !== '' ? '?' . $qs : ''));
}

$group = trim((string) ($_GET['group'] ?? ''));
$status = trim((string) ($_GET['status'] ?? ''));
$page = admin_page();
$per = admin_per_page();
$offset = ($page - 1) * $per;

$where = ['1=1'];
$params = [];
if ($group !== '') {
    $where[] = 'group_code = ?';
    $params[] = $group;
}
if ($status !== '') {
    $where[] = 'status = ?';
    $params[] = $status;
}

$total = 0;
$rows = [];
try {
    $sqlWhere = implode(' AND ', $where);
    $cst = $pdo->prepare("SELECT COUNT(*) FROM xonadosh_polls WHERE $sqlWhere");
    $cst->execute($params);
    $total = (int) $cst->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT * FROM xonadosh_polls WHERE $sqlWhere ORDER BY id DESC LIMIT $per OFFSET $offset"
    );
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $rows = [];
}

$baseQuery = http_build_query(array_filter(['group' => $group, 'status' => $status], static fn($v) => $v !== ''));

$pageTitle = 'So\'rovlar';
$active = 'polls';
require __DIR__ . '/includes/header.php';
?>
<div class="topbar">
    <div>
        <h1>Anonim so'rovlar</h1>
        <p class="sub">Yopish (closed), o'chirish</p>
    </div>
</div>

<div class="card" style="margin-bottom:1rem">
    <form method="get" class="filters">
        <div>
            <label>group_code</label>
            <input type="text" name="group" value="<?= h($group) ?>" placeholder="home_default">
        </div>
        <div style="min-width:140px;flex:0 0 140px">
            <label>Holat</label>
            <select name="status">
                <option value="">Barchasi</option>
                <?php foreach (['active', 'passed', 'rejected', 'closed'] as $s): ?>
                    <option value="<?= $s ?>" <?= $status === $s ? 'selected' : '' ?>><?= $s ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <button class="btn btn-primary" type="submit">Filtrlash</button>
    </form>
</div>

<div class="card">
    <?php if ($rows === []): ?>
        <p class="empty">So'rov topilmadi.</p>
    <?php else: ?>
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Guruh</th>
                <th>Sarlavha</th>
                <th>Kat.</th>
                <th>Ovozlar</th>
                <th>Holat</th>
                <th>Sana</th>
                <th></th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <?php
                $st = (string) ($r['status'] ?? '');
                $badge = $st === 'active' ? '' : ($st === 'closed' ? 'badge-closed' : 'badge-off');
                ?>
                <tr>
                    <td class="mono">#<?= (int) $r['id'] ?></td>
                    <td class="mono"><?= h((string) $r['group_code']) ?></td>
                    <td>
                        <strong><?= h((string) $r['title']) ?></strong>
                        <?php if (!empty($r['description'])): ?>
                            <br><span class="label"><?php
                                $desc = (string) $r['description'];
                                echo h(strlen($desc) > 90 ? substr($desc, 0, 89) . '…' : $desc);
                            ?></span>
                        <?php endif; ?>
                    </td>
                    <td><?= h((string) ($r['category'] ?? '')) ?></td>
                    <td class="mono">
                        Y<?= (int) ($r['votes_yes'] ?? 0) ?>
                        / N<?= (int) ($r['votes_no'] ?? 0) ?>
                        / —<?= (int) ($r['votes_neutral'] ?? 0) ?>
                    </td>
                    <td><span class="badge <?= $badge ?>"><?= h($st) ?></span></td>
                    <td class="muted"><?= h((string) ($r['created_at'] ?? '')) ?></td>
                    <td>
                        <div class="actions">
                            <form method="post" onsubmit="return confirm('Ishonchingiz komilmi?')">
                                <?= admin_csrf_field() ?>
                                <input type="hidden" name="id" value="<?= (int) $r['id'] ?>">
                                <?php if ($st !== 'closed'): ?>
                                    <button class="btn btn-warn btn-sm" name="action" value="close" type="submit">Yopish</button>
                                <?php endif; ?>
                                <button class="btn btn-danger btn-sm" name="action" value="delete" type="submit">Del</button>
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
