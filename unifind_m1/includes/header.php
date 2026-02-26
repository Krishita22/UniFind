<?php

declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';
$flashes = flash_get_all();
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($config['app']['name']) ?></title>
    <link rel="stylesheet" href="<?= e(base_url('assets/css/style.css')) ?>">
</head>
<body>
<header class="site-header">
    <div class="container nav-wrap">
        <a class="brand" href="<?= e(base_url('index.php')) ?>">UniFind</a>
        <nav>
            <a href="<?= e(base_url('index.php')) ?>">Browse</a>
            <?php if (current_user_id() !== null): ?>
                <a href="<?= e(base_url('listings/create.php')) ?>">Create Listing</a>
                <a href="<?= e(base_url('auth/logout.php')) ?>">Logout</a>
            <?php else: ?>
                <a href="<?= e(base_url('auth/login.php')) ?>">Login</a>
                <a href="<?= e(base_url('auth/register.php')) ?>">Register</a>
            <?php endif; ?>
        </nav>
    </div>
</header>
<main class="container main-content">
    <?php foreach ($flashes as $flash): ?>
        <div class="flash flash-<?= e($flash['type']) ?>"><?= e($flash['message']) ?></div>
    <?php endforeach; ?>
