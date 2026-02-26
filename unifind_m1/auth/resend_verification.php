<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';
require_once __DIR__ . '/../includes/mailer.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('auth/login.php');
}

verify_csrf_or_fail('resend_form');

$email = strtolower(trim((string)($_POST['email'] ?? '')));

if (!filter_var($email, FILTER_VALIDATE_EMAIL) || !is_montclair_email($email)) {
    flash_set('error', 'Enter a valid @montclair.edu email.');
    redirect('auth/login.php');
}

$stmt = db()->prepare('SELECT id, full_name, is_verified FROM users WHERE email = ? LIMIT 1');
if (!$stmt) {
    flash_set('error', 'Server error. Please try again later.');
    redirect('auth/login.php');
}

$stmt->bind_param('s', $email);
$stmt->execute();
$user = $stmt->get_result()?->fetch_assoc();
$stmt->close();

if (!$user) {
    flash_set('success', 'If that account exists, a verification email has been sent.');
    redirect('auth/login.php');
}

if ((int)$user['is_verified'] === 1) {
    flash_set('success', 'That account is already verified. Please log in.');
    redirect('auth/login.php');
}

$userId = (int)$user['id'];
if (is_resend_rate_limited($userId)) {
    flash_set('error', 'Please wait at least 2 minutes before requesting another verification email.');
    redirect('auth/login.php');
}

try {
    $tokenData = create_verification_token($userId);
    $sent = send_verification_email($email, $user['full_name'], $tokenData['raw_token']);

    if ($sent) {
        flash_set('success', 'Verification email sent. Please check your inbox.');
    } else {
        flash_set('error', 'Could not send verification email right now. Please try again later.');
    }
} catch (Throwable $e) {
    error_log('Resend verification failed: ' . $e->getMessage());
    flash_set('error', 'Could not send verification email right now. Please try again later.');
}

redirect('auth/login.php');
