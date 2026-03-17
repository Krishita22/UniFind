<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';

flash_set('success', 'You have been logged out.');
unset($_SESSION['user_id'], $_SESSION['email'], $_SESSION['full_name'], $_SESSION['logged_in'], $_SESSION['is_verified']);
session_regenerate_id(true);
redirect('auth/login.php');
