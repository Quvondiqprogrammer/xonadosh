<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

if (isset($_GET['logout'])) {
    admin_logout();
    header('Location: login.php');
    exit;
}

if (admin_logged_in()) {
    header('Location: overview.php');
    exit;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!admin_verify_csrf($_POST['csrf'] ?? null)) {
        $error = 'CSRF xatosi';
    } else {
        $user = trim((string) ($_POST['username'] ?? ''));
        $pass = (string) ($_POST['password'] ?? '');
        if (admin_try_login($user, $pass)) {
            $_SESSION['admin_authenticated'] = true;
            header('Location: overview.php');
            exit;
        }
        $error = 'Login yoki parol noto\'g\'ri';
    }
}

$appName = (string) (xd_cfg()['app_name'] ?? 'XonaDosh');
?>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" type="image/png" href="/assets/brand/xonadosh_icon.png">
    <title>Admin kirish — <?= h($appName) ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/admin.css">
</head>
<body>
<div class="login-wrap">
    <div class="login-box">
        <img class="login-logo" src="/assets/brand/xonadosh_logo_ui.png" alt="XonaDosh" width="120" height="120">
        <h1><?= h($appName) ?></h1>
        <p class="sub">Super Admin paneliga kirish</p>
        <?php if ($error !== ''): ?>
            <div class="alert alert-err"><?= h($error) ?></div>
        <?php endif; ?>
        <form method="post">
            <?= admin_csrf_field() ?>
            <label>Username</label>
            <input type="text" name="username" required autocomplete="username" value="admin">
            <label>Parol</label>
            <input type="password" name="password" required autocomplete="current-password">
            <button class="btn btn-primary" type="submit">Kirish</button>
        </form>
    </div>
</div>
</body>
</html>
