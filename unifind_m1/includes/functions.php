<?php

declare(strict_types=1);

function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}

function base_url(string $path = ''): string
{
    global $config;
    $base = rtrim($config['app']['base_url'], '/');
    $path = ltrim($path, '/');
    return $path === '' ? $base : $base . '/' . $path;
}

function redirect(string $path): never
{
    header('Location: ' . base_url($path));
    exit;
}

function current_user_id(): ?int
{
    if (!isset($_SESSION['user_id'], $_SESSION['logged_in']) || $_SESSION['logged_in'] !== true) {
        return null;
    }

    return (int)$_SESSION['user_id'];
}

function is_montclair_email(string $email): bool
{
    $email = strtolower(trim($email));
    return (bool)preg_match('/^[A-Z0-9._%+\-]+@montclair\.edu$/i', $email);
}

function is_valid_password(string $password): bool
{
    if (strlen($password) < 8) {
        return false;
    }

    return (bool)(preg_match('/[A-Za-z]/', $password) && preg_match('/\d/', $password));
}

function short_desc(string $text, int $max = 120): string
{
    $text = trim($text);
    if (mb_strlen($text) <= $max) {
        return $text;
    }

    return mb_substr($text, 0, $max - 3) . '...';
}

function allowed_listing_categories(): array
{
    global $config;
    return $config['listings']['categories'] ?? [];
}
