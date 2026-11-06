<?php
/**
 * Copy to config.local.php on the server and fill in real credentials.
 * Do NOT commit config.local.php.
 */

declare(strict_types=1);

return [
    'db_host' => 'localhost',
    'db_name' => '69561c631190f_honadosh',
    'db_user' => '69561c631190f_honadosh',
    'db_pass' => 'CHANGE_ME',
    'app_name' => 'XonaDosh',
    'base_url' => 'https://honadosh.uz',
    'admin_user' => 'admin',
    // Generate with: php -r "echo password_hash('your-password', PASSWORD_BCRYPT);"
    'admin_pass_hash' => '$2y$10$REPLACE_WITH_password_hash_OUTPUT',
    // Secret gate key required in URL (?key=...) to access /admin/ entrance
    'admin_gate_key' => 'CHANGE_ME_SECRET_GATE',
];
