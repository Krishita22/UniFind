<?php

declare(strict_types=1);

$configFile = __DIR__ . '/../config/config.php';
if (!file_exists($configFile)) {
    http_response_code(500);
    exit('Missing config/config.php. Copy config/config.example.php to config/config.php first.');
}

$config = require $configFile;

date_default_timezone_set($config['app']['timezone'] ?? 'UTC');

// Detect HTTPS via both the HTTPS server var and port 443 to handle reverse proxies
// (e.g. nginx terminating TLS) that may not forward the HTTPS variable.
// The 'secure' flag prevents the session cookie from being sent over plain HTTP.
$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || ((int)($_SERVER['SERVER_PORT'] ?? 80) === 443);
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'domain' => '',
    'secure' => $isHttps,
    'httponly' => true,
    // 'Lax' allows the session cookie to be sent on top-level cross-site navigations (e.g. clicking
    // a link from email), while still blocking it in third-party iframes and AJAX requests.
    // Use 'Strict' if you never need cross-site navigation to land in an authenticated state.
    'samesite' => 'Lax',
]);

// Guard against calling session_start() twice — harmless on first load, essential when
// bootstrap.php might be included more than once in the same request.
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/functions.php';
require_once __DIR__ . '/flash.php';
require_once __DIR__ . '/csrf.php';
