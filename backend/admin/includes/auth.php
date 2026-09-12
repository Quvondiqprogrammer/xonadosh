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

function admin_try_login(string $user, string $password): bool
{
    $cfg = xd_cfg();
    $expectedUser = (string) ($cfg['admin_user'] ?? 'admin');
    $hash = (string) ($cfg['admin_pass_hash'] ?? '');
    if ($hash === '' || $password === '') {
        return false;
    }
    if (!hash_equals($expectedUser, $user)) {
        return false;
    }
    return password_verify($password, $hash);
}

function admin_logout(): void
{
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
