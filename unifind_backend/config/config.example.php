<?php

declare(strict_types=1);

return [
    'app' => [
        'name' => 'UniFind',
        'base_url' => 'https://yourdomain.com/unifind_backend',
        'timezone' => 'America/New_York',
    ],
    'db' => [
        'host' => 'localhost',
        'name' => 'cpanel_db_name',
        'user' => 'cpanel_db_user',
        'pass' => 'cpanel_db_password',
        'charset' => 'utf8mb4',
    ],
    'mail' => [
        'from_email' => 'noreply@yourdomain.com',
        'from_name' => 'UniFind',
        'smtp_host' => 'mail.yourdomain.com',
        'smtp_port' => 587,
        'smtp_user' => 'noreply@yourdomain.com',
        'smtp_pass' => 'your_smtp_password',
        'smtp_secure' => 'tls', // tls or ssl
    ],
    'security' => [
        'csrf_ttl' => 7200,
        'verification_token_ttl_hours' => 24,
        'resend_cooldown_seconds' => 120,
        'max_upload_bytes' => 5 * 1024 * 1024,
        // 32-byte key for AES-256-GCM encryption of message bodies at rest.
        // Generate with: php -r "echo base64_encode(random_bytes(32)), PHP_EOL;"
        // Rotate by re-encrypting rows under a new key (out of scope for v1).
        // IMPORTANT: losing this key means losing all stored message contents.
        'message_key' => '',
    ],
    'listings' => [
        'categories' => [
            'Books',
            'Electronics',
            'Furniture',
            'Clothing',
            'School Supplies',
            'Other',
        ],
    ],
];
