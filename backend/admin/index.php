<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

if (admin_logged_in()) {
    header('Location: overview.php');
} else {
    header('Location: login.php');
}
exit;
