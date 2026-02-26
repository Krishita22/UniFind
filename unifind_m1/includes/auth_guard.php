<?php

declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

$userId = current_user_id();
if ($userId === null) {
    flash_set('error', 'Please log in first.');
    redirect('auth/login.php');
}

$stmt = db()->prepare('SELECT id, full_name, email, is_verified FROM users WHERE id = ? LIMIT 1');
if (!$stmt) {
    error_log('Prepare failed in auth_guard.');
    http_response_code(500);
    exit('Server error.');
}

$stmt->bind_param('i', $userId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result ? $result->fetch_assoc() : null;
$stmt->close();

if (!$user || (int)$user['is_verified'] !== 1) {
    unset($_SESSION['user_id'], $_SESSION['email'], $_SESSION['full_name'], $_SESSION['logged_in'], $_SESSION['is_verified']);
    session_regenerate_id(true);
    flash_set('error', 'Your session is no longer valid. Please log in again.');
    redirect('auth/login.php');
}

$_SESSION['user_email'] = $user['email'];
$_SESSION['full_name'] = $user['full_name'];
$_SESSION['is_verified'] = 1;
