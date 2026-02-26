<?php

declare(strict_types=1);

function csrf_token(string $form): string
{
    global $config;

    if (!isset($_SESSION['csrf'])) {
        $_SESSION['csrf'] = [];
    }

    $ttl = (int)($config['security']['csrf_ttl'] ?? 7200);
    $now = time();

    if (isset($_SESSION['csrf'][$form]) && ($_SESSION['csrf'][$form]['expires_at'] ?? 0) > $now) {
        return $_SESSION['csrf'][$form]['token'];
    }

    $token = bin2hex(random_bytes(32));
    $_SESSION['csrf'][$form] = [
        'token' => $token,
        'expires_at' => $now + $ttl,
    ];

    return $token;
}

function csrf_input(string $form): string
{
    $token = csrf_token($form);
    return '<input type="hidden" name="csrf_token" value="' . e($token) . '">';
}

function verify_csrf_or_fail(string $form): void
{
    $session = $_SESSION['csrf'][$form] ?? null;
    $submitted = $_POST['csrf_token'] ?? '';

    if (!$session || !is_string($submitted)) {
        http_response_code(400);
        exit('Invalid CSRF token.');
    }

    if (($session['expires_at'] ?? 0) < time()) {
        unset($_SESSION['csrf'][$form]);
        http_response_code(400);
        exit('Expired CSRF token. Please refresh and try again.');
    }

    if (!hash_equals($session['token'], $submitted)) {
        http_response_code(400);
        exit('Invalid CSRF token.');
    }
}
