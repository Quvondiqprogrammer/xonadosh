<?php

declare(strict_types=1);

/** @var string $pageTitle */
$pageTitle = $pageTitle ?? 'Admin';
$active = $active ?? '';
$appName = (string) (xd_cfg()['app_name'] ?? 'XonaDosh');

$navGroups = [
    'Asosiy' => [
        ['id' => 'overview', 'href' => 'overview.php', 'label' => 'Dashboard', 'icon' => '◈'],
        ['id' => 'reports', 'href' => 'reports.php', 'label' => 'Shikoyatlar', 'icon' => '⚑'],
    ],
    'Foydalanuvchilar' => [
        ['id' => 'users', 'href' => 'users.php', 'label' => 'Foydalanuvchilar', 'icon' => '◎'],
        ['id' => 'sessions', 'href' => 'sessions.php', 'label' => 'Sessiyalar', 'icon' => '⟳'],
        ['id' => 'profiles', 'href' => 'profiles.php', 'label' => 'Anketalar', 'icon' => '☺'],
    ],
    'Kontent' => [
        ['id' => 'listings', 'href' => 'listings.php', 'label' => "E'lonlar", 'icon' => '⌂'],
        ['id' => 'universities', 'href' => 'universities.php', 'label' => 'OTMlar', 'icon' => '◇'],
        ['id' => 'recipes', 'href' => 'recipes.php', 'label' => 'Retseptlar', 'icon' => '▣'],
        ['id' => 'market', 'href' => 'market.php', 'label' => 'Bozor narxlari', 'icon' => '₮'],
        ['id' => 'meals', 'href' => 'meals.php', 'label' => 'Taomnoma', 'icon' => '☰'],
    ],
    'Coliving' => [
        ['id' => 'chores', 'href' => 'chores.php', 'label' => 'Navbatchilik', 'icon' => '✓'],
        ['id' => 'finances', 'href' => 'finances.php', 'label' => 'Moliya & Qarz', 'icon' => '₿'],
        ['id' => 'polls', 'href' => 'polls.php', 'label' => 'Anonim masalalar', 'icon' => '◉'],
        ['id' => 'karma', 'href' => 'karma.php', 'label' => "Obro' & Karma", 'icon' => '★'],
    ],
];
?>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" type="image/png" href="/assets/brand/xonadosh_icon.png">
    <title><?= h($pageTitle) ?> — <?= h($appName) ?> Super Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&family=IBM+Plex+Mono:wght@500&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/admin.css">
</head>
<body>
<div class="shell">
    <aside class="side">
        <div class="brand">
            <img src="/assets/brand/xonadosh_icon.png" width="40" height="40" alt="">
            <div>
                <strong><?= h($appName) ?></strong>
                <span>Super Admin</span>
            </div>
        </div>
        <nav class="nav">
            <?php foreach ($navGroups as $group => $items): ?>
                <div class="nav-group"><?= h($group) ?></div>
                <?php foreach ($items as $item): ?>
                    <a class="<?= $active === $item['id'] ? 'active' : '' ?>" href="<?= h($item['href']) ?>">
                        <span class="ico"><?= $item['icon'] ?></span>
                        <?= h($item['label']) ?>
                    </a>
                <?php endforeach; ?>
            <?php endforeach; ?>
        </nav>
        <div class="side-foot">
            <a class="btn btn-ghost btn-sm" href="/" target="_blank" rel="noopener">Sayt</a>
            <a class="btn btn-ghost btn-sm" href="/app/" target="_blank" rel="noopener">Web ilova</a>
            <a class="btn btn-danger btn-sm" href="login.php?logout=1">Chiqish</a>
        </div>
    </aside>
    <main class="main">
<?php
$flash = admin_flash();
if ($flash): ?>
    <div class="alert alert-<?= ($flash['type'] ?? '') === 'err' ? 'err' : 'ok' ?>"><?= h($flash['msg'] ?? '') ?></div>
<?php endif; ?>
