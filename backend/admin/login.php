<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

if (isset($_GET['logout'])) {
    admin_logout();
    if (isset($_GET['lock'])) {
        header('Location: /');
        exit;
    }
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
        $error = 'Xavfsizlik kaliti (CSRF) yaroqsiz';
    } elseif (!admin_check_rate_limit()) {
        $error = "Xavfsizlik blokirovkasi! Juda ko‘p noto‘g‘ri urinishlar bo‘ldi. 15 daqiqadan so‘ng qayta urinib ko‘ring.";
    } else {
        $user = trim((string) ($_POST['username'] ?? ''));
        $pass = (string) ($_POST['password'] ?? '');
        if (admin_try_login($user, $pass)) {
            $_SESSION['admin_authenticated'] = true;
            header('Location: overview.php');
            exit;
        }
        $error = 'Login yoki parol noto‘g‘ri kiritildi';
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
    <title>Admin Kirish — <?= h($appName) ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/admin.css">
    <style>
        .login-wrap {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
            background:
                radial-gradient(1000px 500px at 50% -10%, rgba(16, 185, 129, 0.22), transparent 60%),
                radial-gradient(800px 450px at 80% 110%, rgba(5, 150, 105, 0.15), transparent 55%),
                #071512;
        }
        .login-box {
            width: 100%;
            max-width: 440px;
            background: rgba(12, 31, 26, 0.85);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid rgba(52, 211, 153, 0.25);
            border-radius: 20px;
            padding: 2.5rem 2.25rem;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(16, 185, 129, 0.1);
            text-align: center;
        }
        .login-logo {
            width: 80px;
            height: 80px;
            border-radius: 18px;
            box-shadow: 0 8px 24px rgba(16, 185, 129, 0.3);
            margin-bottom: 1.25rem;
            object-fit: cover;
        }
        .login-box h1 {
            font-size: 1.65rem;
            margin: 0 0 0.35rem;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: #ffffff;
        }
        .login-box .sub {
            color: #8fb9a8;
            font-size: 0.92rem;
            margin: 0 0 1.75rem;
        }
        .security-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.45rem;
            background: rgba(16, 185, 129, 0.12);
            border: 1px solid rgba(16, 185, 129, 0.25);
            color: #34d399;
            font-size: 0.78rem;
            font-weight: 600;
            padding: 0.3rem 0.75rem;
            border-radius: 999px;
            margin-bottom: 1.5rem;
        }
        .form-group {
            text-align: left;
            margin-bottom: 1.2rem;
        }
        .form-group label {
            display: block;
            font-size: 0.84rem;
            font-weight: 600;
            color: #cbd5e1;
            margin-bottom: 0.45rem;
        }
        .input-wrap {
            position: relative;
            display: flex;
            align-items: center;
        }
        .input-wrap input {
            width: 100%;
            background: rgba(10, 26, 22, 0.95);
            border: 1px solid rgba(52, 211, 153, 0.25);
            border-radius: 12px;
            color: #ffffff;
            font-size: 0.95rem;
            padding: 0.75rem 1rem;
            padding-right: 2.75rem;
            outline: none;
            transition: all 0.2s ease;
            font-family: inherit;
        }
        .input-wrap input:focus {
            border-color: #10b981;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.22);
            background: #0a1a16;
        }
        .toggle-pwd {
            position: absolute;
            right: 0.75rem;
            background: transparent;
            border: none;
            color: #8fb9a8;
            cursor: pointer;
            padding: 0.35rem;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 6px;
            transition: color 0.15s ease;
        }
        .toggle-pwd:hover {
            color: #ffffff;
        }
        .btn-submit {
            width: 100%;
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: #042419;
            font-weight: 700;
            font-size: 1rem;
            padding: 0.85rem;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow: 0 4px 18px rgba(16, 185, 129, 0.35);
            margin-top: 0.5rem;
        }
        .btn-submit:hover {
            transform: translateY(-1.5px);
            box-shadow: 0 6px 24px rgba(16, 185, 129, 0.5);
        }
        .btn-submit:active {
            transform: translateY(0);
        }
        .lock-gate-wrap {
            margin-top: 1.5rem;
            padding-top: 1.25rem;
            border-top: 1px solid rgba(52, 211, 153, 0.15);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.82rem;
        }
        .lock-gate-wrap a {
            color: #8fb9a8;
            text-decoration: none;
            transition: color 0.15s ease;
        }
        .lock-gate-wrap a:hover {
            color: #f87171;
        }
    </style>
</head>
<body>
<div class="login-wrap">
    <div class="login-box">
        <img class="login-logo" src="/assets/brand/xonadosh_logo_ui.png" alt="XonaDosh">
        <h1><?= h($appName) ?></h1>
        <p class="sub">Himoyalangan Boshqaruv Markazi</p>

        <div class="security-badge">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
            256-bit Shifrlangan Seans
        </div>

        <?php if ($error !== ''): ?>
            <div class="alert alert-err" style="margin-bottom: 1.25rem; font-size: 0.88rem; padding: 0.75rem 1rem; border-radius: 10px; background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.35); color: #fca5a5; text-align: left;">
                <?= h($error) ?>
            </div>
        <?php endif; ?>

        <form method="post" autocomplete="on">
            <?= admin_csrf_field() ?>
            <div class="form-group">
                <label for="username">Administrator logini</label>
                <div class="input-wrap">
                    <input type="text" id="username" name="username" required autocomplete="username" value="admin" autofocus>
                </div>
            </div>
            <div class="form-group">
                <label for="password">Maxfiy parol</label>
                <div class="input-wrap">
                    <input type="password" id="password" name="password" required autocomplete="current-password">
                    <button type="button" class="toggle-pwd" id="togglePwd" title="Parolni ko'rsatish/yashirish" aria-label="Toggle password">
                        <svg id="eyeIcon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </button>
                </div>
            </div>
            <button class="btn-submit" type="submit">Boshqaruvga kirish</button>
        </form>

        <div class="lock-gate-wrap">
            <a href="/" target="_blank">← Saytga o‘tish</a>
            <a href="login.php?logout=1&lock=1" title="Darvozani qulflab, sahifani 404 rejimiga qaytarish">🔒 Darvozani qulflash</a>
        </div>
    </div>
</div>

<script>
document.getElementById('togglePwd').addEventListener('click', function() {
    const pwd = document.getElementById('password');
    const eye = document.getElementById('eyeIcon');
    if (pwd.type === 'password') {
        pwd.type = 'text';
        eye.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line>';
    } else {
        pwd.type = 'password';
        eye.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>';
    }
});
</script>
</body>
</html>
