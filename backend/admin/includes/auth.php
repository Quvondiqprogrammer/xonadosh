<?php

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start([
        'cookie_httponly' => true,
        'cookie_samesite' => 'Lax',
        'cookie_secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off'),
    ]);
}

$configPath = dirname(__DIR__, 2) . '/config.local.php';
if (!is_readable($configPath)) {
    http_response_code(500);
    exit('config.local.php topilmadi');
}

/** @var array<string,mixed> $GLOBALS['xd_cfg'] */
$GLOBALS['xd_cfg'] = require $configPath;

require_once dirname(__DIR__, 2) . '/includes/db.php';

function xd_cfg(): array
{
    return $GLOBALS['xd_cfg'];
}

function xd_pdo(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $pdo = db_connect(xd_cfg());
    }
    return $pdo;
}

function admin_csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(16));
    }
    return $_SESSION['csrf'];
}

function admin_gate_key(): string
{
    $cfg = xd_cfg();
    return (string) ($cfg['admin_gate_key'] ?? 'Asad03@18');
}

function admin_gate_cookie_hash(string $key): string
{
    return hash_hmac('sha256', 'xd_admin_gate_v1_token', $key);
}

function admin_render_404_and_exit(): never
{
    http_response_code(404);
    header('Cache-Control: no-cache, no-store, must-revalidate');
    ?>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>404 — Sahifa topilmadi | XonaDosh</title>
    <link rel="icon" type="image/png" href="/assets/brand/xonadosh_icon.png">
    <style>
        :root { --bg: #071512; --card: #0c1f1a; --border: rgba(52,211,153,0.18); --emerald: #10b981; --text: #e8f6f0; --muted: #8fb9a8; }
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, system-ui, sans-serif; background: radial-gradient(800px 400px at 50% 0%, rgba(16,185,129,0.12), transparent), var(--bg); color: var(--text); display: flex; align-items: center; justify-content: center; padding: 1.5rem; text-align: center; }
        .card { max-width: 460px; background: var(--card); border: 1px solid var(--border); border-radius: 18px; padding: 2.5rem 2rem; box-shadow: 0 12px 36px rgba(0,0,0,0.45); }
        .badge { display: inline-block; font-size: 0.8rem; font-weight: 700; color: var(--emerald); background: rgba(16,185,129,0.14); padding: 0.35rem 0.85rem; border-radius: 999px; margin-bottom: 1rem; }
        h1 { font-size: 3.5rem; margin: 0; font-weight: 900; letter-spacing: -0.03em; color: var(--emerald); line-height: 1; }
        h2 { font-size: 1.35rem; margin: 0.75rem 0 0.5rem; color: #fff; font-weight: 700; }
        p { color: var(--muted); font-size: 0.95rem; line-height: 1.55; margin: 0 0 1.75rem; }
        .btn { display: inline-flex; align-items: center; justify-content: center; gap: 0.5rem; background: var(--emerald); color: #042419; text-decoration: none; font-weight: 700; font-size: 0.95rem; padding: 0.75rem 1.5rem; border-radius: 12px; transition: all 0.2s ease; box-shadow: 0 4px 14px rgba(16,185,129,0.3); }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(16,185,129,0.45); }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge" id="gateBadge" style="cursor: pointer;" title="XonaDosh Admin Gate" onclick="toggleGateForm()">Xato 404</span>
        <h1>404</h1>
        <h2>Sahifa topilmadi</h2>
        <p>Kechirasiz, siz murojaat qilgan manzil mavjud emas yoki ko‘chirilgan bo‘lishi mumkin.</p>
        <a class="btn" href="/">Bosh sahifaga qaytish</a>

        <form method="POST" id="gateForm" style="display: none; margin-top: 1.75rem; padding-top: 1.25rem; border-top: 1px dashed rgba(52,211,153,0.25);">
            <div style="font-size: 0.85rem; color: #8fb9a8; margin-bottom: 0.75rem; font-weight: 600;">🔒 Administrator maxfiy kaliti:</div>
            <input type="password" name="gate_key" placeholder="Maxfiy kalit..." required style="width: 100%; padding: 0.7rem 0.9rem; background: rgba(0,0,0,0.3); border: 1px solid rgba(52,211,153,0.3); border-radius: 10px; color: #fff; font-size: 0.9rem; margin-bottom: 0.75rem; outline: none; box-sizing: border-box;">
            <button type="submit" class="btn" style="width: 100%; padding: 0.65rem 1rem; cursor: pointer; border: none;">Darvozani ochish</button>
        </form>
    </div>
    <script>
    function toggleGateForm() {
        var f = document.getElementById('gateForm');
        f.style.display = (f.style.display === 'none' || f.style.display === '') ? 'block' : 'none';
        if (f.style.display === 'block') {
            f.querySelector('input').focus();
        }
    }
    </script>
</body>
</html>
    <?php
    exit;
}

function admin_lock_gate(): void
{
    unset($_SESSION['admin_gate_unlocked']);
    if (ini_get('session.use_cookies')) {
        setcookie('xd_admin_gate', '', [
            'expires' => time() - 3600,
            'path' => '/admin/',
            'secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off'),
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
    }
}

function admin_gate_check(): void
{
    if (admin_logged_in()) {
        return;
    }

    $gateKey = admin_gate_key();
    if ($gateKey === '') {
        return;
    }
    $expectedHash = admin_gate_cookie_hash($gateKey);

    $providedKey = (string) ($_GET['key'] ?? $_GET['gate'] ?? $_GET['secret'] ?? $_POST['gate_key'] ?? '');
    if ($providedKey !== '' && hash_equals($gateKey, $providedKey)) {
        $_SESSION['admin_gate_unlocked'] = true;
        setcookie('xd_admin_gate', $expectedHash, [
            'expires' => time() + (7 * 86400),
            'path' => '/admin/',
            'secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off'),
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        $script = basename($_SERVER['SCRIPT_NAME'] ?? '');
        if ($script === 'index.php' || !empty($_POST['gate_key'])) {
            header('Location: login.php');
            exit;
        }
        return;
    }

    if (!empty($_SESSION['admin_gate_unlocked']) && $_SESSION['admin_gate_unlocked'] === true) {
        return;
    }

    $cookieHash = (string) ($_COOKIE['xd_admin_gate'] ?? '');
    if ($cookieHash !== '' && hash_equals($expectedHash, $cookieHash)) {
        $_SESSION['admin_gate_unlocked'] = true;
        return;
    }

    admin_render_404_and_exit();
}

// Enforce gatekeeper
admin_gate_check();

function admin_verify_csrf(?string $token): bool
{
    return is_string($token) && isset($_SESSION['csrf']) && hash_equals($_SESSION['csrf'], $token);
}

function admin_logged_in(): bool
{
    return !empty($_SESSION['admin_authenticated']) && $_SESSION['admin_authenticated'] === true;
}

function admin_require_login(): void
{
    $hash = (string) (xd_cfg()['admin_pass_hash'] ?? '');
    if ($hash === '' || str_contains($hash, 'REPLACE_WITH')) {
        http_response_code(503);
        exit('Admin panel o‘chirilgan (config.local.php da admin_pass_hash sozlanmagan)');
    }
    if (!admin_logged_in()) {
        header('Location: login.php');
        exit;
    }
}

function admin_check_rate_limit(): bool
{
    $now = time();
    $attempts = $_SESSION['admin_failed_attempts'] ?? [];
    if (!is_array($attempts)) {
        $attempts = [];
    }
    $attempts = array_filter($attempts, static fn($t) => is_int($t) && ($now - $t) < 900);
    $_SESSION['admin_failed_attempts'] = $attempts;

    return count($attempts) < 5;
}

function admin_record_failed_attempt(): void
{
    if (!isset($_SESSION['admin_failed_attempts']) || !is_array($_SESSION['admin_failed_attempts'])) {
        $_SESSION['admin_failed_attempts'] = [];
    }
    $_SESSION['admin_failed_attempts'][] = time();
}

function admin_clear_login_attempts(): void
{
    unset($_SESSION['admin_failed_attempts']);
}

function admin_try_login(string $user, string $password): bool
{
    if (!admin_check_rate_limit()) {
        return false;
    }

    $cfg = xd_cfg();
    $expectedUser = (string) ($cfg['admin_user'] ?? 'admin');
    $hash = (string) ($cfg['admin_pass_hash'] ?? '');
    if ($hash === '' || $password === '') {
        admin_record_failed_attempt();
        return false;
    }
    if (!hash_equals($expectedUser, $user)) {
        admin_record_failed_attempt();
        return false;
    }
    if (!password_verify($password, $hash)) {
        admin_record_failed_attempt();
        return false;
    }

    admin_clear_login_attempts();
    return true;
}

function admin_logout(): void
{
    if (isset($_GET['lock'])) {
        admin_lock_gate();
    }
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], (bool) $p['secure'], (bool) $p['httponly']);
    }
    session_destroy();
}

function admin_safe_count(PDO $pdo, string $sql): int
{
    try {
        return (int) $pdo->query($sql)->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}

function h(?string $s): string
{
    return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8');
}

function admin_flash(?string $msg = null, string $type = 'ok'): ?array
{
    if ($msg !== null) {
        $_SESSION['admin_flash'] = ['msg' => $msg, 'type' => $type];
        return null;
    }
    if (empty($_SESSION['admin_flash'])) {
        return null;
    }
    $f = $_SESSION['admin_flash'];
    unset($_SESSION['admin_flash']);
    return $f;
}

function admin_redirect(string $url): never
{
    header('Location: ' . $url);
    exit;
}

function admin_post_ok(): bool
{
    return $_SERVER['REQUEST_METHOD'] === 'POST' && admin_verify_csrf($_POST['csrf'] ?? null);
}

function admin_table_exists(PDO $pdo, string $table): bool
{
    try {
        $stmt = $pdo->prepare('SHOW TABLES LIKE ?');
        $stmt->execute([$table]);
        return (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        return false;
    }
}

function admin_money(float|int|string $n): string
{
    return number_format((float) $n, 0, '.', ' ');
}

function admin_page(int $default = 1): int
{
    return max(1, (int) ($_GET['page'] ?? $default));
}

function admin_per_page(int $default = 40): int
{
    $n = (int) ($_GET['per'] ?? $default);
    return max(10, min(200, $n > 0 ? $n : $default));
}

function admin_pager(int $page, int $per, int $total, string $baseQuery = ''): string
{
    $pages = max(1, (int) ceil($total / $per));
    if ($pages <= 1) {
        return '';
    }
    $html = '<div class="pager">';
    for ($i = 1; $i <= $pages && $i <= 20; $i++) {
        $q = $baseQuery === '' ? "page=$i" : $baseQuery . "&page=$i";
        $cls = $i === $page ? 'active' : '';
        $html .= '<a class="' . $cls . '" href="?' . h($q) . '">' . $i . '</a>';
    }
    $html .= '<span class="muted"> / ' . $pages . ' · jami ' . $total . '</span></div>';
    return $html;
}

function admin_csrf_field(): string
{
    return '<input type="hidden" name="csrf" value="' . h(admin_csrf_token()) . '">';
}
